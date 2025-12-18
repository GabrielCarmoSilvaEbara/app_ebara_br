import 'dart:convert';
import 'package:http/http.dart' as http;

class LinesService {
  static const String _baseUrl = 'https://ebara.com.br/api';

  static Future<List<Map<String, dynamic>>> fetchLines({
    required String categoryId,
    String applicationId = 'TODOS',
    String systemType = '0',
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/busca-bombas/get-lines'
        '?id_category=$categoryId'
        '&id_application=$applicationId'
        '&system_type=$systemType',
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

      final List<dynamic> data = jsonResponse['data'];

      return data
          .where((e) => e['id'] != 'TODOS')
          .map<Map<String, dynamic>>(
            (e) => {
              'id': e['id'],
              'name': e['title_product'] ?? '',
              'model': e['model'] ?? '',
              'slug_category': e['slug_category'] ?? '',
              'image': e['file'] ?? '',
            },
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}
