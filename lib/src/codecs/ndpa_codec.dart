import 'dart:convert';
import 'package:xml/xml.dart';

import '../calibration/slide_physical_context.dart';
import '../models/annotation.dart';
import '../models/document.dart';
import '../models/layer.dart';
import '../models/shapes/annotation_shape.dart';
import '../models/shapes/arrow_shape.dart';
import '../models/shapes/circle_shape.dart';
import '../models/shapes/line_shape.dart';
import '../models/shapes/point_2d.dart';
import '../models/shapes/point_shape.dart';
import '../models/shapes/polygon_shape.dart';
import '../models/shapes/rectangle_shape.dart';
import '../utils/color_utils.dart';
import '../utils/text_utils.dart';
import 'codec.dart';

/// Codec for Hamamatsu NDP.view Annotation format (`.ndpa`).
///
/// NDP.view stores all coordinate points in physical nanometers relative to
/// the optical slide center. Converting between Level 0 pixels and nanometers
/// strictly requires a [SlidePhysicalContext].
class NdpaCodec extends AnnotationCodec {
  const NdpaCodec();

  @override
  AnnotationDocument decode(String content, {SlidePhysicalContext? context}) {
    if (context == null) {
      throw ArgumentError(
        'SlidePhysicalContext is required for NDPA decoding. '
        'NDPA coordinates are stored in nanometers and cannot be mapped '
        'to Level 0 pixels without slide dimensions and MPP calibration.',
      );
    }

    final xmlDoc = XmlDocument.parse(content);
    final annotationsElement = xmlDoc.rootElement;
    final annotationNodes = annotationsElement.findElements('annotation');

    final userAnnotations = <Annotation>[];
    final aiAnnotations = <Annotation>[];

    // Track metadata for AI layer if discovered
    String? aiModelName;
    String? aiModelVersion;

    for (final node in annotationNodes) {
      final id = node.getAttribute('id') ?? 'ann-${userAnnotations.length + aiAnnotations.length + 1}';
      final displayName = node.getAttribute('displayname');
      final title = node.findElements('title').firstOrNull?.innerText.trim();
      final colorAttr = node.getAttribute('color');
      final color = colorAttr != null ? ColorUtils.parseHex(colorAttr) : null;
      final type = node.findElements('type').firstOrNull?.innerText.trim().toLowerCase() ?? 'freehand';
      final specialType = node.findElements('specialtype').firstOrNull?.innerText.trim().toLowerCase();

      // Parse <details>
      AiMetadata? aiMetadata;
      Map<String, dynamic> customProps = {};
      final detailsText = node.findElements('details').firstOrNull?.innerText.trim();
      if (detailsText != null && detailsText.isNotEmpty) {
        try {
          final decoded = json.decode(detailsText);
          if (decoded is Map<String, dynamic>) {
            if (decoded.containsKey('ai') && decoded['ai'] is Map<String, dynamic>) {
              aiMetadata = AiMetadata.fromJson(decoded['ai'] as Map<String, dynamic>);
            } else {
              aiMetadata = AiMetadata.fromJson(decoded);
            }
            customProps = decoded;
          }
        } catch (_) {
          customProps['raw_details'] = detailsText;
        }
      }

      if (aiMetadata != null) {
        aiModelName ??= aiMetadata.modelName;
        aiModelVersion ??= aiMetadata.modelVersion;
      }

      // Parse points in nanometers
      final pointListElem = node.findElements('pointlist').firstOrNull;
      final nmPoints = <Point2D>[];
      if (pointListElem != null) {
        for (final ptNode in pointListElem.findElements('point')) {
          final xText = ptNode.findElements('x').firstOrNull?.innerText.trim();
          final yText = ptNode.findElements('y').firstOrNull?.innerText.trim();
          if (xText != null && yText != null) {
            final xNm = double.parse(xText);
            final yNm = double.parse(yText);
            nmPoints.add(Point2D(xNm, yNm));
          }
        }
      }

      // Convert nanometer points to Level 0 pixels
      final pxPoints = nmPoints.map((pt) => context.ndpaNanometersToPixel(pt)).toList();

      // Radius for circle
      final radiusElem = node.findElements('radius').firstOrNull;
      double? radiusNm;
      if (radiusElem != null) {
        radiusNm = double.tryParse(radiusElem.innerText.trim());
      }

      final AnnotationShape shape = _decodeShape(
        type: type,
        specialType: specialType,
        points: pxPoints,
        radiusNm: radiusNm,
        context: context,
      );

      final annotation = Annotation(
        id: id,
        shape: shape,
        label: title ?? displayName,
        color: color,
        aiMetadata: aiMetadata,
        properties: customProps,
      );

      if (aiMetadata != null) {
        aiAnnotations.add(annotation);
      } else {
        userAnnotations.add(annotation);
      }
    }

    final layers = <AnnotationLayer>[];
    if (userAnnotations.isNotEmpty || aiAnnotations.isEmpty) {
      layers.add(UserAnnotationLayer(
        id: 'layer-user',
        name: 'Manual Annotations',
        annotations: userAnnotations,
      ));
    }

    if (aiAnnotations.isNotEmpty) {
      layers.add(AiAnnotationLayer(
        id: 'layer-ai',
        name: 'AI Detections',
        modelName: aiModelName ?? 'AI-Model',
        modelVersion: aiModelVersion,
        annotations: aiAnnotations,
      ));
    }

    return AnnotationDocument(layers: layers);
  }

