import 'package:xml/xml.dart';

import '../calibration/slide_physical_context.dart';
import '../models/annotation.dart';
import '../models/document.dart';
import '../models/layer.dart';
import '../models/shapes/annotation_shape.dart';
import '../models/shapes/arrow_shape.dart';
import '../models/shapes/circle_shape.dart';
import '../models/shapes/ellipse_shape.dart';
import '../models/shapes/line_shape.dart';
import '../models/shapes/point_2d.dart';
import '../models/shapes/point_shape.dart';
import '../models/shapes/polygon_shape.dart';
import '../models/shapes/rectangle_shape.dart';
import '../utils/color_utils.dart';
import '../utils/text_utils.dart';
import 'codec.dart';

/// Codec for Aperio ImageScope XML format (`.xml`).
///
/// Aperio stores coordinates directly as Level 0 pixels.
/// Colors are stored as 32-bit BGR integers (`0x00BBGGRR`).
/// AI metadata (confidence, class, model) are stored inside `<Attributes>`.
class AperioXmlCodec extends AnnotationCodec {
  const AperioXmlCodec();

  @override
  AnnotationDocument decode(String content, {SlidePhysicalContext? context}) {
    final xmlDoc = XmlDocument.parse(content);
    final root = xmlDoc.rootElement;

    final mppAttr = root.getAttribute('MicronsPerPixel');
    final docMetadata = <String, dynamic>{};
    if (mppAttr != null) {
      docMetadata['MicronsPerPixel'] = double.tryParse(mppAttr) ?? mppAttr;
    }

    final layers = <AnnotationLayer>[];
    final annotationElements = root.findElements('Annotation');

    for (final annNode in annotationElements) {
      final layerId = annNode.getAttribute('Id') ?? 'layer-${layers.length + 1}';
      final layerName = annNode.getAttribute('Name') ?? 'Layer $layerId';
      final lineColorAttr = annNode.getAttribute('LineColor');
      final isVisible = annNode.getAttribute('Visible') != '0';
      final isLocked = annNode.getAttribute('ReadOnly') == '1';

      int? defaultColor;
      if (lineColorAttr != null) {
        final bgr = int.tryParse(lineColorAttr);
        if (bgr != null) {
          defaultColor = ColorUtils.bgrIntToColor(bgr);
        }
      }

      // Parse layer-level attributes
      final layerAttrs = _parseAttributes(annNode.findElements('Attributes').firstOrNull);
      final layerAiMetadata = _buildAiMetadata(layerAttrs);

      final regionList = <Annotation>[];
      final regionsParent = annNode.findElements('Regions').firstOrNull;
      if (regionsParent != null) {
        for (final regNode in regionsParent.findElements('Region')) {
          final regId = regNode.getAttribute('Id') ?? '${layerId}_${regionList.length + 1}';
          final typeStr = regNode.getAttribute('Type') ?? '0';
          final type = int.tryParse(typeStr) ?? 0;
          final regText = regNode.getAttribute('Text');

          // Parse region attributes
          final regAttrs = _parseAttributes(regNode.findElements('Attributes').firstOrNull);
          // Merge layer attributes if not set on region
          final mergedAttrs = {...layerAttrs, ...regAttrs};
          final aiMetadata = _buildAiMetadata(mergedAttrs);

          // Parse vertices
          final vertices = <Point2D>[];
          final verticesParent = regNode.findElements('Vertices').firstOrNull;
          if (verticesParent != null) {
            for (final vNode in verticesParent.findElements('Vertex')) {
              final xStr = vNode.getAttribute('X');
              final yStr = vNode.getAttribute('Y');
              if (xStr != null && yStr != null) {
                vertices.add(Point2D(double.parse(xStr), double.parse(yStr)));
              }
            }
          }

          final shape = _decodeAperioShape(type, vertices);
          regionList.add(Annotation(
            id: regId,
            shape: shape,
            label: regText?.isNotEmpty == true ? regText : null,
            color: defaultColor,
            aiMetadata: aiMetadata,
            properties: regAttrs,
          ));
        }
      }

      final hasAi = layerAiMetadata != null || regionList.any((a) => a.aiMetadata != null);
      if (hasAi) {
        final firstAi = regionList.firstWhere(
          (a) => a.aiMetadata != null,
          orElse: () => Annotation(id: '', shape: const PointShape(Point2D(0, 0)), aiMetadata: layerAiMetadata),
        ).aiMetadata;

        layers.add(AiAnnotationLayer(
          id: layerId,
          name: layerName,
          modelName: firstAi?.modelName ?? 'Aperio-AI',
          modelVersion: firstAi?.modelVersion,
          isVisible: isVisible,
          isLocked: isLocked,
          defaultColor: defaultColor,
          annotations: regionList,
        ));
      } else {
        layers.add(UserAnnotationLayer(
          id: layerId,
          name: layerName,
          isVisible: isVisible,
          isLocked: isLocked,
          defaultColor: defaultColor,
          annotations: regionList,
        ));
      }
    }

    return AnnotationDocument(layers: layers, metadata: docMetadata);
  }

