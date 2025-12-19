import 'package:flutter/material.dart';
import 'api_service.dart';
import '../../core/utils/parse_util.dart';

class EbaraDataService {
  static final ApiService _api = ApiService(
    baseUrl: 'https://ebara.com.br/api',
    defaultHeaders: {
      'Content-Type': 'application/json',
      'api-version': '1',
      'api-token': 'EZTHB1985',
    },
  );

  static const Map<String, IconData> _categoryIcons = {
    'bombas-centrifugas': Icons.tune,
    'bombas-submersas': Icons.water,
    'bombas-submersiveis': Icons.water_drop,
    'sistema-solar-ecaros-1': Icons.wb_sunny,
    'sistemas-de-pressurizacao-1': Icons.compress,
    'industrial': Icons.factory,
    'residencial': Icons.home,
    '22': Icons.tune,
    '23': Icons.water,
    '24': Icons.water_drop,
    '26': Icons.wb_sunny,
    '27': Icons.compress,
    '28': Icons.factory,
    '29': Icons.home,
  };

  static List<Map<String, dynamic>>? _cachedCategories;

  static Future<List<Map<String, dynamic>>> fetchCategories({
    int idLanguage = 1,
  }) async {
    if (_cachedCategories != null) return _cachedCategories!;

    final response = await _api.get(
      'categories',
      queryParams: {'id_language': idLanguage},
      parser: (json) {
        if (json['status'] == true && json['data'] != null) {
          final List<dynamic> data = json['data'];
          return data.map((cat) => _mapCategory(cat)).toList();
        }
        return <Map<String, dynamic>>[];
      },
    );

    _cachedCategories = response.dataOrNull ?? [];
    return _cachedCategories!;
  }

  static Map<String, dynamic> _mapCategory(Map<String, dynamic> category) {
    final String id = category['id']?.toString() ?? '';
    final String slug = category['slug'] ?? '';

    return {
      'id': id,
      'slug': slug,
      'title': category['title'] ?? '',
      'subtitle': category['subtitle'] ?? '',
      'icon': _getIconForCategory(slug, id),
      'id_icon': category['id_icon'],
      'id_image_app': category['id_image_app'],
      'image': category['image'],
      'status': category['status'],
      'isChild': false, // Mantido conforme lógica original
      'appSearchVariationUp': category['appSearchVariationUp'],
      'appSearchVariationDown': category['appSearchVariationDown'],
      'appMaxResults': category['appMaxResults'],
      'related': category['related'],
      'useRelated': category['useRelated'],
    };
  }

  static IconData _getIconForCategory(String slug, String id) {
    return _categoryIcons[slug] ?? _categoryIcons[id] ?? Icons.category;
  }

