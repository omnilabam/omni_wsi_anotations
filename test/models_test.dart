import 'dart:math' as math;
import 'package:test/test.dart';
import 'package:omni_wsi_anotations/omni_wsi_anotations.dart';

void main() {
  group('Point2D & Rect2D Tests', () {
    test('Point2D calculations and distance', () {
      const p1 = Point2D(10.0, 20.0);
      const p2 = Point2D(13.0, 24.0);
      expect(p1.distanceTo(p2), equals(5.0));
      expect(p1.scale(2.0), equals(const Point2D(20.0, 40.0)));
      expect(p1.translate(5.0, -5.0), equals(const Point2D(15.0, 15.0)));
      expect(p1.toGeoJsonCoordinates(), equals([10.0, 20.0]));
      expect(Point2D.fromGeoJson([10, 20]), equals(const Point2D(10.0, 20.0)));
    });

    test('Rect2D calculations and containment', () {
      final rect = const Rect2D(left: 100.0, top: 100.0, width: 200.0, height: 150.0);
      expect(rect.right, equals(300.0));
      expect(rect.bottom, equals(250.0));
      expect(rect.area, equals(30000.0));
      expect(rect.center, equals(const Point2D(200.0, 175.0)));

      expect(rect.containsPoint(const Point2D(150.0, 150.0)), isTrue);
      expect(rect.containsPoint(const Point2D(50.0, 150.0)), isFalse);
      expect(rect.containsPoint(const Point2D(100.0, 100.0)), isTrue); // On corner

      final other = const Rect2D(left: 250.0, top: 200.0, width: 100.0, height: 100.0);
      expect(rect.intersects(other), isTrue);

      final disjoint = const Rect2D(left: 400.0, top: 400.0, width: 10.0, height: 10.0);
      expect(rect.intersects(disjoint), isFalse);

      final union = rect.union(other);
      expect(union.left, equals(100.0));
      expect(union.top, equals(100.0));
      expect(union.right, equals(350.0));
      expect(union.bottom, equals(300.0));
    });
  });

  group('Shapes Geometry & Formulas', () {
    test('PointShape', () {
      const pt = PointShape(Point2D(50.0, 60.0));
      expect(pt.x, equals(50.0));
      expect(pt.y, equals(60.0));
      expect(pt.area, equals(0.0));
      expect(pt.perimeter, equals(0.0));
      expect(pt.boundingBox, equals(const Rect2D(left: 50.0, top: 60.0, width: 0.0, height: 0.0)));
      expect(pt.containsPoint(const Point2D(50.0, 60.0)), isTrue);
      expect(pt.containsPoint(const Point2D(50.1, 60.0)), isFalse);
      expect(pt.scale(2.0), equals(const PointShape(Point2D(100.0, 120.0))));
    });

    test('LineShape and RulerShape length and physical microns', () {
      const line = LineShape(x1: 0.0, y1: 0.0, x2: 300.0, y2: 400.0);
      expect(line.length, equals(500.0));
      expect(line.perimeter, equals(500.0));
      expect(line.area, equals(0.0));
      expect(line.boundingBox, equals(const Rect2D(left: 0.0, top: 0.0, width: 300.0, height: 400.0)));
      expect(line.containsPoint(const Point2D(150.0, 200.0)), isTrue);
      expect(line.containsPoint(const Point2D(150.0, 250.0)), isFalse);

      // Microns calculation
      expect(line.physicalLengthMicrons(0.25), equals(125.0)); // 500 * 0.25 = 125 um
      expect(line.physicalLengthMicrons2D(mppX: 0.25, mppY: 0.25), equals(125.0));

      const ruler = RulerShape(x1: 0.0, y1: 0.0, x2: 100.0, y2: 0.0, label: '100px');
      expect(ruler.length, equals(100.0));
      expect(ruler.label, equals('100px'));
      expect(ruler.scale(2.0).length, equals(200.0));
    });

    test('ArrowShape geometry', () {
      const arrow = ArrowShape(
        startX: 0.0,
        startY: 0.0,
        endX: 100.0,
        endY: 0.0,
        headLength: 10.0,
        headAngle: 30.0,
      );
      expect(arrow.length, equals(100.0));
      expect(arrow.perimeter, equals(100.0));
      expect(arrow.area, equals(0.0));
      expect(arrow.containsPoint(const Point2D(50.0, 0.0)), isTrue);
      expect(arrow.containsPoint(const Point2D(50.0, 10.0)), isFalse);

      final barbs = arrow.headPoints;
      expect(barbs.length, equals(2));
      // End is (100, 0), headLength is 10, angle is 30 deg backwards
      expect(barbs[0].x, closeTo(100.0 - 10.0 * math.cos(math.pi / 6), 1e-4));
      expect(barbs[0].y, closeTo(10.0 * math.sin(math.pi / 6), 1e-4));
      expect(barbs[1].x, closeTo(100.0 - 10.0 * math.cos(math.pi / 6), 1e-4));
      expect(barbs[1].y, closeTo(-10.0 * math.sin(math.pi / 6), 1e-4));
    });

    test('RectangleShape area, perimeter, and vertices', () {
      const rect = RectangleShape(left: 10.0, top: 20.0, width: 100.0, height: 50.0);
      expect(rect.area, equals(5000.0));
      expect(rect.perimeter, equals(300.0));
      expect(rect.vertices, equals([
        const Point2D(10.0, 20.0),
        const Point2D(110.0, 20.0),
        const Point2D(110.0, 70.0),
        const Point2D(10.0, 70.0),
      ]));
      expect(rect.containsPoint(const Point2D(50.0, 50.0)), isTrue);
      expect(rect.containsPoint(const Point2D(5.0, 50.0)), isFalse);
    });

    test('CircleShape and EllipseShape area, perimeter, toPolygon, and containment', () {
      const circle = CircleShape(centerX: 100.0, centerY: 100.0, radius: 50.0);
      expect(circle.area, closeTo(math.pi * 2500.0, 1e-4));
      expect(circle.perimeter, closeTo(2.0 * math.pi * 50.0, 1e-4));
      expect(circle.containsPoint(const Point2D(100.0, 100.0)), isTrue);
      expect(circle.containsPoint(const Point2D(140.0, 100.0)), isTrue);
      expect(circle.containsPoint(const Point2D(160.0, 100.0)), isFalse);

      final poly = circle.toPolygon(segments: 36);
      expect(poly.vertices.length, equals(36));
      expect(poly.isClosed, isTrue);
      // Area of 36-segment polygon approximating circle should be very close to circle area
      expect(poly.area, closeTo(circle.area, 100.0));

      const ellipse = EllipseShape(centerX: 200.0, centerY: 200.0, radiusX: 60.0, radiusY: 30.0);
      expect(ellipse.area, closeTo(math.pi * 1800.0, 1e-4));
      expect(ellipse.containsPoint(const Point2D(250.0, 200.0)), isTrue);
      expect(ellipse.containsPoint(const Point2D(200.0, 240.0)), isFalse);
    });

    test('PolygonShape Shoelace area and Point-in-polygon (square and concave polygon)', () {
      // 1. Square: 100x100 -> area 10000
      const square = PolygonShape(vertices: [
        Point2D(0.0, 0.0),
        Point2D(100.0, 0.0),
        Point2D(100.0, 100.0),
        Point2D(0.0, 100.0),
      ]);
      expect(square.area, equals(10000.0));
      expect(square.perimeter, equals(400.0));
      expect(square.containsPoint(const Point2D(50.0, 50.0)), isTrue);
      expect(square.containsPoint(const Point2D(150.0, 50.0)), isFalse);

      // 2. Concave arrowhead polygon:
      // (0,0), (100, 50), (0, 100), (40, 50)
      const concave = PolygonShape(vertices: [
        Point2D(0.0, 0.0),
        Point2D(100.0, 50.0),
        Point2D(0.0, 100.0),
        Point2D(40.0, 50.0),
      ]);
      // Triangle 1: (0,0)-(100,50)-(40,50) area = 0.5 * base * height = 0.5 * 60 * 50 = 1500
      // Triangle 2: (40,50)-(100,50)-(0,100) area = 0.5 * 60 * 50 = 1500
      // Total area = 3000
      expect(concave.area, equals(3000.0));
      // Point inside the concave notch (e.g. (20, 50)) should be OUTSIDE
      expect(concave.containsPoint(const Point2D(20.0, 50.0)), isFalse);
      // Point inside the body (e.g. (60, 50)) should be INSIDE
      expect(concave.containsPoint(const Point2D(60.0, 50.0)), isTrue);
    });

    test('PolygonShape with Holes area and containment', () {
      // Outer square 200x200 (area 40000) from (0,0) to (200,200)
      // Hole square 100x100 (area 10000) from (50,50) to (150,150)
      const donut = PolygonShape(
        vertices: [
          Point2D(0.0, 0.0),
          Point2D(200.0, 0.0),
          Point2D(200.0, 200.0),
          Point2D(0.0, 200.0),
        ],
        holes: [
          [
            Point2D(50.0, 50.0),
            Point2D(150.0, 50.0),
            Point2D(150.0, 150.0),
            Point2D(50.0, 150.0),
          ],
        ],
      );

      expect(donut.area, equals(30000.0)); // 40000 - 10000
      expect(donut.perimeter, equals(1200.0)); // 800 + 400

      // Point in the donut body: (25, 25)
      expect(donut.containsPoint(const Point2D(25.0, 25.0)), isTrue);

      // Point inside the hole: (100, 100)
      expect(donut.containsPoint(const Point2D(100.0, 100.0)), isFalse);

      // Point outside the donut: (250, 250)
      expect(donut.containsPoint(const Point2D(250.0, 250.0)), isFalse);
    });
  });

  group('ColorUtils Tests', () {
    test('Hex color parsing and formatting', () {
      expect(ColorUtils.parseHex('#FF0000'), equals(0xFFFF0000));
      expect(ColorUtils.parseHex('#00FF00'), equals(0xFF00FF00));
      expect(ColorUtils.parseHex('#0000FF'), equals(0xFF0000FF));
      expect(ColorUtils.parseHex('#80FF0000'), equals(0x80FF0000));
      expect(ColorUtils.parseHex('F00'), equals(0xFFFF0000)); // Short 3-char hex

      expect(ColorUtils.colorToHex(0xFFFF0000), equals('#FF0000'));
      expect(ColorUtils.colorToHex(0x80FF0000, includeAlpha: true), equals('#80FF0000'));
    });

    test('Aperio 32-bit BGR Integer conversion', () {
      // Red: RGB=0xFF0000 -> BGR=255 (0x0000FF)
      expect(ColorUtils.colorToBgrInt(0xFFFF0000), equals(255));
      expect(ColorUtils.bgrIntToColor(255), equals(0xFFFF0000));

      // Green: RGB=0x00FF00 -> BGR=65280 (0x00FF00)
      expect(ColorUtils.colorToBgrInt(0xFF00FF00), equals(65280));
      expect(ColorUtils.bgrIntToColor(65280), equals(0xFF00FF00));

      // Blue: RGB=0x0000FF -> BGR=16711680 (0xFF0000)
      expect(ColorUtils.colorToBgrInt(0xFF0000FF), equals(16711680));
      expect(ColorUtils.bgrIntToColor(16711680), equals(0xFF0000FF));
    });

    test('RGB List conversion', () {
      expect(ColorUtils.colorToRgbList(0xFFFF0000), equals([255, 0, 0]));
      expect(ColorUtils.rgbListToColor([255, 0, 0]), equals(0xFFFF0000));
    });
  });
}
