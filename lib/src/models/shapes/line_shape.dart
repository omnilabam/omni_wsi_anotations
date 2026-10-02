import 'dart:math' as math;
import '../../utils/geometry_utils.dart';
import 'annotation_shape.dart';
import 'point_2d.dart';
import 'rect_2d.dart';

/// Straight line segment shape between (x1, y1) and (x2, y2).
class LineShape extends AnnotationShape {
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  const LineShape({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  LineShape.fromPoints(Point2D start, Point2D end)
      : x1 = start.x,
        y1 = start.y,
        x2 = end.x,
        y2 = end.y;

  Point2D get start => Point2D(x1, y1);
  Point2D get end => Point2D(x2, y2);

  /// Pixel length of the line.
  double get length => start.distanceTo(end);

  @override
  double get perimeter => length;

  @override
  double get area => 0.0;

  /// Calculates physical length in micrometers (microns) using isotropic [micronsPerPixel].
  double physicalLengthMicrons(double micronsPerPixel) =>
      length * micronsPerPixel;

  /// Calculates physical length in micrometers taking into account anisotropic [mppX] and [mppY].
  double physicalLengthMicrons2D({
    required double mppX,
    required double mppY,
  }) {
    final dx = (x2 - x1) * mppX;
    final dy = (y2 - y1) * mppY;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  Rect2D get boundingBox => GeometryUtils.calculateBoundingBox([start, end]);

  @override
  bool containsPoint(Point2D point, {double tolerance = 1e-2}) {
    return GeometryUtils.isPointOnSegment(point, start, end, tolerance: tolerance);
  }

  @override
  LineShape scale(double factor) => LineShape(
        x1: x1 * factor,
        y1: y1 * factor,
        x2: x2 * factor,
        y2: y2 * factor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineShape &&
          runtimeType == other.runtimeType &&
          (x1 - other.x1).abs() < 1e-9 &&
          (y1 - other.y1).abs() < 1e-9 &&
          (x2 - other.x2).abs() < 1e-9 &&
          (y2 - other.y2).abs() < 1e-9;

  @override
  int get hashCode => Object.hash(
        x1.roundToDouble(),
        y1.roundToDouble(),
        x2.roundToDouble(),
        y2.roundToDouble(),
      );

  @override
  String toString() => 'LineShape(($x1, $y1) -> ($x2, $y2))';
}


