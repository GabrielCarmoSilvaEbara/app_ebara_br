import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/ebara_data_service.dart';
import '../services/analytics_service.dart';
import '../models/product_model.dart';
import 'history_provider.dart';

class ProductDescKeys {
  static const String description = 'description';
  static const String specifications = 'specifications';
  static const String options = 'options';
  static const String apps = 'apps';
}

class ProductDetailsProvider with ChangeNotifier {
  final EbaraDataService _dataService;

  int _currentIndex = 0;
  int _comparisonBaseIndex = 0;
  bool _isLoading = true;

  Map<String, dynamic>? _descriptions;
  List<Map<String, dynamic>> _applications = [];
  List<Map<String, dynamic>> _files = [];

  final ExpansibleController featuresCtrl = ExpansibleController();
  final ExpansibleController specsCtrl = ExpansibleController();
  final ExpansibleController optionsCtrl = ExpansibleController();
  final ExpansibleController docsCtrl = ExpansibleController();

  ProductDetailsProvider({required EbaraDataService dataService})
    : _dataService = dataService;

  int get currentIndex => _currentIndex;
  int get comparisonBaseIndex => _comparisonBaseIndex;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get descriptions => _descriptions;
  List<Map<String, dynamic>> get applications => _applications;
  List<Map<String, dynamic>> get files => _files;

  Future<void> initProductView({
    required String productId,
    required int languageId,
    required ProductModel product,
    required String category,
    required HistoryProvider historyProvider,
  }) async {
    _currentIndex = 0;
    _comparisonBaseIndex = 0;
    _isLoading = true;
    _collapseAllSections();
    notifyListeners();

    historyProvider.addToHistory(product.toMap(), category);
    AnalyticsService.logViewProduct(product.productId, product.name, category);

    final results = await Future.wait([
      _dataService.getProductDescriptions(productId, idLanguage: languageId),
      _dataService.getProductApplications(productId, idLanguage: languageId),
      _dataService.getProductFiles(productId, idLanguage: languageId),
    ]);

    _descriptions = results[0] as Map<String, dynamic>?;
    _applications = results[1] as List<Map<String, dynamic>>;
    _files = results[2] as List<Map<String, dynamic>>;

    _isLoading = false;
    notifyListeners();
  }

  void updateIndex(int index) {
    _currentIndex = index;
    _collapseAllSections();
    notifyListeners();
  }

  void setComparisonBase(int index) {
    _comparisonBaseIndex = index;
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  Future<void> shareProduct(
    ProductModel product,
    String shareTextTemplate,
  ) async {
    final String name = product.name;
    final String model = product.model;
    final String link = product.ecommerceLink ?? 'https://ebara.com.br';

    final text = shareTextTemplate
        .replaceAll('{name}', name)
        .replaceAll('{model}', model);

    await SharePlus.instance.share(ShareParams(text: '$text $link'));
  }

  Future<void> launchEcommerce(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void handleSectionExpansion(ExpansibleController selected) {
    if (selected != featuresCtrl && featuresCtrl.isExpanded) {
      featuresCtrl.collapse();
    }
    if (selected != specsCtrl && specsCtrl.isExpanded) {
      specsCtrl.collapse();
    }
    if (selected != optionsCtrl && optionsCtrl.isExpanded) {
      optionsCtrl.collapse();
    }
    if (selected != docsCtrl && docsCtrl.isExpanded) {
      docsCtrl.collapse();
    }
  }

  void _collapseAllSections() {
    if (featuresCtrl.isExpanded) featuresCtrl.collapse();
    if (specsCtrl.isExpanded) specsCtrl.collapse();
    if (optionsCtrl.isExpanded) optionsCtrl.collapse();
    if (docsCtrl.isExpanded) docsCtrl.collapse();
  }
}
