import 'package:test/test.dart';
import 'package:omni_wsi_anotations/omni_wsi_anotations.dart';

void main() {
  group('Hamamatsu NDPI Calibration Tests (SlidePhysicalContext)', () {
    test('DoD Requirement: Optical center mapping (-123 nm)', () {
      const context = SlidePhysicalContext(
        imageWidth: 40000,
        imageHeight: 40000,
        mppX: 0.25,
        mppY: 0.25,
        xOffsetFromSlideCentre: -123.0,
        yOffsetFromSlideCentre: -123.0,
      );

      // Pixel (20000, 20000) is the center of the image
      final pixelCenter = const Point2D(20000.0, 20000.0);
      final nmPoint = context.pixelToNdpaNanometers(pixelCenter);

      expect(nmPoint.x, equals(-123.0));
      expect(nmPoint.y, equals(-123.0));

      // Reverse conversion back to pixels
      final roundTripPixel = context.ndpaNanometersToPixel(nmPoint);
      expect(roundTripPixel.x, closeTo(20000.0, 0.1));
      expect(roundTripPixel.y, closeTo(20000.0, 0.1));
    });

    test('Round-trip pixel <-> nanometer conversions across slide coordinates', () {
      const context = SlidePhysicalContext(
        imageWidth: 60000,
        imageHeight: 40000,
        mppX: 0.225,
        mppY: 0.228,
        xOffsetFromSlideCentre: 450000.0,
        yOffsetFromSlideCentre: -320000.0,
      );

      final testPoints = [
        const Point2D(0.0, 0.0), // Top-left
        const Point2D(30000.0, 20000.0), // Center
        const Point2D(60000.0, 40000.0), // Bottom-right
        const Point2D(12345.6, 23456.7), // Arbitrary sub-pixel
        const Point2D(54321.0, 11223.3),
      ];

      for (final originalPixel in testPoints) {
        final nm = context.pixelToNdpaNanometers(originalPixel);
        final restoredPixel = context.ndpaNanometersToPixel(nm);

        expect(restoredPixel.x, closeTo(originalPixel.x, 1e-4),
            reason: 'Failed X round-trip for $originalPixel');
        expect(restoredPixel.y, closeTo(originalPixel.y, 1e-4),
            reason: 'Failed Y round-trip for $originalPixel');
      }
    });

    test('Pixel to microns conversions', () {
      const context = SlidePhysicalContext(
        imageWidth: 1000,
        imageHeight: 1000,
        mppX: 0.5,
        mppY: 0.25,
      );

      final microns = context.pixelToMicrons(const Point2D(100.0, 200.0));
      expect(microns.x, equals(50.0)); // 100 * 0.5
      expect(microns.y, equals(50.0)); // 200 * 0.25

      final backToPixel = context.micronsToPixel(microns);
      expect(backToPixel.x, equals(100.0));
      expect(backToPixel.y, equals(200.0));
    });
  });
}