  Map<String, String> _parseAttributes(XmlElement? attributesElem) {
    final result = <String, String>{};
    if (attributesElem == null) return result;
    for (final attrNode in attributesElem.findElements('Attribute')) {
      final name = attrNode.getAttribute('Name');
      final val = attrNode.getAttribute('Value');
      if (name != null && val != null) {
        result[name] = val;
      }
    }
    return result;
  }

  AiMetadata? _buildAiMetadata(Map<String, String> attrs) {
    if (attrs.isEmpty) return null;
    final confStr = attrs['Confidence'] ?? attrs['confidence'] ?? attrs['Score'] ?? attrs['score'];
    final className = attrs['Class'] ?? attrs['class'] ?? attrs['Classification'] ?? attrs['classification'];
    final modelName = attrs['ModelName'] ?? attrs['modelName'] ?? attrs['Model'] ?? attrs['model'];
    final modelVersion = attrs['ModelVersion'] ?? attrs['version'];
    final statusStr = attrs['VerificationStatus'] ?? attrs['Status'] ?? attrs['status'];

    if (confStr == null && className == null && modelName == null && statusStr == null) {
      return null;
    }

    return AiMetadata(
      modelName: modelName,
      modelVersion: modelVersion,
      confidence: confStr != null ? double.tryParse(confStr) : null,
      classification: className,
      verificationStatus: AiVerificationStatus.fromString(statusStr),
      customAttributes: Map<String, dynamic>.from(attrs),
    );
  }

  AnnotationShape _decodeAperioShape(int type, List<Point2D> vertices) {
    switch (type) {
      case 1: // Rectangle
        if (vertices.length >= 2) {
          return RectangleShape.fromCorners(vertices[0], vertices[vertices.length >= 4 ? 2 : 1]);
        }
        return const RectangleShape(left: 0, top: 0, width: 0, height: 0);

      case 2: // Ellipse / Circle
        if (vertices.length >= 2) {
          var minX = vertices.first.x;
          var maxX = vertices.first.x;
          var minY = vertices.first.y;
          var maxY = vertices.first.y;
          for (final v in vertices) {
            if (v.x < minX) minX = v.x;
            if (v.x > maxX) maxX = v.x;
            if (v.y < minY) minY = v.y;
            if (v.y > maxY) maxY = v.y;
          }
          final rx = (maxX - minX) / 2.0;
          final ry = (maxY - minY) / 2.0;
          final cx = minX + rx;
          final cy = minY + ry;
          if ((rx - ry).abs() < 1e-4) {
            return CircleShape(centerX: cx, centerY: cy, radius: rx);
          }
          return EllipseShape(centerX: cx, centerY: cy, radiusX: rx, radiusY: ry);
        }
        return const CircleShape(centerX: 0, centerY: 0, radius: 0);

      case 3: // Arrow
        if (vertices.length >= 2) {
          return ArrowShape(
            startX: vertices[0].x,
            startY: vertices[0].y,
            endX: vertices[1].x,
            endY: vertices[1].y,
          );
        }
        return const ArrowShape(startX: 0, startY: 0, endX: 0, endY: 0);

      case 4: // Ruler / Line
        if (vertices.length >= 2) {
          return LineShape(
            x1: vertices[0].x,
            y1: vertices[0].y,
            x2: vertices[1].x,
            y2: vertices[1].y,
          );
        }
        return const LineShape(x1: 0, y1: 0, x2: 0, y2: 0);

      case 0: // Polygon
      default:
        return PolygonShape(vertices: vertices, isClosed: true);
    }
  }

  @override
  String encode(AnnotationDocument doc, {SlidePhysicalContext? context}) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    final mppVal = context?.micronsPerPixel ?? doc.metadata['MicronsPerPixel'] ?? 0.25;