  AnnotationShape _decodeShape({
    required String type,
    required String? specialType,
    required List<Point2D> points,
    required double? radiusNm,
    required SlidePhysicalContext context,
  }) {
    switch (type) {
      case 'rect':
        if (points.length >= 2) {
          return RectangleShape.fromCorners(points[0], points[1]);
        } else if (points.length == 1) {
          return RectangleShape(left: points[0].x, top: points[0].y, width: 0, height: 0);
        }
        return const RectangleShape(left: 0, top: 0, width: 0, height: 0);

      case 'circle':
        if (points.isNotEmpty) {
          final center = points.first;
          double radiusPx = 0.0;
          if (radiusNm != null) {
            radiusPx = radiusNm / (context.mppX * 1000.0);
          } else if (points.length >= 2) {
            radiusPx = center.distanceTo(points[1]);
          }
          return CircleShape(centerX: center.x, centerY: center.y, radius: radiusPx);
        }
        return const CircleShape(centerX: 0, centerY: 0, radius: 0);

      case 'linear':
      case 'line':
        if (points.length >= 2) {
          return LineShape(
            x1: points[0].x,
            y1: points[0].y,
            x2: points[1].x,
            y2: points[1].y,
          );
        } else if (points.length == 1) {
          return LineShape(
            x1: points[0].x,
            y1: points[0].y,
            x2: points[0].x,
            y2: points[0].y,
          );
        }
        return const LineShape(x1: 0, y1: 0, x2: 0, y2: 0);

      case 'pin':
      case 'pointer':
        if (points.length >= 2) {
          return ArrowShape(
            startX: points[0].x,
            startY: points[0].y,
            endX: points[1].x,
            endY: points[1].y,
          );
        } else if (points.length == 1) {
          return PointShape(points[0]);
        }
        return const PointShape(Point2D(0, 0));

      case 'freehand':
      default:
        final isClosed = specialType == null || specialType == 'closedfreehand';
        return PolygonShape(vertices: points, isClosed: isClosed);
    }
  }

  @override
  String encode(AnnotationDocument doc, {SlidePhysicalContext? context}) {
    if (context == null) {
      throw ArgumentError(
        'SlidePhysicalContext is required for NDPA encoding. '
        'NDPA coordinates are stored in nanometers and Level 0 pixel coordinates '
        'must be calibrated using slide dimensions and MPP values.',
      );
    }

    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="utf-8" standalone="yes"');

    builder.element('annotations', nest: () {
      var counter = 1;
      for (final layer in doc.layers) {
        for (final ann in layer.annotations) {
          final idStr = ann.id.isNotEmpty ? ann.id : '${counter++}';
          final label = ann.label ?? 'Annotation $idStr';
          final hexColor = ColorUtils.colorToHex(
            ann.color ?? layer.defaultColor ?? 0xFFFF0000,
            includeAlpha: false,
          );

          builder.element('annotation', attributes: {
            'id': idStr,
            'displayname': label,
            'color': hexColor,
          }, nest: () {
            builder.element('title', nest: label);

            // <details> with AI or custom metadata
            final detailsMap = <String, dynamic>{};
            if (ann.aiMetadata != null) {
              detailsMap['ai'] = ann.aiMetadata!.toJson();
            } else if (layer is AiAnnotationLayer) {
              detailsMap['ai'] = {
                'model': layer.modelName,
                if (layer.modelVersion != null) 'version': layer.modelVersion,
              };
            }
            if (ann.properties.isNotEmpty) {
              detailsMap.addAll(ann.properties);
            }

            if (detailsMap.isNotEmpty) {
              builder.element('details', nest: json.encode(detailsMap));
            }

            _encodeShape(builder, ann.shape, context);
          });
        }
      }
    });
    final rawXml = builder.buildDocument().toXmlString(pretty: true);
    return escapeNonAsciiToXmlEntities(rawXml);
  }

