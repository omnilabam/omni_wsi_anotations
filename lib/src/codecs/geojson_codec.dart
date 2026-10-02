import 'dart:convert';

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
import 'codec.dart';

/// Codec for QuPath and ASAP WSI GeoJSON format conforming to RFC 7946.
///
/// Features are mapped to/from Level 0 pixel coordinates.
/// AI metadata is stored within `properties.ai`.
class GeoJsonCodec extends AnnotationCodec {
  const GeoJsonCodec();

  @override
  AnnotationDocument decode(String content, {SlidePhysicalContext? context}) {
    final dynamic parsed = json.decode(content);
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('GeoJSON root must be a JSON object');
    }

    final rootType = parsed['type'] as String?;
    final featuresList = <Map<String, dynamic>>[];

    if (rootType == 'FeatureCollection') {
      final features = parsed['features'];
      if (features is List) {
        for (final item in features) {
          if (item is Map<String, dynamic>) {
            featuresList.add(item);
          }
        }
      }
    } else if (rootType == 'Feature') {
      featuresList.add(parsed);
    } else {
      throw FormatException('Unsupported GeoJSON type: $rootType');
    }

    final layerMap = <String, List<Annotation>>{};
    final layerMetadataMap = <String, Map<String, dynamic>>{};

    for (var i = 0; i < featuresList.length; i++) {
      final feat = featuresList[i];
      final id = feat['id']?.toString() ?? 'feat-${i + 1}';
      final geometry = feat['geometry'];
      final properties = feat['properties'] is Map<String, dynamic>
          ? feat['properties'] as Map<String, dynamic>
          : <String, dynamic>{};

      if (geometry is! Map<String, dynamic>) continue;

      // Parse AI Metadata
      AiMetadata? aiMetadata;
      if (properties.containsKey('ai') && properties['ai'] is Map<String, dynamic>) {
        aiMetadata = AiMetadata.fromJson(properties['ai'] as Map<String, dynamic>);
      }

      // Classification name & color
      String? classificationName;
      int? color;
      final classification = properties['classification'];
      if (classification is Map<String, dynamic>) {
        classificationName = classification['name'] as String?;
        if (classification.containsKey('color')) {
          color = ColorUtils.parseColor(classification['color']);
        }
      } else if (classification is String) {
        classificationName = classification;
      }

      if (color == null && properties.containsKey('color')) {
        color = ColorUtils.parseColor(properties['color']);
      }

      if (aiMetadata != null && classificationName != null && aiMetadata.classification == null) {
        aiMetadata = aiMetadata.copyWith(classification: classificationName);
      }

      final label = properties['label'] as String? ??
          properties['name'] as String? ??
          classificationName;

      final isLocked = properties['isLocked'] == true;

      // Decode shape
      final shape = _decodeGeometry(geometry, properties);
      if (shape == null) continue;

      final annotation = Annotation(
        id: id,
        shape: shape,
        label: label,
        color: color,
        aiMetadata: aiMetadata,
        isLocked: isLocked,
        properties: properties,
      );

      final layerId = properties['layerId'] as String? ??
          (aiMetadata != null ? 'layer-ai' : 'layer-user');
      final layerName = properties['layerName'] as String? ??
          (aiMetadata != null ? 'AI Detections' : 'User Annotations');

      layerMap.putIfAbsent(layerId, () => []).add(annotation);
      layerMetadataMap[layerId] = {
        'name': layerName,
        if (aiMetadata?.modelName != null) 'modelName': aiMetadata!.modelName,
        if (aiMetadata?.modelVersion != null) 'modelVersion': aiMetadata!.modelVersion,
      };
    }

    final layers = <AnnotationLayer>[];
    layerMap.forEach((layerId, annotations) {
      final meta = layerMetadataMap[layerId] ?? {};
      final name = meta['name'] as String? ?? layerId;
      final isAi = annotations.any((a) => a.aiMetadata != null);

      if (isAi) {
        final modelName = meta['modelName'] as String? ??
            annotations.firstWhere((a) => a.aiMetadata?.modelName != null, orElse: () => annotations.first).aiMetadata?.modelName ??
            'AI-Model';
        final modelVersion = meta['modelVersion'] as String? ??
            annotations.firstWhere((a) => a.aiMetadata?.modelVersion != null, orElse: () => annotations.first).aiMetadata?.modelVersion;

        layers.add(AiAnnotationLayer(
          id: layerId,
          name: name,
          modelName: modelName,
          modelVersion: modelVersion,
          annotations: annotations,
        ));
      } else {
        layers.add(UserAnnotationLayer(
          id: layerId,
          name: name,
          annotations: annotations,
        ));
      }
    });

