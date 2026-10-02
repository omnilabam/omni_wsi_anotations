import '../../utils/geometry_utils.dart';
import 'annotation_shape.dart';
import 'point_2d.dart';
import 'rect_2d.dart';

/// Closed or open polygon shape with optional interior holes.
class PolygonShape extends AnnotationShape {
  final List<Point2D> vertices;
  final List<List<Point2D>> holes;
  final bool isClosed;

  const PolygonShape({
    required this.vertices,
    this.holes = const [],
    this.isClosed = true,
  });

  @override
  Rect2D get boundingBox => GeometryUtils.calculateBoundingBox(vertices);

  @override
  double get area {
    if (!isClosed || vertices.length < 3) return 0.0;
    final outerArea = GeometryUtils.calculatePolygonArea(vertices);
    var holesArea = 0.0;
    for (final hole in holes) {
      holesArea += GeometryUtils.calculatePolygonArea(hole);
    }
    return (outerArea - holesArea).clamp(0.0, double.infinity);
  }

  @override
  double get perimeter {
    var length = GeometryUtils.calculatePolylineLength(vertices, isClosed: isClosed);
    if (isClosed) {
      for (final hole in holes) {
        length += GeometryUtils.calculatePolylineLength(hole, isClosed: true);
      }
    }
    return length;
  }

  @override
  bool containsPoint(Point2D point) {
    if (!isClosed || vertices.length < 3) {
      // Check if point lies on the polyline
      for (var i = 0; i < vertices.length - 1; i++) {
        if (GeometryUtils.isPointOnSegment(point, vertices[i], vertices[i + 1])) {
          return true;
        }
      }
      return false;
    }

    // Must be inside outer boundary
    if (!GeometryUtils.isPointInPolygon(point, vertices)) {
      return false;
    }

    // Must not be inside any hole (unless on edge)
    for (final hole in holes) {
      if (GeometryUtils.isPointInPolygon(point, hole)) {
        return false;
      }
    }

    return true;
  }

  @override
  PolygonShape scale(double factor) => PolygonShape(
        vertices: vertices.map((p) => p.scale(factor)).toList(),
        holes: holes
            .map((hole) => hole.map((p) => p.scale(factor)).toList())
            .toList(),
        isClosed: isClosed,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PolygonShape ||
        runtimeType != other.runtimeType ||
        isClosed != other.isClosed ||
        vertices.length != other.vertices.length ||
        holes.length != other.holes.length) {
      return false;
    }
    for (var i = 0; i < vertices.length; i++) {
      if (vertices[i] != other.vertices[i]) return false;
    }
    for (var h = 0; h < holes.length; h++) {
      if (holes[h].length != other.holes[h].length) return false;
      for (var p = 0; p < holes[h].length; p++) {
        if (holes[h][p] != other.holes[h][p]) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(vertices),
        isClosed,
        holes.length,
      );

  @override
  String toString() =>
      'PolygonShape(vertices: ${vertices.length}, holes: ${holes.length}, closed: $isClosed)';
}

/// Freehand polyline or closed contour drawn by user or pathologist.
class FreehandShape extends PolygonShape {
  const FreehandShape({
    required super.vertices,
    super.holes = const [],
    super.isClosed = true,
  });

  @override
  FreehandShape scale(double factor) => FreehandShape(
        vertices: vertices.map((p) => p.scale(factor)).toList(),
        holes: holes
            .map((hole) => hole.map((p) => p.scale(factor)).toList())
            .toList(),
        isClosed: isClosed,
      );

  @override
  String toString() =>
      'FreehandShape(vertices: ${vertices.length}, holes: ${holes.length}, closed: $isClosed)';
}
