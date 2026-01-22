import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../../core/utils/parse_util.dart';
import '../../core/extensions/string_extensions.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_filter_params.dart';
import '../constants/app_constants.dart';
import '../constants/api_endpoints.dart';

List<CategoryModel> _parseCategories(dynamic json) {
  if (json['status'] == true && json['data'] != null) {
    return (json['data'] as List).map((cat) {
      final String id = cat['id']?.toString() ?? '';
      final String slug = cat['slug'] ?? '';
      final icon = CategoryUtil.getIconForCategory(id, slug);
      return CategoryModel.fromJson(cat, icon: icon);
    }).toList();
  }
  return [];
}

List<ProductModel> _parseProducts(dynamic json) {
  if (json['status'] != true) return [];
  final List result = json['data']['result'];
  return result.map((p) => ProductModel.fromJson(p)).toList();
}

List<ProductModel> _groupProducts(List<ProductModel> products) {
  final Map<String, List<ProductModel>> grouped = {};
  for (final p in products) {
    final key = p.productId.isNotEmpty ? p.productId : (p.slugProduct ?? '');
    if (key.isEmpty) continue;
    grouped.putIfAbsent(key, () => []);
    grouped[key]!.add(p);
  }

  return grouped.entries.map((e) {
    final base = e.value.first;
    return base.copyWith(variants: e.value);
  }).toList();
}

Map<String, dynamic> _parseDescriptions(dynamic json) {
  if (json['status'] != true || json['data'] == null) return {};
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
}

List<Map<String, dynamic>> _parseFiles(dynamic json) {
  if (json['status'] != true) return [];
  final List result = json['data'];
  final seenFiles = <String>{};
  final List<Map<String, dynamic>> uniqueList = [];

  for (var f in result) {
    final String fileName = f['file'] ?? '';
    if (fileName.isEmpty || seenFiles.contains(fileName)) continue;

    seenFiles.add(fileName);
    final String path = f['path'] ?? '';

    uniqueList.add({
      'name': f['name'] ?? '',
      'path': path,
      'file': fileName,
      'extension': f['extension'] ?? '',
      'size': f['size'] ?? '0',
      'full_url': fileName.toEbaraFileUrl(path),
    });
  }
  return uniqueList;
}

List<Map<String, dynamic>> _parseGenericList(dynamic json) {
  if (json['status'] != true) return [];
  return (json['data'] as List).map((e) => e as Map<String, dynamic>).toList();
}

List<Map<String, dynamic>> _parseRepresentatives(dynamic json) {
  if (json['status'] != true || json['data'] == null) return [];
  return List<Map<String, dynamic>>.from(json['data']);
}

class EbaraDataService {
  final ApiService _api;

  static const Duration _shortCache = Duration(hours: 4);
  static const Duration _longCache = Duration(days: 365);

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

  Future<List<CategoryModel>> fetchCategories({int idLanguage = 1}) async {
    final response = await _api.get<dynamic>(
      ApiEndpoints.categories,
      queryParams: {'id_language': idLanguage},
      cacheDuration: const Duration(days: 7),
      offlineCacheDuration: _longCache,
    );
    if (!response.isSuccess) return [];
    return compute(_parseCategories, response.data);
  }

  Future<List<ProductModel>> searchProducts(ProductFilterParams params) async {
    String endpoint = ApiEndpoints.searchBomb;
    final bool isPressurizer =
        params.categoryId == CategoryIds.pressurizer ||
        params.categoryId == CategorySlugs.pressurizer;

    if (isPressurizer) endpoint = ApiEndpoints.searchPressurization;

    final response = await _api.get<dynamic>(
      endpoint,
      queryParams: params.toMap(),
      cacheDuration: _shortCache,
      offlineCacheDuration: _longCache,
    );

    if (!response.isSuccess) return [];
    return compute(_parseProducts, response.data);
  }

  Future<List<ProductModel>> groupProducts(List<ProductModel> products) async {
    return compute(_groupProducts, products);
  }

