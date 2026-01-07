import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'products_provider.dart';
import 'categories_provider.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_filter_params.dart';
import '../models/history_item_model.dart';
import '../../presentation/widgets/filters_bottom_sheet.dart';
import '../../core/extensions/context_extensions.dart';
import '../../presentation/pages/product_details_page.dart';
import '../../presentation/widgets/image_viewer.dart';

class HomeProvider with ChangeNotifier {
  final ProductsProvider _productsProvider;
  final CategoriesProvider _categoriesProvider;

  ItemScrollController _itemScrollController = ItemScrollController();
  ItemScrollController get itemScrollController => _itemScrollController;

  final PageController pageController = PageController();

  HomeProvider({
    required ProductsProvider productsProvider,
    required CategoriesProvider categoriesProvider,
  }) : _productsProvider = productsProvider,
       _categoriesProvider = categoriesProvider;

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
        application: result['application']?.toString() ?? 'TODOS',
        line: result['line']?.toString() ?? 'TODOS',
        flowRate: double.tryParse(result['flow_rate']?.toString() ?? '') ?? 0.0,
        flowRateMeasure: result['flow_rate_measure']?.toString() ?? 'm3/h',
        heightGauge:
            double.tryParse(result['height_gauge']?.toString() ?? '') ?? 0.0,
        heightGaugeMeasure: result['height_gauge_measure']?.toString() ?? 'm',
        frequency: int.tryParse(result['frequency']?.toString() ?? '') ?? 60,
        types: int.tryParse(result['types']?.toString() ?? '') ?? 0,
        wellDiameter: result['well_diameter']?.toString(),
        cableLength: result['cable_lenght']?.toString(),
        activation: result['activation']?.toString() ?? 'pressostato',
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(
          category: categoryName,
          variants: product.variants,
        ),
      ),
    );
  }

  void navigateToHistoryItem(BuildContext context, HistoryItemModel item) {
    final List<ProductModel> variants = item.variants
        .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailsPage(category: item.category, variants: variants),
      ),
    );
  }

  void openZoom(BuildContext context, String imageUrl, String heroTag) {
    if (imageUrl.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            ImageViewer(imageUrl: imageUrl, heroTag: heroTag),
      ),
    );
  }
}
