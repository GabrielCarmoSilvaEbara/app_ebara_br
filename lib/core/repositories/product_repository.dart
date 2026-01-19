import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/product_filter_params.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/ebara_data_service.dart';
import '../providers/connectivity_provider.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';

class ProductRepository {
  final ApiService _api;
  final CacheService cache;
  final ConnectivityProvider connectivity;

  static const Duration _freshCacheDuration = Duration(days: 7);
  static const Duration _shortCacheDuration = Duration(hours: 4);
  static const Duration _offlineCacheDuration = Duration(days: 365);

  ProductRepository({
    required ApiService api,
    required this.cache,
    required this.connectivity,
  }) : _api = api;

  Future<List<CategoryModel>> fetchCategories({int idLanguage = 1}) async {
    final queryParams = {'id_language': idLanguage};

    final response = await _api.get<dynamic>(
      ApiEndpoints.categories,
      queryParams: queryParams,
      cacheDuration: _freshCacheDuration,
      offlineCacheDuration: _offlineCacheDuration,
    );

    if (response.isSuccess && response.data != null) {
      return compute(parseCategoriesIsolate, response.data);
    }

    return [];
  }

  Future<List<ProductModel>> searchProducts(ProductFilterParams params) async {
    String endpoint = ApiEndpoints.searchBomb;
    final bool isPressurizer =
        params.categoryId == CategoryIds.pressurizer ||
        params.categoryId == CategorySlugs.pressurizer;

    if (isPressurizer) endpoint = ApiEndpoints.searchPressurization;

    final queryParams = params.toMap();

    final response = await _api.get<dynamic>(
      endpoint,
      queryParams: queryParams,
      cacheDuration: _shortCacheDuration,
      offlineCacheDuration: _offlineCacheDuration,
    );

    if (response.isSuccess && response.data != null) {
      return compute(parseProductsIsolate, response.data);
    }

    return [];
  }
}

List<CategoryModel> parseCategoriesIsolate(dynamic json) {
  if (json['status'] == true && json['data'] != null) {
    return (json['data'] as List).map((cat) {
      final String id = cat['id']?.toString() ?? '';
      final String slug = cat['slug'] ?? '';
      final icon =
          EbaraDataService.categoryIcons[slug] ??
          EbaraDataService.categoryIcons[id];
      return CategoryModel.fromJson(cat, icon: icon);
    }).toList();
  }
  return [];
}

List<ProductModel> parseProductsIsolate(dynamic json) {
  if (json['status'] != true) return [];
  final List result = json['data']['result'];
  return result.map((p) => ProductModel.fromJson(p)).toList();
}
