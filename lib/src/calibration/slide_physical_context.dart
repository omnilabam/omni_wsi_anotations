import '../models/shapes/point_2d.dart';

/// Physical calibration context for Whole Slide Images (WSI),
/// particularly Hamamatsu NDPI slides with nanometer offsets.
class SlidePhysicalContext {
  /// Slide width at Level 0 (highest resolution) in pixels.
  final int imageWidth;

  /// Slide height at Level 0 (highest resolution) in pixels.
  final int imageHeight;

  /// Microns per pixel along the X axis ($\mu m / px$).
  final double mppX;

  /// Microns per pixel along the Y axis ($\mu m / px$).
  final double mppY;

  /// Optical center offset along X in nanometers (Hamamatsu NDPI tag 65422).
  final double xOffsetFromSlideCentre;

  /// Optical center offset along Y in nanometers (Hamamatsu NDPI tag 65423).
  final double yOffsetFromSlideCentre;

  const SlidePhysicalContext({
    required this.imageWidth,
    required this.imageHeight,
    required this.mppX,
    required this.mppY,
    this.xOffsetFromSlideCentre = 0.0,
    this.yOffsetFromSlideCentre = 0.0,
  });

  /// Average isotropic microns per pixel.
  double get micronsPerPixel => (mppX + mppY) / 2.0;

  /// Converts Level 0 pixel coordinates into Hamamatsu NDPA physical nanometers.
  Point2D pixelToNdpaNanometers(Point2D pixel) {
    final xNm = xOffsetFromSlideCentre + (pixel.x - imageWidth / 2.0) * (mppX * 1000.0);
    final yNm = yOffsetFromSlideCentre + (pixel.y - imageHeight / 2.0) * (mppY * 1000.0);
    return Point2D(xNm, yNm);
  }

  /// Converts Hamamatsu NDPA physical nanometers into Level 0 pixel coordinates.
  Point2D ndpaNanometersToPixel(Point2D nmPoint) {
    final px = imageWidth / 2.0 + (nmPoint.x - xOffsetFromSlideCentre) / (mppX * 1000.0);
    final py = imageHeight / 2.0 + (nmPoint.y - yOffsetFromSlideCentre) / (mppY * 1000.0);
    return Point2D(px, py);
  }

  /// Converts Level 0 pixel coordinates into physical micrometers ($\mu m$).
  Point2D pixelToMicrons(Point2D pixel) {
    return Point2D(pixel.x * mppX, pixel.y * mppY);
  }

  /// Converts physical micrometers ($\mu m$) into Level 0 pixel coordinates.
  Point2D micronsToPixel(Point2D microns) {
    return Point2D(microns.x / mppX, microns.y / mppY);
  }

  SlidePhysicalContext copyWith({
    int? imageWidth,
    int? imageHeight,
    double? mppX,
    double? mppY,
    double? xOffsetFromSlideCentre,
    double? yOffsetFromSlideCentre,
  }) {
    return SlidePhysicalContext(
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      mppX: mppX ?? this.mppX,
      mppY: mppY ?? this.mppY,
      xOffsetFromSlideCentre: xOffsetFromSlideCentre ?? this.xOffsetFromSlideCentre,
      yOffsetFromSlideCentre: yOffsetFromSlideCentre ?? this.yOffsetFromSlideCentre,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlidePhysicalContext &&
          runtimeType == other.runtimeType &&
          imageWidth == other.imageWidth &&
          imageHeight == other.imageHeight &&
          (mppX - other.mppX).abs() < 1e-9 &&
          (mppY - other.mppY).abs() < 1e-9 &&
          (xOffsetFromSlideCentre - other.xOffsetFromSlideCentre).abs() < 1e-9 &&
          (yOffsetFromSlideCentre - other.yOffsetFromSlideCentre).abs() < 1e-9;

  @override
  int get hashCode => Object.hash(
        imageWidth,
        imageHeight,
        mppX,
        mppY,
        xOffsetFromSlideCentre,
        yOffsetFromSlideCentre,
      );

  @override
  String toString() =>
      'SlidePhysicalContext(${imageWidth}x$imageHeight, mpp: ($mppX, $mppY), offsetNm: ($xOffsetFromSlideCentre, $yOffsetFromSlideCentre))';
}
