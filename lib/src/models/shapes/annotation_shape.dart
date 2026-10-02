import 'point_2d.dart';
import 'rect_2d.dart';

/// Base abstract class for all vector annotation shapes in Level 0 pixel coordinates.
abstract class AnnotationShape {
  const AnnotationShape();

  /// Axis-Aligned Bounding Box (AABB) of the shape.
  Rect2D get boundingBox;

  /// Checks if [point] is contained inside or on the boundary of the shape.
  bool containsPoint(Point2D point);

  /// Area of the shape in square pixels.
  double get area;

  /// Perimeter or length of the shape in pixels.
  double get perimeter;

  /// Scales all coordinates of the shape by [factor].
  AnnotationShape scale(double factor);
}
