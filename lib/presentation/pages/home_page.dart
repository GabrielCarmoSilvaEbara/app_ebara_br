import 'dart:async';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import '../widgets/product_card_skeleton.dart';
import '../../core/services/location_service.dart';
import '../../core/services/translation_service.dart';
import '../../core/services/ebara_data_service.dart';
import '../widgets/location_selector_sheet.dart';
import '../widgets/category_chip_skeleton.dart';

class NoScrollbarScrollBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(context, child, details) => child;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  static const int _pageSize = 10;
  static const int _scrollThreshold = 200;
  static const Duration _debounceDelay = Duration(milliseconds: 400);
  static const Duration _paginationDelay = Duration(milliseconds: 400);

  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  Timer? _debounce;

  bool isLoadingCategories = true;
  bool isLoadingProducts = true;
  bool isPaginating = false;

  String city = '';
  String state = '';
  String country = '';

  String selectedCategory = '';
  String selectedCategoryId = '';
  String searchQuery = '';

  int currentPage = 1;
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> visibleProducts = [];

  final Map<String, List<Map<String, dynamic>>> _cacheByCategory = {};

  @override
  void initState() {
    super.initState();
    _initializeHomePage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredAllProducts {
    if (searchQuery.isEmpty) return allProducts;
    final query = searchQuery.toLowerCase();
    return allProducts
        .where((product) => _matchesSearchQuery(product, query))
        .toList();
  }

  bool get hasMoreProducts =>
      visibleProducts.length < filteredAllProducts.length;
  bool get canPaginate => !isPaginating && hasMoreProducts;

  void _initializeHomePage() {
    city = TranslationService.translate('search');
    _scrollController.addListener(_onScroll);
    initLocation();
  }

  Future<void> initLocation() async {
    final location = await LocationService.getCurrentCity();
    if (!mounted) return;
    _updateLocationState(location);
    await loadCategories();
  }

  void _updateLocationState(Map<String, String>? location) {
    if (location == null) {
      setState(() => city = TranslationService.translate('choose_location'));
      return;
    }
    final cityValue = location['city'];
    if (cityValue == null || cityValue.isEmpty) {
      setState(() => city = TranslationService.translate('choose_location'));
      return;
    }
    final countryCode = location['country'];
    if (countryCode != null) {
      TranslationService.setLanguageByCountry(countryCode);
    }
    setState(() {
      city = cityValue;
      country = countryCode ?? '';
      state = location['state'] ?? '';
    });
  }

  Future<void> loadCategories({bool refreshProducts = true}) async {
    setState(() => isLoadingCategories = true);

    final fetchedCategories = await EbaraDataService.fetchCategories(
      idLanguage: TranslationService.getLanguageId(),
    );

    if (!mounted) return;

    setState(() {
      categories = fetchedCategories;
      isLoadingCategories = false;
    });

    if (categories.isNotEmpty) {
      if (refreshProducts) {
        _selectFirstCategory();
      } else {
        final current = categories.firstWhere(
          (cat) => cat['id'].toString() == selectedCategoryId.toString(),
          orElse: () => categories.first,
        );
        setState(() {
          selectedCategory = current['slug'] ?? '';
        });
      }
    }
  }

  void _selectFirstCategory() {
    final firstCategory = categories.first;
    selectedCategory = firstCategory['slug'] ?? '';
    selectedCategoryId = firstCategory['id'] ?? '';
    loadProducts(selectedCategoryId);
  }

  Future<void> loadProducts(String categoryId) async {
    if (categoryId.isEmpty) return;
    _resetProductState();
    final products = await _getProductsForCategory(categoryId);
    if (!mounted) return;
    setState(() {
      allProducts = products;
      searchQuery = '';
      visibleProducts = products.take(_pageSize).toList();
      isLoadingProducts = false;
    });
  }

  Future<void> _performTechnicalSearch(Map<String, dynamic> filters) async {
    _resetProductState();

    final products = await EbaraDataService.searchProducts(
      categoryId: selectedCategoryId,
      application: filters['application'] ?? 'TODOS',
      line: filters['line'] ?? 'TODOS',
      frequency: int.tryParse(filters['frequency'].toString()) ?? 60,
      flowRate: double.tryParse(filters['flow_rate'].toString()) ?? 0,
      flowRateMeasure: filters['flow_rate_measure'] ?? 'm3/h',
      heightGauge: double.tryParse(filters['height_gauge'].toString()) ?? 0,
      heightGaugeMeasure: filters['height_gauge_measure'] ?? 'm',
      idLanguage: TranslationService.getLanguageId(),
    );

    if (!mounted) return;

    setState(() {
      allProducts = EbaraDataService.groupProducts(products);
      searchQuery = '';
      visibleProducts = allProducts.take(_pageSize).toList();
      isLoadingProducts = false;
    });
  }

  Future<List<Map<String, dynamic>>> _getProductsForCategory(
    String categoryId,
  ) async {
    if (_cacheByCategory.containsKey(categoryId)) {
      return _cacheByCategory[categoryId]!;
    }
    final fetchedProducts = await EbaraDataService.searchProducts(
      categoryId: categoryId,
      idLanguage: TranslationService.getLanguageId(),
    );
    final groupedProducts = EbaraDataService.groupProducts(fetchedProducts);
    _cacheByCategory[categoryId] = groupedProducts;
    return groupedProducts;
  }

  void _resetProductState() {
    setState(() {
      isLoadingProducts = true;
      isPaginating = false;
      currentPage = 1;
      visibleProducts.clear();
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _onScroll() {
    final isNearBottom =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - _scrollThreshold;
    if (isNearBottom && canPaginate) {
      _loadMore();
    }
  }

  void _loadMore() {
    setState(() => isPaginating = true);
    Future.delayed(_paginationDelay, () {
      if (!mounted) return;
      final nextProducts = _getNextPageProducts();
      setState(() {
        visibleProducts.addAll(nextProducts);
        currentPage++;
        isPaginating = false;
      });
    });
  }

  List<Map<String, dynamic>> _getNextPageProducts() {
    return filteredAllProducts
        .skip(currentPage * _pageSize)
        .take(_pageSize)
        .toList();
  }

  bool _matchesSearchQuery(Map<String, dynamic> product, String query) {
    final name = (product['name'] ?? '').toString().toLowerCase();
    final model = (product['model'] ?? '').toString().toLowerCase();
    return name.contains(query) || model.contains(query);
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () => _performSearch(value));
  }

  void _performSearch(String query) {
    if (!mounted) return;
    setState(() {
      searchQuery = query;
      currentPage = 1;
      visibleProducts = filteredAllProducts.take(_pageSize).toList();
    });
  }

  void openLocationSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          LocationSelectorSheet(onSelected: _onLocationSelected),
    );
  }

  void _onLocationSelected(
    String newCity,
    String newState,
    String newCountry,
  ) async {
    TranslationService.setLanguageByCountry(newCountry);

    EbaraDataService.clearCategoryCache();

    setState(() {
      city = newCity;
      state = newState;
      country = newCountry;
    });

    await loadCategories(refreshProducts: false);
  }

  void _onCategorySelected(Map<String, dynamic> category) {
    final index = categories.indexOf(category);
    if (index != -1) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    final category = categories[index];
    setState(() {
      selectedCategory = category['slug'] ?? '';
      selectedCategoryId = category['id'] ?? '';
    });

    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.4,
      );
    }

    loadProducts(selectedCategoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LocationHeader(city: city, onTap: openLocationSelector),
          _SearchSection(
            onSearchChanged: onSearchChanged,
            selectedCategoryId: selectedCategoryId,
            onFiltersApplied: _performTechnicalSearch,
          ),
          _CategorySection(
            isLoading: isLoadingCategories,
            categories: categories,
            selectedCategory: selectedCategory,
            onCategorySelected: _onCategorySelected,
            itemScrollController: _itemScrollController,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isLoadingCategories
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ProductLoadingSkeleton(),
                  )
                : PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double value = 1.0;
                          if (_pageController.position.haveDimensions) {
                            value = _pageController.page! - index;
                            value = (1 - (value.abs() * 0.05)).clamp(0.0, 1.0);
                          }
                          return Opacity(
                            opacity: value,
                            child: Transform.scale(scale: value, child: child),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _ProductGrid(
                            isLoading: isLoadingProducts,
                            products: visibleProducts,
                            isPaginating: isPaginating,
                            selectedCategory: selectedCategory,
                            scrollController: _scrollController,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LocationHeader extends StatelessWidget {
  final String city;
  final VoidCallback onTap;
  const _LocationHeader({required this.city, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on,
                size: 24,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationService.translate('location'),
                    style: AppTextStyles.text4,
                  ),
                  Text(city, style: AppTextStyles.text),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchSection extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final String selectedCategoryId;
  final Function(Map<String, dynamic>) onFiltersApplied;

  const _SearchSection({
    required this.onSearchChanged,
    required this.selectedCategoryId,
    required this.onFiltersApplied,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: CustomSearchBar(
        hintText: TranslationService.translate('search'),
        onChanged: onSearchChanged,
        selectedCategoryId: selectedCategoryId,
        onFiltersApplied: onFiltersApplied,
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> categories;
  final String selectedCategory;
  final ValueChanged<Map<String, dynamic>> onCategorySelected;
  final ItemScrollController itemScrollController;
  const _CategorySection({
    required this.isLoading,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.itemScrollController,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 8),
          child: Text(
            TranslationService.translate('select_category'),
            style: AppTextStyles.text,
          ),
        ),
        SizedBox(
          height: 44,
          child: isLoading
              ? _CategoryLoadingSkeleton()
              : _CategoryList(
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onCategorySelected: onCategorySelected,
                  itemScrollController: itemScrollController,
                ),
        ),
      ],
    );
  }
}

class _CategoryLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 6,
      itemBuilder: (_, index) => const CategoryChipSkeleton(),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String selectedCategory;
  final ValueChanged<Map<String, dynamic>> onCategorySelected;
  final ItemScrollController itemScrollController;
  const _CategoryList({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.itemScrollController,
  });
  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      itemScrollController: itemScrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final slug = category['slug'] ?? '';
        final isSelected = slug == selectedCategory;
        return CategoryChip(
          label: category['title'] ?? '',
          icon: category['icon'],
          isSelected: isSelected,
          onTap: () => onCategorySelected(category),
        );
      },
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> products;
  final bool isPaginating;
  final String selectedCategory;
  final ScrollController scrollController;
  const _ProductGrid({
    required this.isLoading,
    required this.products,
    required this.isPaginating,
    required this.selectedCategory,
    required this.scrollController,
  });
  @override
  Widget build(BuildContext context) {
    if (isLoading) return _ProductLoadingSkeleton();
    if (products.isEmpty) return _EmptyProductsView();
    return ScrollConfiguration(
      behavior: NoScrollbarScrollBehavior(),
      child: GridView.builder(
        controller: scrollController,
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.99,
        ),
        itemCount: products.length + (isPaginating ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= products.length) return const ProductCardSkeleton();
          final product = products[index];
          return ProductCard(
            category: TranslationService.translate(selectedCategory),
            productData: product,
            onActionPressed: () {},
          );
        },
      ),
    );
  }
}

class _ProductLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: 6,
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.99,
      ),
      itemBuilder: (_, index) => const ProductCardSkeleton(),
    );
  }
}

class _EmptyProductsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        TranslationService.translate('no_products_found'),
        style: AppTextStyles.text4,
      ),
    );
  }
}
