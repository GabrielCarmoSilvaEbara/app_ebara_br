import 'package:flutter/material.dart';
import 'api_service.dart';
import '../../core/utils/parse_util.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_filter_params.dart';
import '../constants/app_constants.dart';

class EbaraDataService {
  final ApiService _api;

  EbaraDataService({ApiService? api})
    : _api =
          api ??
          ApiService(
            baseUrl: AppConstants.apiBaseUrl,
            defaultHeaders: {
              'Content-Type': 'application/json',
              'api-version': AppConstants.apiVersion,
              'api-token': AppConstants.apiToken,
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

  Future<List<CategoryModel>> fetchCategories({int idLanguage = 1}) async {
    final response = await _api.get<List<CategoryModel>>(
      'categories',
      queryParams: {'id_language': idLanguage},
      cacheDuration: const Duration(days: 7),
      parser: (json) {
        if (json['status'] == true && json['data'] != null) {
          return (json['data'] as List).map((cat) {
            final String id = cat['id']?.toString() ?? '';
            final String slug = cat['slug'] ?? '';
            final icon =
                _categoryIcons[slug] ?? _categoryIcons[id] ?? Icons.category;
            return CategoryModel.fromJson(cat, icon: icon);
          }).toList();
        }
        return [];
      },
    );
    return response.dataOrNull ?? [];
  }

  Future<List<ProductModel>> searchProducts(ProductFilterParams params) async {
    String endpoint = 'busca-bombas/search-bomb';
    final bool isPressurizer =
        params.categoryId == '27' ||
        params.categoryId == 'sistemas-de-pressurizacao-1';

    if (isPressurizer) {
      endpoint = 'busca-bombas/search-bomb-pressurization';
    }

    final queryParams = params.toMap();

    final response = await _api.get<List<ProductModel>>(
      endpoint,
      queryParams: queryParams,
      cacheDuration: const Duration(hours: 4),
      parser: (json) {
        if (json['status'] != true) {
          return [];
        }
        final List result = json['data']['result'];
        return result.map((p) => ProductModel.fromJson(p)).toList();
      },
    );
    return response.dataOrNull ?? [];
  }

  List<ProductModel> groupProducts(List<ProductModel> products) {
    final Map<String, List<ProductModel>> grouped = {};
    for (final p in products) {
      final key = p.productId.isNotEmpty ? p.productId : (p.slugProduct ?? '');
      if (key.isEmpty) {
        continue;
      }
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(p);
    }

    return grouped.entries.map((e) {
      final base = e.value.first;
      return base.copyWith(variants: e.value);
    }).toList();
  }

  Future<Map<String, dynamic>?> getProductDescriptions(
    String productId, {
    int? idLanguage,
  }) async {
    final response = await _api.get<Map<String, dynamic>>(
      'busca-bombas/get_descriptions',
      queryParams: {'id_product': productId, 'id_language': idLanguage ?? 1},
      cacheDuration: const Duration(hours: 12),
      parser: (json) {
        if (json['status'] != true || json['data'] == null) {
          return <String, dynamic>{};
        }
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

  Future<List<Map<String, dynamic>>> getProductFiles(
    String productId, {
    int? idLanguage,
  }) async {
    final response = await _api.get<List<Map<String, dynamic>>>(
      'busca-bombas/get_archives',
      queryParams: {'id_product': productId, 'id_language': idLanguage ?? 1},
      cacheDuration: const Duration(hours: 4),
      parser: (json) {
        if (json['status'] != true) {
          return [];
        }
        final List result = json['data'];
        final seenFiles = <String>{};
        final List<Map<String, dynamic>> uniqueList = [];
        for (var f in result) {
          final fileName = f['file'] ?? '';
          if (fileName.isEmpty || seenFiles.contains(fileName)) {
            continue;
          }
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

  Future<List<Map<String, dynamic>>> getProductApplications(
    String productId, {
    int? idLanguage,
  }) async {
    final response = await _api.get<List<Map<String, dynamic>>>(
      'busca-bombas/get_applications',
      queryParams: {'id_product': productId, 'id_language': idLanguage ?? 1},
      cacheDuration: const Duration(hours: 4),
      parser: (json) {
        if (json['status'] != true) {
          return [];
        }
        return (json['data'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      },
    );
    return response.dataOrNull ?? [];
  }

  Future<List<Map<String, dynamic>>> getApplicationsByCategory(
    String categoryId,
  ) async {
    final response = await _api.get<List<Map<String, dynamic>>>(
      'aplicacoes',
      queryParams: {'id_category': categoryId},
      cacheDuration: const Duration(hours: 4),
      parser: (json) {
        if (json['status'] != true) {
          return [];
        }
        return (json['data'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      },
    );
    return response.dataOrNull ?? [];
  }

  Future<List<Map<String, dynamic>>> getLines(
    String categoryId, {
    String application = 'TODOS',
  }) async {
    final response = await _api.get<List<Map<String, dynamic>>>(
      'busca-bombas/get-lines',
      queryParams: {'id_category': categoryId, 'id_application': application},
      cacheDuration: const Duration(hours: 4),
      parser: (json) {
        if (json['status'] != true) {
          return [];
        }
        return (json['data'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      },
    );
    return response.dataOrNull ?? [];
  }

  Future<List<Map<String, dynamic>>> getFrequencies() async {
    final response = await _api.get<List<Map<String, dynamic>>>(
      'busca-bombas/get-frequency',
      cacheDuration: const Duration(days: 30),
      parser: (json) {
        if (json['status'] != true) {
          return [];
        }
        return (json['data'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      },
    );
    return response.dataOrNull ?? [];
  }

  Future<List<Map<String, dynamic>>> getFlowRates() async {
    final response = await _api.get<List<Map<String, dynamic>>>(
      'busca-bombas/list-flow-rate',
      cacheDuration: const Duration(days: 30),
      parser: (json) {
        if (json['status'] != true) {
          return [];
        }
        return (json['data'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      },
    );
    return response.dataOrNull ?? [];
  }

  Future<List<Map<String, dynamic>>> getHeightGauges() async {
    final response = await _api.get<List<Map<String, dynamic>>>(
      'busca-bombas/list_height_gauge',
      cacheDuration: const Duration(days: 30),
      parser: (json) {
        if (json['status'] != true) {
          return [];
        }
        return (json['data'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      },
    );
    return response.dataOrNull ?? [];
  }

  Future<List<Map<String, dynamic>>> getSystemTypes() async {
    final response = await _api.get<List<Map<String, dynamic>>>(
      'busca-bombas/get_types',
      cacheDuration: const Duration(days: 30),
      parser: (json) {
        if (json['status'] != true) {
          return [];
        }
        return (json['data'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      },
    );
    return response.dataOrNull ?? [];
  }

  Future<List<String>> getWellDiameters() async {
    final response = await _api.get<List<String>>(
      'busca-bombas/diametros',
      cacheDuration: const Duration(days: 30),
      parser: (json) {
        if (json['status'] != true) {
          return [];
        }
        return (json['data'] as List).map((e) => e.toString()).toList();
      },
    );
    return response.dataOrNull ?? [];
  }
}
