/// Converts any non-ASCII Unicode characters (code point > 127) into
/// numeric XML character entities (e.g. `&#1069;`).
///
/// Aperio ImageScope on Windows does not support UTF-8 in XML attributes
/// and strips the 8th bit of raw UTF-8 / non-ASCII bytes, causing text
/// corruption ("krakozyabry"). Numeric XML character entities preserve
/// non-English text (Cyrillic, CJK, etc.) safely across all Windows codepages.
String escapeNonAsciiToXmlEntities(String xml) {
  final sb = StringBuffer();
  for (final rune in xml.runes) {
      if (rune > 127) {
          sb.write('&#$rune;');
      } else {
          sb.writeCharCode(rune);
      }
  }
return sb.toString();
}