import 'package:html_unescape/html_unescape.dart';

class ParseUtil {
  static final _htmlUnescape = HtmlUnescape();

  static String formatValue(dynamic value) {
    if (value == null || value.toString().isEmpty) return "0.00";
    try {
      final double parsed = double.parse(value.toString());
      return parsed.toStringAsFixed(2);
    } catch (e) {
      return value.toString();
    }
  }

  static double? toDoubleSafe(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return null;
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return null;
  }

  static int? toIntSafe(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) {
      if (value.isEmpty) return null;
      return int.tryParse(value) ?? 0;
    }
    return null;
  }

  static List<String> parseHtmlToList(String content, bool removeTraces) {
    if (content.isEmpty) return [];

    String normalized = content
        .replaceAll('</li>', '###')
        .replaceAll('</ul>', '###')
        .replaceAll('</ol>', '###')
        .replaceAll('<br>', '###')
        .replaceAll('<br />', '###')
        .replaceAll('</p>', '###');

    if (removeTraces) {
      normalized = normalized.replaceAll(' - ', '###');
    }

    normalized = normalized.replaceAll(RegExp(r'<[^>]*>'), '');
    normalized = _htmlUnescape.convert(normalized);

    return normalized
        .split('###')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String normalizeSpecialChars(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll('³', '3')
        .replaceAll('²', '2')
        .replaceAll('¹', '1')
        .replaceAll('⁰', '0');
  }
}
