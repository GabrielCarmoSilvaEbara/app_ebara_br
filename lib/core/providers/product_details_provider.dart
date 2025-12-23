import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ebara_data_service.dart';

class ProductDetailsProvider with ChangeNotifier {
  int _currentIndex = 0;
  int _comparisonBaseIndex = 0;
  bool _isLoading = true;

  Map<String, dynamic>? _descriptions;
  List<Map<String, dynamic>> _applications = [];
  List<Map<String, dynamic>> _files = [];

  int get currentIndex => _currentIndex;
  int get comparisonBaseIndex => _comparisonBaseIndex;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get descriptions => _descriptions;
  List<Map<String, dynamic>> get applications => _applications;
  List<Map<String, dynamic>> get files => _files;

  Future<void> loadProductData(String productId, int languageId) async {
    _currentIndex = 0;
    _comparisonBaseIndex = 0;
    _isLoading = true;
    notifyListeners();

    final results = await Future.wait([
      EbaraDataService.getProductDescriptions(
        productId,
        idLanguage: languageId,
      ),
      EbaraDataService.getProductApplications(
        productId,
        idLanguage: languageId,
      ),
      EbaraDataService.getProductFiles(productId, idLanguage: languageId),
    ]);

    _descriptions = results[0] as Map<String, dynamic>?;
    _applications = results[1] as List<Map<String, dynamic>>;
    _files = results[2] as List<Map<String, dynamic>>;

    _isLoading = false;
    notifyListeners();
  }

  void updateIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void setComparisonBase(int index) {
    _comparisonBaseIndex = index;
    HapticFeedback.mediumImpact();
    notifyListeners();
  }
}
