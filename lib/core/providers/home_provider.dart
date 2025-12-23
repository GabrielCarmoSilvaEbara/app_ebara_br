import 'dart:async';
import 'package:flutter/material.dart';
import '../services/ebara_data_service.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class HomeProvider with ChangeNotifier {
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
  List<ProductModel> _visibleProducts = [];
  final Map<String, List<ProductModel>> _cacheByCategory = {};

  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isPaginating => _isPaginating;
  String get selectedCategory => _selectedCategory;
  String get selectedCategoryId => _selectedCategoryId;
  List<CategoryModel> get categories => _categories;
  List<ProductModel> get visibleProducts => _visibleProducts;

  List<ProductModel> get filteredAllProducts {
    if (_searchQuery.isEmpty) return _allProducts;
    final query = _searchQuery.toLowerCase();
    return _allProducts.where((product) {
      final name = product.name.toLowerCase();
      final model = product.model.toLowerCase();
      return name.contains(query) || model.contains(query);
    }).toList();
  }

  bool get hasMoreProducts =>
      _visibleProducts.length < filteredAllProducts.length;

  Future<void> reloadData(int languageId) async {
    _currentLanguageId = languageId;
    _cacheByCategory.clear();
    _categories.clear();
    await loadCategories();
  }

  Future<void> loadCategories({bool refreshProducts = true}) async {
    _isLoadingCategories = true;
    notifyListeners();
    _categories = await EbaraDataService.fetchCategories(
      idLanguage: _currentLanguageId,
    );
    _isLoadingCategories = false;
    if (_categories.isNotEmpty) {
      if (refreshProducts || _selectedCategoryId.isEmpty) {
        _selectedCategory = _categories.first.slug;
        _selectedCategoryId = _categories.first.id;
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
        idLanguage: _currentLanguageId,
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
    _selectedCategory = cat.slug;
    _selectedCategoryId = cat.id;
    loadProducts(_selectedCategoryId);
  }
}
