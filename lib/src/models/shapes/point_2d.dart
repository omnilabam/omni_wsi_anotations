import 'dart:math' as math;

/// 2D Point representation in Level 0 pixel coordinates or nanometers.
class Point2D {
  final double x;
  final double y;

  const Point2D(this.x, this.y);

  /// Creates a [Point2D] from GeoJSON coordinate pair `[x, y]`.
  factory Point2D.fromGeoJson(List<dynamic> coords) {
    if (coords.length < 2) {
      throw ArgumentError('Coordinate array must contain at least 2 elements: $coords');
    }
    return Point2D(
      (coords[0] as num).toDouble(),
      (coords[1] as num).toDouble(),
    );
  }

  /// Calculates Euclidean distance to [other].
  double distanceTo(Point2D other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Scales the point coordinates by [factor].
  Point2D scale(double factor) => Point2D(x * factor, y * factor);

  /// Translates point by [dx] and [dy].
  Point2D translate(double dx, double dy) => Point2D(x + dx, y + dy);

  /// Converts point to GeoJSON `[x, y]` list.
  List<double> toGeoJsonCoordinates() => [x, y];

  Point2D copyWith({double? x, double? y}) => Point2D(x ?? this.x, y ?? this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point2D &&
          runtimeType == other.runtimeType &&
          (x - other.x).abs() < 1e-9 &&
          (y - other.y).abs() < 1e-9;

  @override
  int get hashCode => Object.hash(x.roundToDouble(), y.roundToDouble());

  @override
  String toString() => 'Point2D($x, $y)';
}
