import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/ebara_data_service.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_filter_params.dart';
import '../services/analytics_service.dart';

List<ProductModel> _filterProductsIsolate(Map<String, dynamic> params) {
  final List<ProductModel> all = params['products'];
  final String query = params['query'].toString().toLowerCase();

  return all.where((product) {
    final name = product.name.toLowerCase();
    final model = product.model.toLowerCase();
    return name.contains(query) || model.contains(query);
  }).toList();
}

class HomeProvider with ChangeNotifier {
  final EbaraDataService _dataService;

  static const int _pageSize = 10;

  bool _isLoadingCategories = true;
  bool _isLoadingProducts = true;
  bool _isPaginating = false;

  String _selectedCategory = '';
  String _selectedCategoryId = '';
  String _searchQuery = '';

  int _currentLanguageId = 1;

  int _currentPage = 1;
  List<CategoryModel> _categories = [];
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  List<ProductModel> _visibleProducts = [];

  final Map<String, List<ProductModel>> _cacheByCategory = {};
  ProductFilterParams? _activeFilters;

  double _sunExposure = 5.0;
  bool _hasError = false;

  HomeProvider({required EbaraDataService dataService})
    : _dataService = dataService;

  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isPaginating => _isPaginating;
  String get selectedCategory => _selectedCategory;
  String get selectedCategoryId => _selectedCategoryId;
  List<CategoryModel> get categories => _categories;
  List<ProductModel> get visibleProducts => _visibleProducts;

  List<ProductModel> get filteredAllProducts => _filteredProducts;

  bool get hasMoreProducts =>
      _visibleProducts.length < _filteredProducts.length;

  bool get hasError => _hasError;

  void updateSunExposure(double value) {
    if (_sunExposure != value) {
      _sunExposure = value;
      if (_selectedCategoryId == '26' || _selectedCategory.contains('solar')) {
        loadProducts(_selectedCategoryId);
      }
    }
  }

  Future<void> reloadData(int languageId) async {
    _currentLanguageId = languageId;
    _cacheByCategory.clear();
    _categories.clear();
    _activeFilters = null;
    await loadCategories();
  }

  Future<void> loadCategories({bool refreshProducts = true}) async {
    _isLoadingCategories = true;
    notifyListeners();

    final previousSelectedId = _selectedCategoryId;

    _categories = await _dataService.fetchCategories(
      idLanguage: _currentLanguageId,
    );

    _isLoadingCategories = false;

    if (_categories.isNotEmpty) {
      final bool exists = _categories.any((c) => c.id == previousSelectedId);

      CategoryModel targetCategory;

      if (exists && previousSelectedId.isNotEmpty) {
        targetCategory = _categories.firstWhere(
          (c) => c.id == previousSelectedId,
        );
      } else {
        targetCategory = _categories.first;
      }

      _selectedCategoryId = targetCategory.id;
      _selectedCategory = targetCategory.slug;

      if (refreshProducts || !exists) {
        await loadProducts(_selectedCategoryId);
      }
    }
    notifyListeners();
  }

  Future<void> loadProducts(
    String categoryId, {
    ProductFilterParams? filters,
  }) async {
    _isLoadingProducts = true;
    _currentPage = 1;
    _visibleProducts.clear();

    if (_selectedCategoryId != categoryId) {
      _activeFilters = null;
    }

    if (filters != null) {
      _activeFilters = filters;

      AnalyticsService.logSearchFilters(
        flowRate: filters.flowRate,
        head: filters.heightGauge,
        application: filters.application,
        categoryId: categoryId,
      );
    }

    _selectedCategoryId = categoryId;

    final catIndex = _categories.indexWhere((c) => c.id == categoryId);
    if (catIndex != -1) {
      _selectedCategory = _categories[catIndex].slug;
    }

    notifyListeners();

    if (_activeFilters == null && _cacheByCategory.containsKey(categoryId)) {
      _allProducts = _cacheByCategory[categoryId]!;
      _hasError = false;
    } else {
      try {
        final searchParams =
            filters ??
            ProductFilterParams(
              categoryId: categoryId,
              idLanguage: _currentLanguageId,
              sunExposure: _sunExposure,
            );

        final fetched = await _dataService.searchProducts(searchParams);

        _allProducts = _dataService.groupProducts(fetched);

        if (_activeFilters == null) {
          _cacheByCategory[categoryId] = _allProducts;
        }
        _hasError = false;
      } catch (e) {
        _hasError = true;
        _isLoadingProducts = false;
        notifyListeners();
        return;
      }
    }

    await _updateFilteredProducts();
    _visibleProducts = _filteredProducts.take(_pageSize).toList();
    _isLoadingProducts = false;
    notifyListeners();
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

  void applyFilters(ProductFilterParams filters) {
    loadProducts(_selectedCategoryId, filters: filters);
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    _currentPage = 1;
    await _updateFilteredProducts();
    _visibleProducts = _filteredProducts.take(_pageSize).toList();
    notifyListeners();
  }

  void loadMore() {
    if (_isPaginating || !hasMoreProducts) {
      return;
    }
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

  void updateCategoryByIndex(int index) {
    if (index < 0 || index >= _categories.length) {
      return;
    }
    final cat = _categories[index];
    _activeFilters = null;
    _selectedCategory = cat.slug;
    _selectedCategoryId = cat.id;
    loadProducts(_selectedCategoryId);
  }
}
