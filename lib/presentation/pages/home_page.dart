import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../core/providers/home_provider.dart';
import '../../core/providers/products_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../theme/app_dimens.dart';
import '../widgets/category_chip.dart';
import '../widgets/app_skeletons.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/app_status_widgets.dart';
import '../widgets/home_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeProvider>().resetController();
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.read<HomeProvider>();
    final productsProvider = context.read<ProductsProvider>();
    final locProvider = context.read<LocationProvider>();

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollEndNotification && n.metrics.axis == Axis.vertical) {
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 500) {
              if (!productsProvider.isLoading &&
                  productsProvider.hasMoreProducts) {
                productsProvider.loadMore();
              }
              return true;
            }
          }
          return false;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeAppBar(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.lg,
                vertical: AppDimens.sm,
              ),
              child: AppSearchBar(
                hintText: context.l10n.translate('search'),
                debounceDuration: AppDimens.durationSlow,
                onChanged: (val) => productsProvider.onSearchInputChanged(val),
                onFilterTap: () => homeProvider.openFilters(
                  context,
                  locProvider.apiLanguageId,
                ),
              ),
            ),
            const _CategoriesSection(),
            const SizedBox(height: AppDimens.xs),
            Expanded(child: const _ProductPageView()),
          ],
        ),
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection();

  @override
  Widget build(BuildContext context) {
    return Selector<CategoriesProvider, (bool, int)>(
      selector: (_, p) => (p.isLoading, p.categories.length),
      builder: (context, data, _) {
        final isLoading = data.$1;
        final count = data.$2;
        final provider = context.read<CategoriesProvider>();
        final homeProvider = context.read<HomeProvider>();
        final locProvider = context.read<LocationProvider>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppDimens.lg,
                bottom: AppDimens.xs,
              ),
              child: Text(
                context.l10n.translate('select_category'),
                style: context.titleStyle,
              ),
            ),
            SizedBox(
              height: AppDimens.chipHeight,
              child: isLoading
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.lg,
                      ),
                      itemCount: 6,
                      itemBuilder: (_, _) => const CategoryChipSkeleton(),
                    )
                  : ScrollablePositionedList.builder(
                      itemScrollController: homeProvider.itemScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.lg,
                      ),
                      itemCount: count,
                      itemBuilder: (context, index) {
                        final category = provider.categories[index];
                        return Selector<CategoriesProvider, String>(
                          selector: (_, p) => p.selectedCategoryId,
                          builder: (_, selectedId, _) {
                            return CategoryChip(
                              label: category.title,
                              icon: category.icon ?? Icons.category,
                              isSelected: category.id == selectedId,
                              onTap: () => homeProvider.onCategorySelected(
                                category,
                                index,
                                locProvider.apiLanguageId,
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ProductPageView extends StatelessWidget {
  const _ProductPageView();

  @override
  Widget build(BuildContext context) {
    final catProvider = context.read<CategoriesProvider>();
    final homeProvider = context.read<HomeProvider>();
    final locProvider = context.read<LocationProvider>();

    if (catProvider.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
        child: const _ProductLoadingSkeleton(),
      );
    }

    return PageView.builder(
      controller: homeProvider.pageController,
      itemCount: catProvider.categories.length,
      onPageChanged: (index) =>
          homeProvider.onPageChanged(index, locProvider.apiLanguageId),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
          child: Consumer<ProductsProvider>(
            builder: (context, prodProvider, _) {
              if (prodProvider.hasError) {
                return AppErrorState(
                  message: context.l10n.translate('connect_error'),
                  onRetry: () => homeProvider.reloadCurrentCategory(
                    locProvider.apiLanguageId,
                  ),
                );
              }
              if (prodProvider.isLoading && !prodProvider.isPaginating) {
                return const _ProductLoadingSkeleton();
              }
              if (prodProvider.visibleProducts.isEmpty) {
                return AppEmptyState(
                  message: context.l10n.translate('no_products_found'),
                );
              }

              return GridView.builder(
                cacheExtent: 500,
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: AppDimens.gridMaxExtent,
                  childAspectRatio: AppDimens.gridRatio,
                  crossAxisSpacing: AppDimens.gridSpacing,
                  mainAxisSpacing: AppDimens.gridSpacing,
                ),
                itemCount:
                    prodProvider.visibleProducts.length +
                    (prodProvider.isPaginating ? 2 : 0),
                itemBuilder: (context, idx) {
                  if (idx >= prodProvider.visibleProducts.length) {
                    return const ProductCardSkeleton();
                  }
                  final product = prodProvider.visibleProducts[idx];
                  return ProductCard(
                    category: context.l10n.translate(
                      catProvider.selectedCategorySlug,
                    ),
                    product: product,
                    onActionPressed: () {},
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductLoadingSkeleton extends StatelessWidget {
  const _ProductLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: 6,
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: AppDimens.gridMaxExtent,
        childAspectRatio: AppDimens.gridRatio,
        crossAxisSpacing: AppDimens.gridSpacing,
        mainAxisSpacing: AppDimens.gridSpacing,
      ),
      itemBuilder: (_, _) => const ProductCardSkeleton(),
    );
  }
}
