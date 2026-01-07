import '../services/api_service.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_filter_params.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../services/ebara_data_service.dart';
import 'package:flutter/foundation.dart';

class ProductRepository {
  final ApiService _api;

  ProductRepository({required ApiService api}) : _api = api;

  Future<List<CategoryModel>> fetchCategories({int idLanguage = 1}) async {
    final response = await _api.get<dynamic>(
      ApiEndpoints.categories,
      queryParams: {'id_language': idLanguage},
      cacheDuration: const Duration(days: 7),
    );
    if (!response.isSuccess) return [];

    return compute(parseCategoriesIsolate, response.data);
  }

  Future<List<ProductModel>> searchProducts(ProductFilterParams params) async {
    String endpoint = ApiEndpoints.searchBomb;
    final bool isPressurizer =
        params.categoryId == CategoryIds.pressurizer ||
        params.categoryId == CategoryIds.pressurizerSlug;

    if (isPressurizer) endpoint = ApiEndpoints.searchPressurization;

    final response = await _api.get<dynamic>(
      endpoint,
      queryParams: params.toMap(),
      cacheDuration: const Duration(hours: 4),
    );

    if (!response.isSuccess) return [];
    return compute(parseProductsIsolate, response.data);
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