  void _encodeShape(XmlBuilder builder, AnnotationShape shape, SlidePhysicalContext context) {
    if (shape is PolygonShape) {
      builder.element('type', nest: 'freehand');
      builder.element('pointlist', nest: () {
        for (final v in shape.vertices) {
          final nm = context.pixelToNdpaNanometers(v);
          builder.element('point', nest: () {
            builder.element('x', nest: nm.x.round().toString());
            builder.element('y', nest: nm.y.round().toString());
          });
        }
      });
      if (shape.isClosed) {
        builder.element('specialtype', nest: 'closedfreehand');
      }
    } else if (shape is RectangleShape) {
      builder.element('type', nest: 'rect');
      builder.element('pointlist', nest: () {
        final p1 = context.pixelToNdpaNanometers(Point2D(shape.left, shape.top));
        final p2 = context.pixelToNdpaNanometers(Point2D(shape.right, shape.bottom));
        builder.element('point', nest: () {
          builder.element('x', nest: p1.x.round().toString());
          builder.element('y', nest: p1.y.round().toString());
        });
        builder.element('point', nest: () {
          builder.element('x', nest: p2.x.round().toString());
          builder.element('y', nest: p2.y.round().toString());
        });
      });
      builder.element('specialtype', nest: 'rectangle');
    } else if (shape is CircleShape) {
      builder.element('type', nest: 'circle');
      final centerNm = context.pixelToNdpaNanometers(shape.center);
      builder.element('pointlist', nest: () {
        builder.element('point', nest: () {
          builder.element('x', nest: centerNm.x.round().toString());
          builder.element('y', nest: centerNm.y.round().toString());
        });
      });
      final radiusNm = (shape.radius * (context.mppX * 1000.0)).round();
      builder.element('radius', nest: radiusNm.toString());
    } else if (shape is LineShape) {
      builder.element('type', nest: 'linear');
      final p1 = context.pixelToNdpaNanometers(shape.start);
      final p2 = context.pixelToNdpaNanometers(shape.end);
      builder.element('pointlist', nest: () {
        builder.element('point', nest: () {
          builder.element('x', nest: p1.x.round().toString());
          builder.element('y', nest: p1.y.round().toString());
        });
        builder.element('point', nest: () {
          builder.element('x', nest: p2.x.round().toString());
          builder.element('y', nest: p2.y.round().toString());
        });
      });
    } else if (shape is ArrowShape) {
      builder.element('type', nest: 'pin');
      final p1 = context.pixelToNdpaNanometers(shape.start);
      final p2 = context.pixelToNdpaNanometers(shape.end);
      builder.element('pointlist', nest: () {
        builder.element('point', nest: () {
          builder.element('x', nest: p1.x.round().toString());
          builder.element('y', nest: p1.y.round().toString());
        });
        builder.element('point', nest: () {
          builder.element('x', nest: p2.x.round().toString());
          builder.element('y', nest: p2.y.round().toString());
        });
      });
    } else if (shape is PointShape) {
      builder.element('type', nest: 'pin');
      final p = context.pixelToNdpaNanometers(shape.point);
      builder.element('pointlist', nest: () {
        builder.element('point', nest: () {
          builder.element('x', nest: p.x.round().toString());
          builder.element('y', nest: p.y.round().toString());
        });
      });
    }
  }
}
