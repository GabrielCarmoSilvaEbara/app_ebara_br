import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/home_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/product_model.dart';
import '../../core/models/category_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/history_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/category_chip.dart';
import '../widgets/category_chip_skeleton.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/product_card_skeleton.dart';
import '../widgets/auth_modal_sheet.dart';
import 'product_details_page.dart';
import 'location_page.dart';

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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationPage()),
    );
  }

  void _scrollToCategory(int index) {
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.38,
      );
    }
  }

  void _showHistoryModal(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.status != AuthStatus.authenticated) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => const AuthModalSheet(),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _HistoryModalSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
            child: SizedBox(
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 0,
                    child: GestureDetector(
                      onTap: () => _showHistoryModal(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                        child: Icon(Icons.history, color: AppColors.primary),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => openLocationSelector(context),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.translate('location'),
                              style: AppTextStyles.text4,
                            ),
                          ],
                        ),
                        Text(
                          locationProvider.city.isEmpty
                              ? l10n.translate('choose_location')
                              : locationProvider.city,
                          style: AppTextStyles.text,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showAuthModal(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                        child: authProvider.user?.photoURL != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: authProvider.user!.photoURL!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.person,
                                color:
                                    authProvider.status ==
                                        AuthStatus.authenticated
                                    ? AppColors.primary
                                    : Colors.grey,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: CustomSearchBar(
              hintText: l10n.translate('search'),
              selectedCategoryId: homeProvider.selectedCategoryId,
              onChanged: (val) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  homeProvider.setSearchQuery(val);
                });
              },
              onFiltersApplied: (filters) {
                homeProvider.applyFilters(filters);
              },
            ),
          ),
          _CategorySection(
            isLoading: homeProvider.isLoadingCategories,
            categories: homeProvider.categories,
            selectedCategory: homeProvider.selectedCategory,
            onCategorySelected: (cat) {
              final index = homeProvider.categories.indexOf(cat);
              _scrollToCategory(index);
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
            child: homeProvider.isLoadingCategories
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ProductLoadingSkeleton(),
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: homeProvider.categories.length,
                    onPageChanged: (index) {
                      homeProvider.updateCategoryByIndex(index);
                      _scrollToCategory(index);
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _ProductGrid(
                          isLoading: homeProvider.isLoadingProducts,
                          products: homeProvider.visibleProducts,
                          isPaginating: homeProvider.isPaginating,
                          selectedCategory: homeProvider.selectedCategory,
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

  void _showAuthModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const AuthModalSheet(),
    );
  }
}

class _HistoryModalSheet extends StatelessWidget {
  const _HistoryModalSheet();

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final l10n = AppLocalizations.of(context)!;
    final list = historyProvider.history;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('recent_products'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (list.isNotEmpty)
                TextButton(
                  onPressed: () => historyProvider.clearHistory(),
                  child: Text(
                    l10n.translate('clear'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  l10n.translate('no_recent_products'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                itemCount: list.length,
                padding: const EdgeInsets.only(bottom: 20),
                separatorBuilder: (context, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = list[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: item['image'] != null && item['image'].isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item['image'],
                              fit: BoxFit.contain,
                              errorWidget: (c, e, s) =>
                                  const Icon(Icons.image_not_supported),
                            )
                          : const Icon(Icons.image),
                    ),
                    title: Text(
                      item['name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      item['model'] ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      final category = item['history_category'] ?? '';
                      final rawVariants = item['variants'] as List;
                      final variants = rawVariants
                          .map((e) => Map<String, dynamic>.from(e))
                          .toList();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsPage(
                            category: category,
                            variants: variants,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final bool isLoading;
  final List<CategoryModel> categories;
  final String selectedCategory;
  final ValueChanged<CategoryModel> onCategorySelected;
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
            AppLocalizations.of(context)!.translate('select_category'),
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
                      label: category.title,
                      icon: category.icon ?? Icons.category,
                      isSelected: category.slug == selectedCategory,
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
  final List<ProductModel> products;
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
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) return _ProductLoadingSkeleton();
    if (products.isEmpty) {
      return Center(
        child: Text(
          l10n.translate('no_products_found'),
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
            category: l10n.translate(selectedCategory),
            product: products[index],
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