    return AnnotationDocument(layers: layers);
  }

  AnnotationShape? _decodeGeometry(
    Map<String, dynamic> geometry,
    Map<String, dynamic> properties,
  ) {
    final type = geometry['type'] as String?;
    final coordinates = geometry['coordinates'];
    final shapeHint = properties['shape']?.toString().toLowerCase();

    if (type == 'Point' && coordinates is List) {
      final pt = Point2D.fromGeoJson(coordinates);
      return PointShape(pt);
    }

    if (type == 'LineString' && coordinates is List) {
      final points = coordinates
          .whereType<List<dynamic>>()
          .map((coord) => Point2D.fromGeoJson(coord))
          .toList();

      if (points.length >= 2) {
        if (shapeHint == 'arrow') {
          return ArrowShape(
            startX: points[0].x,
            startY: points[0].y,
            endX: points[1].x,
            endY: points[1].y,
          );
        }
        return LineShape(
          x1: points[0].x,
          y1: points[0].y,
          x2: points[1].x,
          y2: points[1].y,
        );
      }
      return null;
    }

    if (type == 'Polygon' && coordinates is List && coordinates.isNotEmpty) {
      // Check if circle metadata is preserved
      if (shapeHint == 'circle' && properties.containsKey('center') && properties.containsKey('radius')) {
        final centerList = properties['center'];
        final radius = (properties['radius'] as num).toDouble();
        if (centerList is List && centerList.length >= 2) {
          return CircleShape(
            centerX: (centerList[0] as num).toDouble(),
            centerY: (centerList[1] as num).toDouble(),
            radius: radius,
          );
        }
      }

      final rings = <List<Point2D>>[];
      for (final ringItem in coordinates) {
        if (ringItem is List) {
          final ringPoints = <Point2D>[];
          for (final coord in ringItem) {
            if (coord is List && coord.length >= 2) {
              ringPoints.add(Point2D.fromGeoJson(coord));
            }
          }
          // Remove RFC 7946 closing duplicate if present
          if (ringPoints.length > 2 && ringPoints.first == ringPoints.last) {
            ringPoints.removeLast();
          }
          if (ringPoints.isNotEmpty) {
            rings.add(ringPoints);
          }
        }
      }

      if (rings.isEmpty) return null;

      final exterior = rings.first;
      final holes = rings.sublist(1);

      // Check if rectangle
      if (shapeHint == 'rectangle') {
        // Verify if rectangle corners
        if (_isAxisAlignedRectangle(exterior)) {
          return RectangleShape.fromCorners(exterior[0], exterior[2]);
        }
      }

      return PolygonShape(vertices: exterior, holes: holes, isClosed: true);
    }

    return null;
  }

  bool _isAxisAlignedRectangle(List<Point2D> pts) {
    if (pts.length != 4) return false;
    final xs = pts.map((p) => p.x).toSet();
    final ys = pts.map((p) => p.y).toSet();
    return xs.length == 2 && ys.length == 2;
  }

  @override
  String encode(AnnotationDocument doc, {SlidePhysicalContext? context}) {
    final features = <Map<String, dynamic>>[];

    for (final layer in doc.layers) {
      for (final ann in layer.annotations) {
        final feature = _encodeAnnotation(ann, layer, context);
        if (feature != null) {
          features.add(feature);
        }
      }
    }

    final geoJsonMap = {
      'type': 'FeatureCollection',
      'features': features,
    };

    return const JsonEncoder.withIndent('  ').convert(geoJsonMap);
  }

  Map<String, dynamic>? _encodeAnnotation(
    Annotation ann,
    AnnotationLayer layer,
    SlidePhysicalContext? context,
  ) {
    final geometry = _encodeGeometry(ann.shape);
    if (geometry == null) return null;

    final properties = <String, dynamic>{
      'objectType': 'annotation',
      'isLocked': ann.isLocked,
    };

    if (ann.label != null) {
      properties['name'] = ann.label;
    }

    final colorInt = ann.color ?? layer.defaultColor;
    if (ann.aiMetadata?.classification != null || colorInt != null) {
      properties['classification'] = {
        if (ann.aiMetadata?.classification != null)
          'name': ann.aiMetadata!.classification,
        if (colorInt != null) 'color': ColorUtils.colorToRgbList(colorInt),
      };
    }

    // Measurements
    final mpp = context?.micronsPerPixel;
    final areaPx = ann.shape.area;
    final lengthPx = ann.shape.perimeter;

    if (mpp != null) {
      properties['measurements'] = {
        'Area um^2': double.parse((areaPx * mpp * mpp).toStringAsFixed(2)),
        'Perimeter um': double.parse((lengthPx * mpp).toStringAsFixed(2)),
      };
    } else {
      properties['measurements'] = {
        'Area px': double.parse(areaPx.toStringAsFixed(1)),
        'Perimeter px': double.parse(lengthPx.toStringAsFixed(1)),
      };
    }

    // AI metadata
    if (ann.aiMetadata != null) {
      properties['ai'] = ann.aiMetadata!.toJson();
    } else if (layer is AiAnnotationLayer) {
      properties['ai'] = {
        'model': layer.modelName,
        if (layer.modelVersion != null) 'version': layer.modelVersion,
      };
    }

    // Extra properties to preserve exact shape type
    _addShapeProperties(ann.shape, properties);

    return {
      'type': 'Feature',
      'id': ann.id,
      'geometry': geometry,
      'properties': properties,
    };
  }

  void _addShapeProperties(AnnotationShape shape, Map<String, dynamic> properties) {
    if (shape is CircleShape) {
      properties['shape'] = 'circle';
      properties['center'] = [shape.centerX, shape.centerY];
      properties['radius'] = shape.radius;
    } else if (shape is RectangleShape) {
      properties['shape'] = 'rectangle';
    } else if (shape is ArrowShape) {
      properties['shape'] = 'arrow';
    }
  }

  Map<String, dynamic>? _encodeGeometry(AnnotationShape shape) {
    if (shape is PointShape) {
      return {
        'type': 'Point',
        'coordinates': [shape.x, shape.y],
      };
    } else if (shape is LineShape) {
      return {
        'type': 'LineString',
        'coordinates': [
          [shape.x1, shape.y1],
          [shape.x2, shape.y2],
        ],
      };
    } else if (shape is ArrowShape) {
      return {
        'type': 'LineString',
        'coordinates': [
          [shape.startX, shape.startY],
          [shape.endX, shape.endY],
        ],
      };
    } else if (shape is RectangleShape) {
      final vertices = shape.vertices;
      final coords = [
        ...vertices.map((p) => [p.x, p.y]),
        [vertices.first.x, vertices.first.y], // Close RFC 7946 ring
      ];
      return {
        'type': 'Polygon',
        'coordinates': [coords],
      };
    } else if (shape is CircleShape) {
      final poly = shape.toPolygon(segments: 36);
      final coords = [
        ...poly.vertices.map((p) => [p.x, p.y]),
        [poly.vertices.first.x, poly.vertices.first.y],
      ];
      return {
        'type': 'Polygon',
        'coordinates': [coords],
      };
    } else if (shape is PolygonShape) {
      final rings = <List<List<double>>>[];
      // Exterior ring
      final exterior = [
        ...shape.vertices.map((p) => [p.x, p.y]),
      ];
      if (shape.isClosed && exterior.isNotEmpty) {
        exterior.add([shape.vertices.first.x, shape.vertices.first.y]);
      }
      rings.add(exterior);

      // Holes
      for (final hole in shape.holes) {
        final holeCoords = [
          ...hole.map((p) => [p.x, p.y]),
        ];
        if (holeCoords.isNotEmpty) {
          holeCoords.add([hole.first.x, hole.first.y]);
        }
        rings.add(holeCoords);
      }

      return {
        'type': 'Polygon',
        'coordinates': rings,
      };
    }
    return null;
  }
}
