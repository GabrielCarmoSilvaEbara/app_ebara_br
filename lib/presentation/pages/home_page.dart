import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../core/providers/home_provider.dart';
import '../../core/services/translation_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/category_chip.dart';
import '../widgets/category_chip_skeleton.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/location_selector_sheet.dart';
import '../widgets/product_card.dart';
import '../widgets/product_card_skeleton.dart';

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
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().initialize();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<HomeProvider>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      provider.loadMore();
    }
  }

  void openLocationSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationSelectorSheet(
        onSelected: (city, state, country) async {
          context.read<HomeProvider>().updateManualLocation(
            city,
            state,
            country,
          );
          if (mounted) setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LocationHeader(
            city: provider.city,
            onTap: () => openLocationSelector(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: CustomSearchBar(
              hintText: TranslationService.translate('search'),
              selectedCategoryId: provider.selectedCategoryId,
              onChanged: (val) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  provider.setSearchQuery(val);
                });
              },
              onFiltersApplied: (filters) {},
            ),
          ),
          _CategorySection(
            isLoading: provider.isLoadingCategories,
            categories: provider.categories,
            selectedCategory: provider.selectedCategory,
            onCategorySelected: (cat) {
              final index = provider.categories.indexOf(cat);
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
            itemScrollController: _itemScrollController,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: provider.isLoadingCategories
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ProductLoadingSkeleton(),
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: provider.categories.length,
                    onPageChanged: (index) {
                      provider.updateCategoryByIndex(index);
                      if (_itemScrollController.isAttached) {
                        _itemScrollController.scrollTo(
                          index: index,
                          duration: const Duration(milliseconds: 300),
                          alignment: 0.4,
                        );
                      }
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _ProductGrid(
                          isLoading: provider.isLoadingProducts,
                          products: provider.visibleProducts,
                          isPaginating: provider.isPaginating,
                          selectedCategory: provider.selectedCategory,
                          scrollController: _scrollController,
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
              : ScrollablePositionedList.builder(
                  itemScrollController: itemScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return CategoryChip(
                      label: category['title'] ?? '',
                      icon: category['icon'],
                      isSelected: category['slug'] == selectedCategory,
                      onTap: () => onCategorySelected(category),
                    );
                  },
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
    if (products.isEmpty) {
      return Center(
        child: Text(
          TranslationService.translate('no_products_found'),
          style: AppTextStyles.text4,
        ),
      );
    }
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
          return ProductCard(
            category: TranslationService.translate(selectedCategory),
            productData: products[index],
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