  Future<Map<String, dynamic>?> getProductDescriptions(
    String productId, {
    int? idLanguage,
  }) async {
    final response = await _api.get<dynamic>(
      ApiEndpoints.getDescriptions,
      queryParams: {'id_product': productId, 'id_language': idLanguage ?? 1},
      cacheDuration: const Duration(hours: 12),
      offlineCacheDuration: _longCache,
    );
    if (!response.isSuccess) return null;
    return compute(_parseDescriptions, response.data);
  }

  Future<List<Map<String, dynamic>>> getProductFiles(
    String productId, {
    int? idLanguage,
  }) async {
    final response = await _api.get<dynamic>(
      ApiEndpoints.getArchives,
      queryParams: {'id_product': productId, 'id_language': idLanguage ?? 1},
      cacheDuration: _shortCache,
      offlineCacheDuration: _longCache,
    );
    if (!response.isSuccess) return [];
    return compute(_parseFiles, response.data);
  }

  Future<List<Map<String, dynamic>>> getProductApplications(
    String productId, {
    int? idLanguage,
  }) async {
    final response = await _api.get<dynamic>(
      ApiEndpoints.getApplications,
      queryParams: {'id_product': productId, 'id_language': idLanguage ?? 1},
      cacheDuration: _shortCache,
      offlineCacheDuration: _longCache,
    );
    if (!response.isSuccess) return [];
    return compute(_parseGenericList, response.data);
  }

  Future<List<Map<String, dynamic>>> getApplicationsByCategory(
    String categoryId,
  ) async {
    final response = await _api.get<dynamic>(
      ApiEndpoints.applicationsList,
      queryParams: {'id_category': categoryId},
      cacheDuration: _shortCache,
      offlineCacheDuration: _longCache,
    );
    if (!response.isSuccess) return [];
    return compute(_parseGenericList, response.data);
  }

  Future<List<Map<String, dynamic>>> _getSimpleList(
    String endpoint, {
    Map<String, dynamic>? params,
  }) async {
    final response = await _api.get<dynamic>(
      endpoint,
      queryParams: params,
      cacheDuration: _shortCache,
      offlineCacheDuration: _longCache,
    );
    if (!response.isSuccess) return [];
    return compute(_parseGenericList, response.data);
  }

  Future<List<Map<String, dynamic>>> getLines(
    String categoryId, {
    String application = SystemConstants.all,
  }) {
    return _getSimpleList(
      ApiEndpoints.getLines,
      params: {'id_category': categoryId, 'id_application': application},
    );
  }

  Future<List<Map<String, dynamic>>> getFrequencies() =>
      _getSimpleList(ApiEndpoints.getFrequency);

  Future<List<Map<String, dynamic>>> getFlowRates() =>
      _getSimpleList(ApiEndpoints.listFlowRate);

  Future<List<Map<String, dynamic>>> getHeightGauges() =>
      _getSimpleList(ApiEndpoints.listHeightGauge);

  Future<List<Map<String, dynamic>>> getSystemTypes() =>
      _getSimpleList(ApiEndpoints.getTypes);

  Future<List<String>> getWellDiameters() async {
    final response = await _api.get<List<dynamic>>(
      ApiEndpoints.getDiameters,
      cacheDuration: const Duration(days: 30),
      offlineCacheDuration: _longCache,
    );

    if (!response.isSuccess) return [];
    return response.data!.map((e) => e.toString()).toList();
  }

  Future<String?> getAppVersionInfo() async {
    final response = await _api.get<dynamic>(
      ApiEndpoints.update,
      cacheDuration: const Duration(minutes: 30),
    );

    if (response.isSuccess && response.data != null) {
      if (response.data is Map && response.data['data'] != null) {
        return response.data['data'].toString();
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getRepresentatives({
    String? state,
    String? brandId,
    int idLanguage = 1,
  }) async {
    final Map<String, dynamic> params = {'lang': idLanguage};
    if (state != null && state.isNotEmpty) params['state'] = state;
    if (brandId != null && brandId.isNotEmpty) {
      params['id_brand'] = brandId;
    }

    final response = await _api.get<dynamic>(
      ApiEndpoints.searchRepresentatives,
      queryParams: params,
      cacheDuration: _shortCache,
    );

    if (!response.isSuccess) return [];
    return compute(_parseRepresentatives, response.data);
  }
}
