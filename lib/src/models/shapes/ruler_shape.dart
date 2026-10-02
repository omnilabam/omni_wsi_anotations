import 'line_shape.dart';

/// A specialized ruler line shape with optional measurement label.
class RulerShape extends LineShape {
  final String? label;

  const RulerShape({
    required super.x1,
    required super.y1,
    required super.x2,
    required super.y2,
    this.label,
  });

  RulerShape.fromPoints(super.start, super.end, {this.label})
      : super.fromPoints();

  @override
  RulerShape scale(double factor) => RulerShape(
    x1: x1 * factor,
    y1: y1 * factor,
    x2: x2 * factor,
    y2: y2 * factor,
    label: label,
  );

  @override
  String toString() => 'RulerShape(($x1, $y1) -> ($x2, $y2), label: $label)';
}