    builder.element('Annotations', attributes: {
      'MicronsPerPixel': mppVal.toString(),
    }, nest: () {
      var layerIndex = 1;
      for (final layer in doc.layers) {
        final layerColor = layer.defaultColor ?? 0xFFFF0000;
        final bgrInt = ColorUtils.colorToBgrInt(layerColor);

        builder.element('Annotation', attributes: {
          'Id': layer.id.isNotEmpty ? layer.id : '${layerIndex++}',
          'Name': layer.name,
          'ReadOnly': layer.isLocked ? '1' : '0',
          'NameReadOnly': '0',
          'LineColorReadOnly': '0',
          'Incremental': '0',
          'Type': '4',
          'LineColor': bgrInt.toString(),
          'Visible': layer.isVisible ? '1' : '0',
          'Selected': '1',
          'Tag': '',
        }, nest: () {
          // Layer attributes if AI layer
          if (layer is AiAnnotationLayer) {
            builder.element('Attributes', nest: () {
              builder.element('Attribute', attributes: {
                'Name': 'ModelName',
                'Id': '0',
                'Value': layer.modelName,
              });
              if (layer.modelVersion != null) {
                builder.element('Attribute', attributes: {
                  'Name': 'ModelVersion',
                  'Id': '1',
                  'Value': layer.modelVersion!,
                });
              }
            });
          }

          builder.element('Regions', nest: () {
            builder.element('RegionSequenceHeader', nest: () {
              builder.element('X', nest: '0');
              builder.element('Y', nest: '0');
              builder.element('Zoom', nest: '1.0');
            });

            var regIndex = 1;
            for (final ann in layer.annotations) {
              final regId = ann.id.isNotEmpty ? ann.id : '${regIndex++}';
              final aperioType = _getAperioType(ann.shape);
              final vertices = _getAperioVertices(ann.shape);

              final lengthPx = ann.shape.perimeter;
              final areaPx = ann.shape.area;
              final lengthMicrons = lengthPx * (context?.micronsPerPixel ?? 0.25);
              final areaMicrons = areaPx * (context?.micronsPerPixel ?? 0.25) * (context?.micronsPerPixel ?? 0.25);

              builder.element('Region', attributes: {
                'Id': regId,
                'Type': aperioType.toString(),
                'Zoom': '1.0',
                'Selected': '1',
                'ImageLocation': '',
                'ImageFocus': '0',
                'Length': lengthPx.toStringAsFixed(1),
                'Area': areaPx.toStringAsFixed(1),
                'LengthMicrons': lengthMicrons.toStringAsFixed(2),
                'AreaMicrons': areaMicrons.toStringAsFixed(2),
                'Text': ann.label ?? '',
                'NegativeROA': '0',
                'InputRegionId': '0',
              }, nest: () {
                // Region Attributes
                final ai = ann.aiMetadata;
                if (ai != null) {
                  builder.element('Attributes', nest: () {
                    var attrId = 0;
                    if (ai.confidence != null) {
                      builder.element('Attribute', attributes: {
                        'Name': 'Confidence',
                        'Id': '${attrId++}',
                        'Value': ai.confidence!.toString(),
                      });
                    }
                    if (ai.classification != null) {
                      builder.element('Attribute', attributes: {
                        'Name': 'Class',
                        'Id': '${attrId++}',
                        'Value': ai.classification!,
                      });
                    }
                    if (ai.modelName != null) {
                      builder.element('Attribute', attributes: {
                        'Name': 'ModelName',
                        'Id': '${attrId++}',
                        'Value': ai.modelName!,
                      });
                    }
                    builder.element('Attribute', attributes: {
                      'Name': 'VerificationStatus',
                      'Id': '${attrId++}',
                      'Value': ai.verificationStatus.toJson(),
                    });
                  });
                }

                // Vertices
                builder.element('Vertices', nest: () {
                  for (final v in vertices) {
                    builder.element('Vertex', attributes: {
                      'X': v.x.toString(),
                      'Y': v.y.toString(),
                      'Z': '0',
                    });
                  }
                });
              });
            }
          });
        });
      }
    });
    final rawXml = builder.buildDocument().toXmlString(pretty: true);
    return escapeNonAsciiToXmlEntities(rawXml);
  }

  int _getAperioType(AnnotationShape shape) {
    if (shape is PolygonShape) return 0;
    if (shape is RectangleShape) return 1;
    if (shape is EllipseShape) return 2;
    if (shape is ArrowShape) return 3;
    if (shape is LineShape) return 4;
    return 0;
  }

  List<Point2D> _getAperioVertices(AnnotationShape shape) {
    if (shape is PolygonShape) {
      return shape.vertices;
    } else if (shape is RectangleShape) {
      return shape.vertices;
    } else if (shape is EllipseShape) {
      // 4 cardinal points for ellipse/circle
      return [
        Point2D(shape.centerX - shape.radiusX, shape.centerY),
        Point2D(shape.centerX, shape.centerY - shape.radiusY),
        Point2D(shape.centerX + shape.radiusX, shape.centerY),
        Point2D(shape.centerX, shape.centerY + shape.radiusY),
      ];
    } else if (shape is ArrowShape) {
      return [shape.start, shape.end];
    } else if (shape is LineShape) {
      return [shape.start, shape.end];
    } else if (shape is PointShape) {
      return [shape.point];
    }
    return [];
  }
}
