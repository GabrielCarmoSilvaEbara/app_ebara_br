import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repositories/product_repository.dart';
import '../services/ebara_data_service.dart';
import '../models/product_model.dart';
import '../models/product_filter_params.dart';
import '../services/analytics_service.dart';
import '../constants/app_constants.dart';

List<ProductModel> _filterProductsIsolate(Map<String, dynamic> params) {
  final List<ProductModel> all = params['products'];
  final String query = params['query'].toString().toLowerCase();

  return all.where((product) {
    final name = product.name.toLowerCase();
    final model = product.model.toLowerCase();
    return name.contains(query) || model.contains(query);
  }).toList();
}

class ProductsProvider with ChangeNotifier {
  final ProductRepository _repository;
  final EbaraDataService _dataService;

  static const int _pageSize = 10;

  bool _isLoading = false;
  bool _isPaginating = false;
  bool _hasError = false;

  String _currentCategoryId = '';
  String _searchQuery = '';
  Timer? _debounceTimer;

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  List<ProductModel> _visibleProducts = [];
  int _currentPage = 1;

  ProductFilterParams? _activeFilters;
  final Map<String, List<ProductModel>> _cacheByCategory = {};

  ProductsProvider({
    required ProductRepository repository,
    required EbaraDataService dataService,
  }) : _repository = repository,
       _dataService = dataService;

  bool get isLoading => _isLoading;
  bool get isPaginating => _isPaginating;
  bool get hasError => _hasError;
  List<ProductModel> get visibleProducts => _visibleProducts;
  bool get hasMoreProducts =>
      _visibleProducts.length < _filteredProducts.length;

  Future<void> loadProducts(
    String categoryId,
    int languageId, {
    ProductFilterParams? filters,
  }) async {
    _isLoading = true;
    _hasError = false;
    _currentPage = 1;
    _visibleProducts.clear();

    if (_currentCategoryId != categoryId) {
      _activeFilters = null;
    }
    _currentCategoryId = categoryId;

    if (filters != null) {
      _activeFilters = filters;
      AnalyticsService.logSearchFilters(
        flowRate: filters.flowRate,
        head: filters.heightGauge,
        application: filters.application,
        categoryId: categoryId,
      );
    }

    notifyListeners();

    try {
      if (_activeFilters == null && _cacheByCategory.containsKey(categoryId)) {
        _allProducts = _cacheByCategory[categoryId]!;
      } else {
        final searchParams =
            filters ??
            ProductFilterParams(categoryId: categoryId, idLanguage: languageId);

        final fetched = await _repository.searchProducts(searchParams);
        _allProducts = await _dataService.groupProducts(fetched);

        if (_activeFilters == null) {
          _cacheByCategory[categoryId] = _allProducts;
        }
      }

      await _updateFilteredProducts();
      _visibleProducts = _filteredProducts.take(_pageSize).toList();
    } catch (e) {
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void onSearchInputChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      _currentPage = 1;
      _updateFilteredProducts().then((_) {
        _visibleProducts = _filteredProducts.take(_pageSize).toList();
        notifyListeners();
      });
    });
  }

  void clearSearch() {
    _searchQuery = '';
    _updateFilteredProducts().then((_) {
      _visibleProducts = _filteredProducts.take(_pageSize).toList();
      notifyListeners();
    });
  }

  Future<void> _updateFilteredProducts() async {
    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_allProducts);
    } else {
      _filteredProducts = await compute(_filterProductsIsolate, {
        'products': _allProducts,
        'query': _searchQuery,
      });
    }
  }

  void loadMore() {
    if (_isPaginating || !hasMoreProducts) return;

    _isPaginating = true;
    notifyListeners();

    final next = _filteredProducts
        .skip(_currentPage * _pageSize)
        .take(_pageSize)
        .toList();

    _visibleProducts.addAll(next);
    _currentPage++;
    _isPaginating = false;
    notifyListeners();
  }

  Future<ProductModel?> fetchProductByDeepLink(
    String categoryId,
    String productId,
  ) async {
    try {
      final results = await _repository.searchProducts(
        ProductFilterParams(categoryId: categoryId, line: SystemConstants.all),
      );
      final group = await _dataService.groupProducts(results);

      return group.firstWhere(
        (p) =>
            p.productId == productId ||
            p.variants.any((v) => v.productId == productId),
      );
    } catch (e) {
      return null;
    }
  }
}
