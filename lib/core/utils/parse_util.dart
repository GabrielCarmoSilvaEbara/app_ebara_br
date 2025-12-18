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
}
