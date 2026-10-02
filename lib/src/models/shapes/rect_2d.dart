import 'dart:math' as math;
import 'point_2d.dart';

/// Axis-Aligned Bounding Box (AABB) in 2D space.
class Rect2D {
  final double left;
  final double top;
  final double width;
  final double height;

  const Rect2D({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  const Rect2D.fromLTWH(this.left, this.top, this.width, this.height);

  factory Rect2D.fromPoints(Point2D p1, Point2D p2) {
    final minX = math.min(p1.x, p2.x);
    final maxX = math.max(p1.x, p2.x);
    final minY = math.min(p1.y, p2.y);
    final maxY = math.max(p1.y, p2.y);
    return Rect2D(
      left: minX,
      top: minY,
      width: maxX - minX,
      height: maxY - minY,
    );
  }

  factory Rect2D.fromCenter({
    required Point2D center,
    required double width,
    required double height,
  }) {
    return Rect2D(
      left: center.x - width / 2.0,
      top: center.y - height / 2.0,
      width: width,
      height: height,
    );
  }

  double get right => left + width;
  double get bottom => top + height;

  Point2D get topLeft => Point2D(left, top);
  Point2D get topRight => Point2D(right, top);
  Point2D get bottomRight => Point2D(right, bottom);
  Point2D get bottomLeft => Point2D(left, bottom);
  Point2D get center => Point2D(left + width / 2.0, top + height / 2.0);

  double get area => width.abs() * height.abs();

  bool containsPoint(Point2D point) {
    return point.x >= left &&
        point.x <= right &&
        point.y >= top &&
        point.y <= bottom;
  }

  bool intersects(Rect2D other) {
    return left <= other.right &&
        right >= other.left &&
        top <= other.bottom &&
        bottom >= other.top;
  }

  Rect2D union(Rect2D other) {
    final minX = math.min(left, other.left);
    final minY = math.min(top, other.top);
    final maxX = math.max(right, other.right);
    final maxY = math.max(bottom, other.bottom);
    return Rect2D(
      left: minX,
      top: minY,
      width: maxX - minX,
      height: maxY - minY,
    );
  }

  Rect2D scale(double factor) {
    return Rect2D(
      left: left * factor,
      top: top * factor,
      width: width * factor,
      height: height * factor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rect2D &&
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
      'Rect2D(left: $left, top: $top, width: $width, height: $height)';
}