  static void clearCategoryCache() => _cachedCategories = null;

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
    int? idLanguage,
  }) async {
    final response = await _api.get(
      'busca-bombas/search-bomb',
      queryParams: {
        'category': categoryId,
        'application': application,
        'line': line,
        'flow_rate': flowRate,
        'flow_rate_measure': flowRateMeasure,
        'height_gauge': heightGauge,
        'height_gauge_measure': heightGaugeMeasure,
        'frequency': frequency,
        'types': types,
        'inverter': inverter,
        'aligned_equipment': alignedEquipment,
        'id_language': idLanguage ?? 1,
      },
      parser: (json) {
        if (json['status'] != true) return <Map<String, dynamic>>[];
        final List<dynamic> result = json['data']['result'];
        return result.map<Map<String, dynamic>>(_mapProduct).toList();
      },
    );

    return response.dataOrNull ?? [];
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
      'ecommerce_link': p['ecommerce_link'] ?? '',
      'isSearch': p['app_product'] == '1',
    };
  }

  static Future<Map<String, dynamic>?> getProductDescriptions(
    String productId, {
    int? idLanguage,
  }) async {
    final response = await _api.get(
      'busca-bombas/get_descriptions',
      queryParams: {'id_product': productId, 'id_language': idLanguage ?? 1},
      parser: (json) {
        if (json['status'] != true || json['data'] == null) return null;
        final d = json['data'];
        return {
          'description': ParseUtil.parseHtmlToList(
            d['description_product'] ?? '',
            true,
          ),
          'options': ParseUtil.parseHtmlToList(
            d['description_options_product'] ?? '',
            true,
          ),
          'specifications': ParseUtil.parseHtmlToList(
            d['specification_product'] ?? '',
            false,
          ),
        };
      },
    );
    return response.dataOrNull;
  }

  static Future<List<Map<String, dynamic>>> getProductFiles(
    String productId, {
    int? idLanguage,
  }) async {
    final response = await _api.get(
      'busca-bombas/get_archives',
      queryParams: {'id_product': productId, 'id_language': idLanguage ?? 1},
      parser: (json) {
        if (json['status'] != true) return <Map<String, dynamic>>[];
        final List<dynamic> result = json['data'];
        final seenFiles = <String>{};
        final List<Map<String, dynamic>> uniqueList = [];

        for (var f in result) {
          final fileName = f['file'] ?? '';
          if (fileName.isEmpty || seenFiles.contains(fileName)) continue;
          seenFiles.add(fileName);
          uniqueList.add({
            'name': f['name'] ?? '',
            'path': f['path'] ?? '',
            'file': fileName,
            'extension': f['extension'] ?? '',
            'size': f['size'] ?? '0',
            'full_url': 'https://ebara.com.br/${f['path']}/$fileName',
          });
        }
        return uniqueList;
      },
    );
    return response.dataOrNull ?? [];
  }

  static List<Map<String, dynamic>> groupProducts(
    List<Map<String, dynamic>> products,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final p in products) {
      final key = p['id_product']?.toString() ?? p['slug_product'] ?? '';
      if (key.isEmpty) continue;
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(p);
    }
    return grouped.entries.map((e) {
      final base = e.value.first;
      return {...base, 'variants': e.value, 'variants_count': e.value.length};
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getProductApplications(
    String productId, {
    int? idLanguage,
  }) async {
    final response = await _api.get(
      'busca-bombas/get_applications',
      queryParams: {'id_product': productId, 'id_language': idLanguage ?? 1},
      parser: (json) {
        if (json['status'] != true) return <Map<String, dynamic>>[];
        final List<dynamic> data = json['data'];
        return data.map((e) => e as Map<String, dynamic>).toList();
      },
    );
    return response.dataOrNull ?? [];
  }

  static Future<List<Map<String, dynamic>>> getApplicationsByCategory(
    String categoryId,
  ) async {
    final response = await _api.get(
      'aplicacoes',
      queryParams: {'id_category': categoryId},
      parser: (json) {
        if (json['status'] != true) return <Map<String, dynamic>>[];
        final List<dynamic> data = json['data'];
        return data.map((e) => e as Map<String, dynamic>).toList();
      },
    );
    return response.dataOrNull ?? [];
  }

  static Future<List<Map<String, dynamic>>> getLines(
    String categoryId, {
    String application = 'TODOS',
  }) async {
    final response = await _api.get(
      'busca-bombas/get-lines',
      queryParams: {'id_category': categoryId, 'id_application': application},
      parser: (json) {
        if (json['status'] != true) return <Map<String, dynamic>>[];
        final List<dynamic> data = json['data'];
        return data.map((e) => e as Map<String, dynamic>).toList();
      },
    );
    return response.dataOrNull ?? [];
  }

  static Future<List<Map<String, dynamic>>> getFlowRates() async {
    final response = await _api.get(
      'busca-bombas/list-flow-rate',
      parser: (json) {
        if (json['status'] != true) return <Map<String, dynamic>>[];
        final List<dynamic> data = json['data'];
        return data.map((e) => e as Map<String, dynamic>).toList();
      },
    );
    return response.dataOrNull ?? [];
  }

  static Future<List<Map<String, dynamic>>> getHeightGauges() async {
    final response = await _api.get(
      'busca-bombas/list_height_gauge',
      parser: (json) {
        if (json['status'] != true) return <Map<String, dynamic>>[];
        final List<dynamic> data = json['data'];
        return data.map((e) => e as Map<String, dynamic>).toList();
      },
    );
    return response.dataOrNull ?? [];
  }

  static Future<List<Map<String, dynamic>>> getFrequencies() async {
    final response = await _api.get(
      'busca-bombas/get-frequency',
      parser: (json) {
        if (json['status'] != true) return <Map<String, dynamic>>[];
        final List<dynamic> data = json['data'];
        return data.map((e) => e as Map<String, dynamic>).toList();
      },
    );
    return response.dataOrNull ?? [];
  }

  static Future<List<Map<String, dynamic>>> getDiameters() async {
    final response = await _api.get(
      'busca-bombas/diametros',
      parser: (json) {
        if (json['status'] != true) return <Map<String, dynamic>>[];
        final List<dynamic> data = json['data'];
        return data.map((e) => e as Map<String, dynamic>).toList();
      },
    );
    return response.dataOrNull ?? [];
  }
}
