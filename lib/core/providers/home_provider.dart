import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'products_provider.dart';
import 'categories_provider.dart';
import '../services/ebara_data_service.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_filter_params.dart';
import '../models/history_item_model.dart';
import '../../presentation/widgets/filters_bottom_sheet.dart';
import '../../core/extensions/context_extensions.dart';
import '../constants/app_constants.dart';

class HomeProvider with ChangeNotifier {
  final ProductsProvider _productsProvider;
  final CategoriesProvider _categoriesProvider;
  final EbaraDataService _dataService;

  ItemScrollController _itemScrollController = ItemScrollController();
  ItemScrollController get itemScrollController => _itemScrollController;

  final PageController pageController = PageController();

  HomeProvider({
    required ProductsProvider productsProvider,
    required CategoriesProvider categoriesProvider,
    required EbaraDataService dataService,
  }) : _productsProvider = productsProvider,
       _categoriesProvider = categoriesProvider,
       _dataService = dataService;

  bool get isLoading => _productsProvider.isLoading;
  List<ProductModel> get visibleProducts => _productsProvider.visibleProducts;
  List<CategoryModel> get categories => _categoriesProvider.categories;
  String get selectedCategoryId => _categoriesProvider.selectedCategoryId;
  String get selectedCategorySlug => _categoriesProvider.selectedCategorySlug;

  void resetController() {
    _itemScrollController = ItemScrollController();
  }

  Future<void> reloadData(int languageId) async {
    await _categoriesProvider.loadCategories(languageId);
    if (_categoriesProvider.selectedCategoryId.isNotEmpty) {
      _productsProvider.loadProducts(
        _categoriesProvider.selectedCategoryId,
        languageId,
      );
    }
  }

  void reloadCurrentCategory(int languageId) {
    if (_categoriesProvider.selectedCategoryId.isNotEmpty) {
      _productsProvider.loadProducts(
        _categoriesProvider.selectedCategoryId,
        languageId,
      );
    }
  }

  void onCategorySelected(CategoryModel cat, int index, int languageId) {
    _categoriesProvider.selectCategory(cat);
    _scrollToCategory(index);

    if (pageController.hasClients && pageController.page?.round() != index) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }

    _productsProvider.loadProducts(cat.id, languageId);
  }

  void onPageChanged(int index, int languageId) {
    if (index >= 0 && index < categories.length) {
      final cat = categories[index];
      onCategorySelected(cat, index, languageId);
    }
  }

  void _scrollToCategory(int index) {
    if (itemScrollController.isAttached) {
      itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.38,
      );
    }
  }

  Future<void> openFilters(BuildContext context, int languageId) async {
    final result = await context.showAppBottomSheet<Map<String, dynamic>>(
      child: FiltersBottomSheet(categoryId: selectedCategoryId),
    );

    if (result != null) {
      final params = ProductFilterParams(
        categoryId: selectedCategoryId,
        idLanguage: languageId,
        application: result['application']?.toString() ?? SystemConstants.all,
        line: result['line']?.toString() ?? SystemConstants.all,
        flowRate: double.tryParse(result['flow_rate']?.toString() ?? '') ?? 0.0,
        flowRateMeasure:
            result['flow_rate_measure']?.toString() ??
            SystemConstants.defaultFlowMeasure,
        heightGauge:
            double.tryParse(result['height_gauge']?.toString() ?? '') ?? 0.0,
        heightGaugeMeasure:
            result['height_gauge_measure']?.toString() ??
            SystemConstants.defaultHeadMeasure,
        frequency:
            int.tryParse(result['frequency']?.toString() ?? '') ??
            SystemConstants.defaultFrequency,
        types: int.tryParse(result['types']?.toString() ?? '') ?? 0,
        wellDiameter: result['well_diameter']?.toString(),
        cableLength: result['cable_lenght']?.toString(),
        activation:
            result['activation']?.toString() ?? SystemConstants.pressostat,
        bombsQuantity:
            int.tryParse(result['bombs_quantity']?.toString() ?? '') ?? 1,
      );

      _productsProvider.loadProducts(
        selectedCategoryId,
        languageId,
        filters: params,
      );
    }
  }

  void navigateToProduct(
    BuildContext context,
    ProductModel product,
    String categoryName,
  ) {
    if (product.variants.isEmpty) return;
    context.pushNamed(
      'product_details',
      extra: {'category': categoryName, 'variants': product.variants},
    );
  }

  void navigateToHistoryItem(BuildContext context, HistoryItemModel item) {
    final List<ProductModel> variants = item.variants
        .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    context.pushNamed(
      'product_details',
      extra: {'category': item.category, 'variants': variants},
    );
  }

  void openZoom(BuildContext context, String imageUrl, String heroTag) {
    if (imageUrl.isEmpty) return;
    context.pushNamed(
      'image_viewer',
      extra: {'imageUrl': imageUrl, 'heroTag': heroTag},
    );
  }

  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final serverVersionStr = await _dataService.getAppVersionInfo();
      if (serverVersionStr == null) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isVersionNewer(serverVersionStr, currentVersion)) {
        if (context.mounted) {
          _showUpdateDialog(context);
        }
      }
    } catch (_) {}
  }

  bool _isVersionNewer(String serverVersion, String currentVersion) {
    List<int> serverParts = serverVersion.split('.').map(int.parse).toList();
    List<int> currentParts = currentVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < serverParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (serverParts[i] > currentParts[i]) return true;
      if (serverParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.translate('update_available')),
        content: Text(context.l10n.translate('update_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.translate('later')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _launchStore();
            },
            child: Text(context.l10n.translate('update_now')),
          ),
        ],
      ),
    );
  }

  void _launchStore() async {
    const url = 'https://play.google.com/store/apps/details?id=com.ebara.app';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
