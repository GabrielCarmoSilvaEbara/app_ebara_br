import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/home_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/models/category_model.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/models/product_filter_params.dart';
import '../theme/app_colors.dart';
import '../widgets/category_chip.dart';
import '../widgets/category_chip_skeleton.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/product_card_skeleton.dart';
import '../widgets/auth_modal_sheet.dart';
import 'location_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  Timer? _debounce;

  @override
  void dispose() {
    _pageController.dispose();
    _debounce?.cancel();
    super.dispose();
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

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification &&
        notification.metrics.axis == Axis.vertical &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 500) {
      context.read<HomeProvider>().loadMore();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: Column(
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
                      child: Selector<ThemeProvider, bool>(
                        selector: (_, provider) => provider.isDarkMode,
                        builder: (context, isDarkMode, _) {
                          return Semantics(
                            label: context.l10n.translate('dark_mode'),
                            button: true,
                            child: GestureDetector(
                              onTap: () {
                                context.read<ThemeProvider>().toggleTheme(
                                  !isDarkMode,
                                );
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.theme.cardColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isDarkMode
                                      ? Icons.nightlight_round
                                      : Icons.wb_sunny,
                                  color: context.colors.primary,
                                  size: 22,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () => openLocationSelector(context),
                      child: Selector<LocationProvider, String>(
                        selector: (_, provider) => provider.city,
                        builder: (context, city, _) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: context.colors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.l10n.translate('location'),
                                    style: context.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                              Text(
                                city.isEmpty
                                    ? context.l10n.translate('choose_location')
                                    : city,
                                style: context.textTheme.displayLarge?.copyWith(
                                  fontSize: 20,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: Semantics(
                        label: context.l10n.translate('my_account'),
                        button: true,
                        child: GestureDetector(
                          onTap: () => _showAuthModal(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.colors.primary.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            child: Selector<AuthProvider, String?>(
                              selector: (_, provider) =>
                                  provider.user?.photoURL,
                              builder: (context, photoUrl, _) {
                                final authStatus = context
                                    .read<AuthProvider>()
                                    .status;
                                if (photoUrl != null) {
                                  return ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: photoUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Padding(
                                            padding: EdgeInsets.all(10.0),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          Icon(
                                            Icons.person,
                                            color: context.colors.primary,
                                          ),
                                    ),
                                  );
                                }
                                return Icon(
                                  Icons.person,
                                  color: authStatus == AuthStatus.authenticated
                                      ? context.colors.primary
                                      : Colors.grey,
                                );
                              },
                            ),
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
              child: Selector<HomeProvider, String>(
                selector: (_, provider) => provider.selectedCategoryId,
                builder: (context, selectedCategoryId, _) {
                  return CustomSearchBar(
                    hintText: context.l10n.translate('search'),
                    selectedCategoryId: selectedCategoryId,
                    onChanged: (val) {
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 600), () {
                        context.read<HomeProvider>().setSearchQuery(val);
                      });
                    },
                    onFiltersApplied: (filters) {
                      final params = ProductFilterParams(
                        categoryId: selectedCategoryId,
                        application:
                            filters['application']?.toString() ?? 'TODOS',
                        line: filters['line']?.toString() ?? 'TODOS',
                        flowRate:
                            double.tryParse(
                              filters['flow_rate']?.toString() ?? '',
                            ) ??
                            0.0,
                        flowRateMeasure:
                            filters['flow_rate_measure']?.toString() ?? 'm3/h',
                        heightGauge:
                            double.tryParse(
                              filters['height_gauge']?.toString() ?? '',
                            ) ??
                            0.0,
                        heightGaugeMeasure:
                            filters['height_gauge_measure']?.toString() ?? 'm',
                        frequency:
                            int.tryParse(
                              filters['frequency']?.toString() ?? '',
                            ) ??
                            60,
                        types:
                            int.tryParse(filters['types']?.toString() ?? '') ??
                            0,
                        wellDiameter: filters['well_diameter']?.toString(),
                        cableLength: filters['cable_lenght']?.toString(),
                        activation:
                            filters['activation']?.toString() ?? 'pressostato',
                        bombsQuantity: filters['bombs_quantity'] is int
                            ? filters['bombs_quantity'] as int
                            : int.tryParse(
                                    filters['bombs_quantity']?.toString() ?? '',
                                  ) ??
                                  1,
                      );
                      context.read<HomeProvider>().applyFilters(params);
                    },
                  );
                },
              ),
            ),
            Selector<HomeProvider, (bool, List<CategoryModel>, String)>(
              selector: (_, provider) {
                return (
                  provider.isLoadingCategories,
                  provider.categories,
                  provider.selectedCategory,
                );
              },
              builder: (context, data, _) {
                final isLoading = data.$1;
                final categories = data.$2;
                final selectedCategory = data.$3;

                return _CategorySection(
                  isLoading: isLoading,
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onCategorySelected: (cat) {
                    final index = categories.indexOf(cat);
                    _scrollToCategory(index);
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  itemScrollController: _itemScrollController,
                );
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Selector<HomeProvider, (bool, List<CategoryModel>)>(
                selector: (_, provider) =>
                    (provider.isLoadingCategories, provider.categories),
                builder: (context, data, _) {
                  final isLoadingCategories = data.$1;
                  final categories = data.$2;

                  if (isLoadingCategories) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _ProductLoadingSkeleton(),
                    );
                  }

                  return PageView.builder(
                    controller: _pageController,
                    itemCount: categories.length,
                    onPageChanged: (index) {
                      context.read<HomeProvider>().updateCategoryByIndex(index);
                      _scrollToCategory(index);
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Consumer<HomeProvider>(
                          builder: (context, homeProvider, _) {
                            return _ProductGrid(
                              key: PageStorageKey<String>(
                                homeProvider.selectedCategoryId,
                              ),
                              isLoading: homeProvider.isLoadingProducts,
                              hasError: homeProvider.hasError,
                              products: homeProvider.visibleProducts,
                              isPaginating: homeProvider.isPaginating,
                              selectedCategory: homeProvider.selectedCategory,
                              onRetry: () => homeProvider.loadProducts(
                                homeProvider.selectedCategoryId,
                              ),
                              onRefresh: () async {
                                await homeProvider.loadProducts(
                                  homeProvider.selectedCategoryId,
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
            context.l10n.translate('select_category'),
            style: context.textTheme.displayLarge?.copyWith(fontSize: 20),
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

class _ProductGrid extends StatefulWidget {
  final bool isLoading;
  final bool hasError;
  final List<ProductModel> products;
  final bool isPaginating;
  final String selectedCategory;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;

  const _ProductGrid({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.products,
    required this.isPaginating,
    required this.selectedCategory,
    required this.onRetry,
    required this.onRefresh,
  });

  @override
  State<_ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<_ProductGrid>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.isLoading) {
      return _ProductLoadingSkeleton();
    }

    if (widget.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              context.l10n.translate('connect_error'),
              style: context.textTheme.labelMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(context.l10n.translate('try_again')),
            ),
          ],
        ),
      );
    }

    if (widget.products.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: context.height * 0.6,
            child: Center(
              child: Text(
                context.l10n.translate('no_products_found'),
                style: context.textTheme.labelMedium,
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.primary,
      backgroundColor: context.theme.cardColor,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        cacheExtent: 500,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          childAspectRatio: 0.85,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: widget.products.length + (widget.isPaginating ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= widget.products.length) {
            return const ProductCardSkeleton();
          }

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index % 10) * 50),
            curve: Curves.easeOutQuart,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: RepaintBoundary(
              child: ProductCard(
                category: context.l10n.translate(widget.selectedCategory),
                product: widget.products[index],
                onActionPressed: () {},
              ),
            ),
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
