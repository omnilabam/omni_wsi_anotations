import 'dart:math' as math;
import 'annotation_shape.dart';
import 'point_2d.dart';
import 'polygon_shape.dart';
import 'rect_2d.dart';


/// Analytical ellipse annotation shape.
class EllipseShape extends AnnotationShape {
  final double centerX;
  final double centerY;
  final double radiusX;
  final double radiusY;

  const EllipseShape({
    required this.centerX,
    required this.centerY,
    required this.radiusX,
    required this.radiusY,
  });

  Point2D get center => Point2D(centerX, centerY);

  @override
  Rect2D get boundingBox => Rect2D(
    left: centerX - radiusX,
    top: centerY - radiusY,
    width: 2.0 * radiusX,
    height: 2.0 * radiusY,
  );

  @override
  double get area => math.pi * radiusX * radiusY;

  @override
  double get perimeter {
    if ((radiusX - radiusY).abs() < 1e-9) {
      return 2.0 * math.pi * radiusX;
    }
    // Ramanujan's first approximation for ellipse perimeter
    final a = radiusX;
    final b = radiusY;
    return math.pi * (3.0 * (a + b) - math.sqrt((3.0 * a + b) * (a + 3.0 * b)));
  }

  @override
  bool containsPoint(Point2D point) {
    if (radiusX <= 0 || radiusY <= 0) return false;
    final dx = (point.x - centerX) / radiusX;
    final dy = (point.y - centerY) / radiusY;
    return (dx * dx + dy * dy) <= 1.0;
  }

  /// Converts analytical ellipse into a polygon approximation with [segments] count.
  PolygonShape toPolygon({int segments = 36}) {
    if (segments < 3) segments = 3;
    final vertices = <Point2D>[];
    for (var i = 0; i < segments; i++) {
      final theta = 2.0 * math.pi * i / segments;
      vertices.add(Point2D(
        centerX + radiusX * math.cos(theta),
        centerY + radiusY * math.sin(theta),
      ));
    }
    return PolygonShape(vertices: vertices, isClosed: true);
  }

  @override
  EllipseShape scale(double factor) => EllipseShape(
    centerX: centerX * factor,
    centerY: centerY * factor,
    radiusX: radiusX * factor,
    radiusY: radiusY * factor,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is EllipseShape &&
              runtimeType == other.runtimeType &&
              (centerX - other.centerX).abs() < 1e-9 &&
              (centerY - other.centerY).abs() < 1e-9 &&
              (radiusX - other.radiusX).abs() < 1e-9 &&
              (radiusY - other.radiusY).abs() < 1e-9;

  @override
  int get hashCode => Object.hash(
    centerX.roundToDouble(),
    centerY.roundToDouble(),
    radiusX.roundToDouble(),
    radiusY.roundToDouble(),
  );

  @override
  String toString() =>
      'EllipseShape(center: ($centerX, $centerY), rx: $radiusX, ry: $radiusY)';
}