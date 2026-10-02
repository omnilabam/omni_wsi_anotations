import 'point_2d.dart';
import 'ellipse_shape.dart';



/// Specialized circle annotation shape with uniform radius.
class CircleShape extends EllipseShape {
  const CircleShape({
    required super.centerX,
    required super.centerY,
    required double radius,
  }) : super(radiusX: radius, radiusY: radius);

  CircleShape.fromCenterRadius(Point2D center, double radius)
      : super(
          centerX: center.x,
          centerY: center.y,
          radiusX: radius,
          radiusY: radius,
        );

  double get radius => radiusX;

  @override
  CircleShape scale(double factor) => CircleShape(
        centerX: centerX * factor,
        centerY: centerY * factor,
        radius: radius * factor,
      );

  @override
  String toString() =>
      'CircleShape(center: ($centerX, $centerY), radius: $radius)';
}
