import 'annotation_shape.dart';
import 'point_2d.dart';
import 'rect_2d.dart';

/// Single point annotation shape.
class PointShape extends AnnotationShape {
  final Point2D point;

  const PointShape(this.point);

  PointShape.fromXY(double x, double y) : point = Point2D(x, y);

  double get x => point.x;
  double get y => point.y;

  @override
  Rect2D get boundingBox => Rect2D(left: x, top: y, width: 0.0, height: 0.0);

  @override
  bool containsPoint(Point2D p, {double tolerance = 1e-4}) {
    return point.distanceTo(p) <= tolerance;
  }

  @override
  double get area => 0.0;

  @override
  double get perimeter => 0.0;

  @override
  PointShape scale(double factor) => PointShape(point.scale(factor));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointShape &&
          runtimeType == other.runtimeType &&
          point == other.point;

  @override
  int get hashCode => point.hashCode;

  @override
  String toString() => 'PointShape($x, $y)';
}
