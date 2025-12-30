import 'dart:async';
import 'package:flutter/material.dart';
import '../services/ebara_data_service.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/analytics_service.dart';

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
  List<ProductModel> _filteredProducts = [];
  List<ProductModel> _visibleProducts = [];

  final Map<String, List<ProductModel>> _cacheByCategory = {};
  Map<String, dynamic>? _activeFilters;

  double _sunExposure = 5.0;
  bool _hasError = false;

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

    _categories = await EbaraDataService.fetchCategories(
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
    Map<String, dynamic>? filters,
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
        flowRate: double.tryParse(filters['flow_rate'].toString()) ?? 0,
        head: double.tryParse(filters['height_gauge'].toString()) ?? 0,
        application: filters['application']?.toString() ?? 'TODOS',
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
        final searchParams = _prepareSearchParams(categoryId, _activeFilters);

        final fetched = await EbaraDataService.searchProducts(
          categoryId: categoryId,
          idLanguage: _currentLanguageId,
          application: searchParams['application'],
          line: searchParams['line'],
          flowRate: searchParams['flowRate'],
          flowRateMeasure: searchParams['flowRateMeasure'],
          heightGauge: searchParams['heightGauge'],
          heightGaugeMeasure: searchParams['heightGaugeMeasure'],
          frequency: searchParams['frequency'],
          types: searchParams['types'],
          wellDiameter: searchParams['wellDiameter'],
          cableLength: searchParams['cableLength'],
          activation: searchParams['activation'],
          bombsQuantity: searchParams['bombsQuantity'],
          sunExposure: searchParams['sunExposure'] ?? _sunExposure,
        );

        _allProducts = EbaraDataService.groupProducts(fetched);

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

    _updateFilteredProducts();
    _visibleProducts = _filteredProducts.take(_pageSize).toList();
    _isLoadingProducts = false;
    notifyListeners();
  }

  void _updateFilteredProducts() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_allProducts);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredProducts = _allProducts.where((product) {
        final name = product.name.toLowerCase();
        final model = product.model.toLowerCase();
        return name.contains(query) || model.contains(query);
      }).toList();
    }
  }

  Map<String, dynamic> _prepareSearchParams(
    String categoryId,
    Map<String, dynamic>? filters,
  ) {
    final params = <String, dynamic>{
      'application': 'TODOS',
      'line': 'TODOS',
      'flowRate': 0.0,
      'flowRateMeasure': 'm3/h',
      'heightGauge': 0.0,
      'heightGaugeMeasure': 'm',
      'frequency': 60,
      'types': 0,
      'wellDiameter': null,
      'cableLength': null,
      'activation': 'pressostato',
      'bombsQuantity': 1,
      'sunExposure': _sunExposure,
    };

    if (filters == null) {
      return params;
    }

    if (filters['application'] != null) {
      params['application'] = filters['application'];
    }

    if (filters['line'] != null) {
      params['line'] = filters['line'];
    }

    if (filters['flow_rate'] != null) {
      params['flowRate'] =
          double.tryParse(filters['flow_rate'].toString()) ?? 0.0;
    }
    if (filters['flow_rate_measure'] != null) {
      params['flowRateMeasure'] = filters['flow_rate_measure'];
    }

    if (filters['height_gauge'] != null) {
      params['heightGauge'] =
          double.tryParse(filters['height_gauge'].toString()) ?? 0.0;
    }
    if (filters['height_gauge_measure'] != null) {
      params['heightGaugeMeasure'] = filters['height_gauge_measure'];
    }

    if (filters['frequency'] != null) {
      final freqStr = filters['frequency'].toString().replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      params['frequency'] = int.tryParse(freqStr) ?? 60;
    }

    if (filters['types'] != null) {
      params['types'] = int.tryParse(filters['types'].toString()) ?? 0;
    }

    if (filters['well_diameter'] != null) {
      params['wellDiameter'] = filters['well_diameter'];
    }

    if (filters['cable_lenght'] != null) {
      params['cableLength'] = filters['cable_lenght'];
    }

    if (filters['activation'] != null) {
      params['activation'] = filters['activation'];
    }
    if (filters['bombs_quantity'] != null) {
      params['bombsQuantity'] = filters['bombs_quantity'];
    }
    return params;
  }

  void applyFilters(Map<String, dynamic> filters) {
    loadProducts(_selectedCategoryId, filters: filters);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    _updateFilteredProducts();
    _visibleProducts = _filteredProducts.take(_pageSize).toList();
    notifyListeners();
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

  void updateCategoryByIndex(int index) {
    if (index < 0 || index >= _categories.length) return;
    final cat = _categories[index];
    _activeFilters = null;
    _selectedCategory = cat.slug;
    _selectedCategoryId = cat.id;
    loadProducts(_selectedCategoryId);
  }
}
