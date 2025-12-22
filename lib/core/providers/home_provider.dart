import 'dart:async';
import 'package:flutter/material.dart';
import '../services/ebara_data_service.dart';
import '../services/location_service.dart';
import '../services/translation_service.dart';

class HomeProvider with ChangeNotifier {
  static const int _pageSize = 10;

  bool _isLoadingCategories = true;
  bool _isLoadingProducts = true;
  bool _isPaginating = false;

  String _city = '';
  String _state = '';
  String _country = '';

  String _selectedCategory = '';
  String _selectedCategoryId = '';
  String _searchQuery = '';

  int _currentPage = 1;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _visibleProducts = [];
  final Map<String, List<Map<String, dynamic>>> _cacheByCategory = {};

  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isPaginating => _isPaginating;
  String get city => _city;
  String get selectedCategory => _selectedCategory;
  String get selectedCategoryId => _selectedCategoryId;
  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get visibleProducts => _visibleProducts;

  List<Map<String, dynamic>> get filteredAllProducts {
    if (_searchQuery.isEmpty) return _allProducts;
    final query = _searchQuery.toLowerCase();
    return _allProducts.where((product) {
      final name = (product['name'] ?? '').toString().toLowerCase();
      final model = (product['model'] ?? '').toString().toLowerCase();
      return name.contains(query) || model.contains(query);
    }).toList();
  }

  bool get hasMoreProducts =>
      _visibleProducts.length < filteredAllProducts.length;

  Future<void> initialize() async {
    if (_categories.isNotEmpty) return;
    _city = TranslationService.translate('search');
    await initLocation();
  }

  Future<void> initLocation() async {
    final location = await LocationService.getCurrentCity();
    _updateLocationState(location);
    await loadCategories();
  }

  void _updateLocationState(Map<String, String>? location) {
    if (location == null || location['city'] == null) {
      _city = TranslationService.translate('choose_location');
    } else {
      _city = location['city']!;
      _country = location['country'] ?? '';
      _state = location['state'] ?? '';

      TranslationService.setLanguageByCountry(_country);

      _cacheByCategory.clear();
    }
    notifyListeners();
  }

  Future<void> loadCategories({bool refreshProducts = true}) async {
    _isLoadingCategories = true;
    notifyListeners();

    _categories = await EbaraDataService.fetchCategories(
      idLanguage: TranslationService.getLanguageId(),
    );

    _isLoadingCategories = false;
    if (_categories.isNotEmpty) {
      if (refreshProducts || _selectedCategoryId.isEmpty) {
        _selectedCategory = _categories.first['slug'] ?? '';
        _selectedCategoryId = _categories.first['id'] ?? '';
        await loadProducts(_selectedCategoryId);
      }
    }
    notifyListeners();
  }

  Future<void> loadProducts(String categoryId) async {
    _isLoadingProducts = true;
    _currentPage = 1;
    _visibleProducts.clear();
    notifyListeners();

    if (_cacheByCategory.containsKey(categoryId)) {
      _allProducts = _cacheByCategory[categoryId]!;
    } else {
      final fetched = await EbaraDataService.searchProducts(
        categoryId: categoryId,
        idLanguage: TranslationService.getLanguageId(),
      );
      _allProducts = EbaraDataService.groupProducts(fetched);
      _cacheByCategory[categoryId] = _allProducts;
    }

    _visibleProducts = filteredAllProducts.take(_pageSize).toList();
    _isLoadingProducts = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    _visibleProducts = filteredAllProducts.take(_pageSize).toList();
    notifyListeners();
  }

  void loadMore() {
    if (_isPaginating || !hasMoreProducts) return;
    _isPaginating = true;
    notifyListeners();

    final next = filteredAllProducts
        .skip(_currentPage * _pageSize)
        .take(_pageSize)
        .toList();

    _visibleProducts.addAll(next);
    _currentPage++;
    _isPaginating = false;
    notifyListeners();
  }

  void updateCategoryByIndex(int index) {
    if (index < 0 || index >= _categories.length) return;
    final cat = _categories[index];
    _selectedCategory = cat['slug'] ?? '';
    _selectedCategoryId = cat['id'] ?? '';
    loadProducts(_selectedCategoryId);
  }

  Future<void> updateManualLocation(
    String city,
    String state,
    String country,
  ) async {
    _city = city;
    _state = state;
    _country = country;

    TranslationService.setLanguageByCountry(country);

    _cacheByCategory.clear();
    _categories.clear();

    await loadCategories();
    notifyListeners();
  }
}
