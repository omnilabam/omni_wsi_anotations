/// Utility for converting between color representations:
/// ARGB integer, Hex (#RRGGBB, #AARRGGBB), Aperio BGR integer, and QuPath RGB lists.
class ColorUtils {
  ColorUtils._();

  /// Default opaque alpha channel mask.
  static const int defaultAlpha = 0xFF000000;

  /// Parses a color from dynamic input:
  /// - Hex String (`#FF0000`, `#FFFF0000`, `FF0000`)
  /// - Integer (ARGB or RGB; if alpha is 0, defaults to opaque alpha 0xFF)
  /// - List of numbers (`[255, 0, 0]` or `[255, 0, 0, 255]`)
  static int? parseColor(dynamic input) {
    if (input == null) return null;
    if (input is int) {
      // If alpha is 0 (i.e. only 24 bits set), set alpha to 0xFF
      if ((input & 0xFF000000) == 0 && input > 0) {
        return input | defaultAlpha;
      }
      return input;
    }
    if (input is String) {
      return parseHex(input);
    }
    if (input is List && input.isNotEmpty) {
      return rgbListToColor(input.cast<num>());
    }
    return null;
  }

  /// Parses a hex color string (e.g. `#FF0000`, `#FFFF0000`, `0xFF0000`).
  static int parseHex(String hexString) {
    var hex = hexString.trim();
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    } else if (hex.startsWith('0x') || hex.startsWith('0X')) {
      hex = hex.substring(2);
    }

    if (hex.length == 3) {
      // #RGB -> #RRGGBB
      final r = hex[0];
      final g = hex[1];
      final b = hex[2];
      hex = '$r$r$g$g$b$b';
    } else if (hex.length == 4) {
      // #ARGB -> #AARRGGBB
      final a = hex[0];
      final r = hex[1];
      final g = hex[2];
      final b = hex[3];
      hex = '$a$a$r$r$g$g$b$b';
    }

    final parsed = int.parse(hex, radix: 16);
    if (hex.length <= 6) {
      return parsed | defaultAlpha;
    }
    return parsed;
  }

  /// Converts ARGB color integer to hex string.
  /// If [includeAlpha] is false, returns `#RRGGBB`.
  /// If [includeAlpha] is true, returns `#AARRGGBB`.
  static String colorToHex(int color, {bool includeAlpha = false}) {
    final a = (color >> 24) & 0xFF;
    final r = (color >> 16) & 0xFF;
    final g = (color >> 8) & 0xFF;
    final b = color & 0xFF;

    final rHex = r.toRadixString(16).padLeft(2, '0').toUpperCase();
    final gHex = g.toRadixString(16).padLeft(2, '0').toUpperCase();
    final bHex = b.toRadixString(16).padLeft(2, '0').toUpperCase();

    if (includeAlpha) {
      final aHex = a.toRadixString(16).padLeft(2, '0').toUpperCase();
      return '#$aHex$rHex$gHex$bHex';
    }
    return '#$rHex$gHex$bHex';
  }

  /// Converts an Aperio ImageScope BGR 32-bit integer (`0x00BBGGRR`) to ARGB integer.
  static int bgrIntToColor(int bgr, [int alpha = 0xFF]) {
    final r = bgr & 0xFF;
    final g = (bgr >> 8) & 0xFF;
    final b = (bgr >> 16) & 0xFF;
    return ((alpha & 0xFF) << 24) | (r << 16) | (g << 8) | b;
  }

  /// Converts an ARGB integer to an Aperio ImageScope BGR 32-bit integer (`0x00BBGGRR`).
  static int colorToBgrInt(int argb) {
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return (b << 16) | (g << 8) | r;
  }

  /// Converts an RGB or RGBA list of numbers to ARGB integer.
  static int rgbListToColor(List<num> rgb) {
    if (rgb.length < 3) {
      throw ArgumentError('RGB list must contain at least 3 values: $rgb');
    }
    final r = (rgb[0].toInt()).clamp(0, 255);
    final g = (rgb[1].toInt()).clamp(0, 255);
    final b = (rgb[2].toInt()).clamp(0, 255);
    final a = rgb.length >= 4 ? (rgb[3].toInt()).clamp(0, 255) : 255;
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  /// Converts ARGB integer to a List of `[r, g, b]` (or `[r, g, b, a]`).
  static List<int> colorToRgbList(int color, {bool includeAlpha = false}) {
    final a = (color >> 24) & 0xFF;
    final r = (color >> 16) & 0xFF;
    final g = (color >> 8) & 0xFF;
    final b = color & 0xFF;
    if (includeAlpha) {
      return [r, g, b, a];
    }
    return [r, g, b];
  }
}
