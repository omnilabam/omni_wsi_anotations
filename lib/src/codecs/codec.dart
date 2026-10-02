import '../calibration/slide_physical_context.dart';
import '../models/document.dart';

/// Base abstract interface for WSI annotation format codecs (import and export).
abstract class AnnotationCodec {
  const AnnotationCodec();

  /// Deserializes [content] into an [AnnotationDocument].
  ///
  /// Some formats (such as Hamamatsu NDPA) require [context] for converting
  /// physical nanometers to Level 0 pixels.
  AnnotationDocument decode(String content, {SlidePhysicalContext? context});

  /// Serializes [doc] into formatted string output.
  ///
  /// Some formats (such as Hamamatsu NDPA) require [context] for converting
  /// Level 0 pixels to physical nanometers.
  String encode(AnnotationDocument doc, {SlidePhysicalContext? context});
}
