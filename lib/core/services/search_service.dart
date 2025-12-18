import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchService {
  static const String _baseUrl = 'https://ebara.com.br/api';

  static Future<List<Map<String, dynamic>>> searchProducts({
    required String categoryId,
    String application = 'TODOS',
    String line = 'TODOS',
    double flowRate = 0,
    String flowRateMeasure = 'm3/h',
    double heightGauge = 0,
    String heightGaugeMeasure = 'm',
    int frequency = 60,
    int types = 0,
    String inverter = 'TODOS',
    int alignedEquipment = 0,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/busca-bombas/search-bomb'
        '?category=$categoryId'
        '&application=$application'
        '&line=$line'
        '&flow_rate=$flowRate'
        '&flow_rate_measure=$flowRateMeasure'
        '&height_gauge=$heightGauge'
        '&height_gauge_measure=$heightGaugeMeasure'
        '&frequency=$frequency'
        '&types=$types'
        '&inverter=$inverter'
        '&aligned_equipment=$alignedEquipment',
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'api-version': '1',
          'api-token': 'EZTHB1985',
        },
      );

      if (response.statusCode != 200) return [];

      final jsonResponse = json.decode(response.body);

      if (jsonResponse['status'] != true) return [];

      final List<dynamic> result = jsonResponse['data']['result'];

      return result.map<Map<String, dynamic>>(_mapProduct).toList();
    } catch (_) {
      return [];
    }
  }

  static List<Map<String, dynamic>> groupProducts(
    List<Map<String, dynamic>> products,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final p in products) {
      final key = p['id_product'] ?? p['slug_product'];

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(p);
    }

    return grouped.entries.map((e) {
      final base = e.value.first;

      return {...base, 'variants': e.value, 'variants_count': e.value.length};
    }).toList();
  }

  static Map<String, dynamic> _mapProduct(dynamic p) {
    return {
      'id': p['id'],
      'id_product': p['id_product'],
      'name': p['title_product'] ?? '',
      'model': p['model'] ?? '',
      'image': p['file'] ?? '',
      'slug_category': p['slug_category'] ?? '',
      'slug_product': p['slug_product'],
      'power': p['power'],
      'frequency': p['frequency'],
      'rpm': p['rpm'],
      'rate_min': p['rate_min'],
      'rate_max': p['rate_max'],
      'mca_min': p['mca_min'],
      'mca_max': p['mca_max'],
      'app_product': p['app_product'],
      'isSearch': p['app_product'] == '1',
      'description': p['description_product'] ?? '',
      'options': p['description_options_product'] ?? '',
      'specifications': p['specification_product'] ?? '',
    };
  }

  static Future<List<Map<String, dynamic>>> getProductFiles(
    String productId,
  ) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/busca-bombas/get_archives?id_product=$productId',
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'api-version': '1',
          'api-token': 'EZTHB1985',
        },
      );

      if (response.statusCode != 200) return [];

      final jsonResponse = json.decode(response.body);

      if (jsonResponse['status'] != true) return [];

      final List<dynamic> result = jsonResponse['data'];

      return result
          .map<Map<String, dynamic>>(
            (f) => {
              'name': f['name'] ?? '',
              'path': f['path'] ?? '',
              'file': f['file'] ?? '',
              'extension': f['extension'] ?? '',
              'size': f['size'] ?? '0',
              'full_url': 'https://ebara.com.br/${f['path']}/${f['file']}',
            },
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}
