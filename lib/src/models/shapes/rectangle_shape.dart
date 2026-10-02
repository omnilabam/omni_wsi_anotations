import 'dart:math' as math;
import 'annotation_shape.dart';
import 'point_2d.dart';
import 'rect_2d.dart';

/// Axis-aligned rectangle shape.
class RectangleShape extends AnnotationShape {
  final double left;
  final double top;
  final double width;
  final double height;

  const RectangleShape({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  RectangleShape.fromRect(Rect2D rect)
      : left = rect.left,
        top = rect.top,
        width = rect.width,
        height = rect.height;

  factory RectangleShape.fromCorners(Point2D p1, Point2D p2) {
    final minX = math.min(p1.x, p2.x);
    final maxX = math.max(p1.x, p2.x);
    final minY = math.min(p1.y, p2.y);
    final maxY = math.max(p1.y, p2.y);
    return RectangleShape(
      left: minX,
      top: minY,
      width: maxX - minX,
      height: maxY - minY,
    );
  }

  double get right => left + width;
  double get bottom => top + height;

  /// Returns the 4 vertices of the rectangle in clockwise order starting from top-left.
  List<Point2D> get vertices => [
        Point2D(left, top),
        Point2D(right, top),
        Point2D(right, bottom),
        Point2D(left, bottom),
      ];

  @override
  Rect2D get boundingBox => Rect2D(
        left: left,
        top: top,
        width: width,
        height: height,
      );

  @override
  double get area => width.abs() * height.abs();

  @override
  double get perimeter => 2.0 * (width.abs() + height.abs());

  @override
  bool containsPoint(Point2D point) {
    return boundingBox.containsPoint(point);
  }

  @override
  RectangleShape scale(double factor) => RectangleShape(
        left: left * factor,
        top: top * factor,
        width: width * factor,
        height: height * factor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RectangleShape &&
          runtimeType == other.runtimeType &&
          (left - other.left).abs() < 1e-9 &&
          (top - other.top).abs() < 1e-9 &&
          (width - other.width).abs() < 1e-9 &&
          (height - other.height).abs() < 1e-9;

  @override
  int get hashCode => Object.hash(
        left.roundToDouble(),
        top.roundToDouble(),
        width.roundToDouble(),
        height.roundToDouble(),
      );

  @override
  String toString() =>
      'RectangleShape(left: $left, top: $top, width: $width, height: $height)';
}
