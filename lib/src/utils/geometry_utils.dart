import 'dart:math' as math;
import '../models/shapes/point_2d.dart';
import '../models/shapes/rect_2d.dart';

/// Geometric calculation utilities.
class GeometryUtils {
  GeometryUtils._();

  /// Calculates polygon area using the Shoelace formula (Gauss area formula).
  static double calculatePolygonArea(List<Point2D> vertices) {
    if (vertices.length < 3) return 0.0;
    double sum = 0.0;
    final n = vertices.length;
    for (var i = 0; i < n; i++) {
      final current = vertices[i];
      final next = vertices[(i + 1) % n];
      sum += (current.x * next.y) - (next.x * current.y);
    }
    return 0.5 * sum.abs();
  }

  /// Calculates perimeter or length of a polyline/polygon.
  static double calculatePolylineLength(
    List<Point2D> points, {
    bool isClosed = false,
  }) {
    if (points.length < 2) return 0.0;
    double length = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      length += points[i].distanceTo(points[i + 1]);
    }
    if (isClosed && points.length > 2) {
      length += points.last.distanceTo(points.first);
    }
    return length;
  }

  /// Determines whether a point is on the line segment between [p1] and [p2].
  static bool isPointOnSegment(
    Point2D point,
    Point2D p1,
    Point2D p2, {
    double tolerance = 1e-4,
  }) {
    final d1 = point.distanceTo(p1);
    final d2 = point.distanceTo(p2);
    final lineLength = p1.distanceTo(p2);
    if (lineLength == 0.0) {
      return d1 <= tolerance;
    }
    return (d1 + d2 - lineLength).abs() <= tolerance;
  }

  /// Tests if a [point] is inside the polygon defined by [vertices] using ray casting.
  static bool isPointInPolygon(Point2D point, List<Point2D> vertices) {
    if (vertices.length < 3) return false;

    // Check if point lies directly on any polygon edge
    final n = vertices.length;
    for (var i = 0; i < n; i++) {
      final j = (i + 1) % n;
      if (isPointOnSegment(point, vertices[i], vertices[j])) {
        return true;
      }
    }

    bool inside = false;
    for (var i = 0, j = n - 1; i < n; j = i++) {
      final xi = vertices[i].x, yi = vertices[i].y;
      final xj = vertices[j].x, yj = vertices[j].y;

      final intersect = ((yi > point.y) != (yj > point.y)) &&
          (point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi);
      if (intersect) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Calculates Axis-Aligned Bounding Box (AABB) covering all [points].
  static Rect2D calculateBoundingBox(Iterable<Point2D> points) {
    if (points.isEmpty) {
      return const Rect2D(left: 0.0, top: 0.0, width: 0.0, height: 0.0);
    }
    double minX = points.first.x;
    double maxX = points.first.x;
    double minY = points.first.y;
    double maxY = points.first.y;

    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    return Rect2D(
      left: minX,
      top: minY,
      width: maxX - minX,
      height: maxY - minY,
    );
  }

  /// Calculates points of an arrow head given shaft endpoints.
  static List<Point2D> calculateArrowHead({
    required Point2D start,
    required Point2D end,
    required double headLength,
    required double headAngleDegrees,
  }) {
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final angle = math.atan2(dy, dx);
    final rad = headAngleDegrees * math.pi / 180.0;

    final x1 = end.x - headLength * math.cos(angle - rad);
    final y1 = end.y - headLength * math.sin(angle - rad);

    final x2 = end.x - headLength * math.cos(angle + rad);
    final y2 = end.y - headLength * math.sin(angle + rad);

    return [Point2D(x1, y1), Point2D(x2, y2)];
  }
}
