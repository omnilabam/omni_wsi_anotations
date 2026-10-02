import '../../utils/geometry_utils.dart';
import 'annotation_shape.dart';
import 'point_2d.dart';
import 'rect_2d.dart';

/// Arrow / pointer shape from (startX, startY) to (endX, endY).
class ArrowShape extends AnnotationShape {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double headLength;
  final double headAngle; // In degrees, e.g. 30.0

  const ArrowShape({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    this.headLength = 10.0,
    this.headAngle = 30.0,
  });

  ArrowShape.fromPoints(
    Point2D start,
    Point2D end, {
    this.headLength = 10.0,
    this.headAngle = 30.0,
  })  : startX = start.x,
        startY = start.y,
        endX = end.x,
        endY = end.y;

  Point2D get start => Point2D(startX, startY);
  Point2D get end => Point2D(endX, endY);

  double get length => start.distanceTo(end);

  @override
  double get perimeter => length;

  @override
  double get area => 0.0;

  /// Returns the two barb points forming the arrow head.
  List<Point2D> get headPoints => GeometryUtils.calculateArrowHead(
        start: start,
        end: end,
        headLength: headLength,
        headAngleDegrees: headAngle,
      );

  @override
  Rect2D get boundingBox {
    final barb = headPoints;
    return GeometryUtils.calculateBoundingBox([start, end, ...barb]);
  }

  @override
  bool containsPoint(Point2D point, {double tolerance = 1e-2}) {
    // Check shaft
    if (GeometryUtils.isPointOnSegment(point, start, end, tolerance: tolerance)) {
      return true;
    }
    // Check head barbs
    final barbs = headPoints;
    if (barbs.length >= 2) {
      if (GeometryUtils.isPointOnSegment(point, end, barbs[0], tolerance: tolerance) ||
          GeometryUtils.isPointOnSegment(point, end, barbs[1], tolerance: tolerance)) {
        return true;
      }
    }
    return false;
  }

  @override
  ArrowShape scale(double factor) => ArrowShape(
        startX: startX * factor,
        startY: startY * factor,
        endX: endX * factor,
        endY: endY * factor,
        headLength: headLength * factor,
        headAngle: headAngle,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArrowShape &&
          runtimeType == other.runtimeType &&
          (startX - other.startX).abs() < 1e-9 &&
          (startY - other.startY).abs() < 1e-9 &&
          (endX - other.endX).abs() < 1e-9 &&
          (endY - other.endY).abs() < 1e-9 &&
          (headLength - other.headLength).abs() < 1e-9 &&
          (headAngle - other.headAngle).abs() < 1e-9;

  @override
  int get hashCode => Object.hash(
        startX.roundToDouble(),
        startY.roundToDouble(),
        endX.roundToDouble(),
        endY.roundToDouble(),
        headLength.roundToDouble(),
        headAngle.roundToDouble(),
      );

  @override
  String toString() =>
      'ArrowShape(($startX, $startY) -> ($endX, $endY), head: ${headLength}px @ $headAngle°)';
}
