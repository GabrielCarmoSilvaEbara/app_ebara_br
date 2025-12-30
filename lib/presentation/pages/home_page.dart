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
import '../../core/providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/category_chip.dart';
import '../widgets/category_chip_skeleton.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/product_card_skeleton.dart';
import '../widgets/auth_modal_sheet.dart';
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
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
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

  void _showAuthModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AuthModalSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

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
                      onTap: () =>
                          themeProvider.toggleTheme(!themeProvider.isDarkMode),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          themeProvider.isDarkMode
                              ? Icons.nightlight_round
                              : Icons.wb_sunny,
                          color: AppColors.primary,
                          size: 22,
                        ),
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
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.translate('location'),
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                        Text(
                          locationProvider.city.isEmpty
                              ? l10n.translate('choose_location')
                              : locationProvider.city,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 20,
                          ),
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
                          hasError: homeProvider.hasError,
                          products: homeProvider.visibleProducts,
                          isPaginating: homeProvider.isPaginating,
                          selectedCategory: homeProvider.selectedCategory,
                          scrollController: _scrollController,
                          onRetry: () => homeProvider.loadProducts(
                            homeProvider.selectedCategoryId,
                          ),
                          onRefresh: () async {
                            await homeProvider.loadProducts(
                              homeProvider.selectedCategoryId,
                            );
                          },
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 8),
          child: Text(
            AppLocalizations.of(context)!.translate('select_category'),
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 20),
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
  final bool hasError;
  final List<ProductModel> products;
  final bool isPaginating;
  final String selectedCategory;
  final ScrollController scrollController;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;

  const _ProductGrid({
    required this.isLoading,
    required this.hasError,
    required this.products,
    required this.isPaginating,
    required this.selectedCategory,
    required this.scrollController,
    required this.onRetry,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (isLoading) return _ProductLoadingSkeleton();

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.translate('connect_error'),
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.translate('try_again')),
            ),
          ],
        ),
      );
    }

    if (products.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Text(
                l10n.translate('no_products_found'),
                style: theme.textTheme.labelMedium,
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: theme.cardColor,
      child: GridView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          childAspectRatio: 0.85,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: products.length + (isPaginating ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= products.length) {
            return const ProductCardSkeleton();
          }
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
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, index) => const ProductCardSkeleton(),
    );
  }
}
