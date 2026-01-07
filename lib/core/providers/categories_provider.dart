import 'package:flutter/material.dart';
import '../repositories/product_repository.dart';
import '../models/category_model.dart';

class CategoriesProvider with ChangeNotifier {
  final ProductRepository _repository;

  bool _isLoading = true;
  List<CategoryModel> _categories = [];
  String _selectedCategorySlug = '';
  String _selectedCategoryId = '';

  CategoriesProvider({required ProductRepository repository})
    : _repository = repository;

  bool get isLoading => _isLoading;
  List<CategoryModel> get categories => _categories;
  String get selectedCategorySlug => _selectedCategorySlug;
  String get selectedCategoryId => _selectedCategoryId;

  Future<void> loadCategories(int languageId) async {
    _isLoading = true;
    notifyListeners();

    _categories = await _repository.fetchCategories(idLanguage: languageId);

    if (_categories.isNotEmpty) {
      if (_selectedCategoryId.isEmpty) {
        selectCategory(_categories.first);
      } else {
        final current = _categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
          orElse: () => _categories.first,
        );
        selectCategory(current);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectCategory(CategoryModel category) {
    _selectedCategoryId = category.id;
    _selectedCategorySlug = category.slug;
    notifyListeners();
  }

  void selectCategoryById(String id) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      selectCategory(_categories[index]);
    }
  }
}
