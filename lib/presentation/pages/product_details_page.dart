import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/product_details_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/models/product_model.dart';
import '../theme/app_dimens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/product/product_hero_section.dart';
import '../widgets/product/product_info_section.dart';
import '../widgets/product/comparison_sheet.dart';

class ProductDetailsPage extends StatefulWidget {
  final String category;
  final List<ProductModel> variants;

  const ProductDetailsPage({
    super.key,
    required this.category,
    required this.variants,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();

    if (widget.variants.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pop();
      });
      _pageController = PageController();
      return;
    }

    final provider = context.read<ProductDetailsProvider>();
    final locProvider = context.read<LocationProvider>();
    final historyProvider = context.read<HistoryProvider>();

    final product = widget.variants.first.copyWith(variants: widget.variants);

    _pageController = PageController(initialPage: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.initProductView(
        productId: product.productId,
        languageId: locProvider.apiLanguageId,
        product: product,
        category: widget.category,
        historyProvider: historyProvider,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _changeVariant(int index) {
    if (index < 0 || index >= widget.variants.length) return;

    HapticFeedback.lightImpact();
    context.read<ProductDetailsProvider>().updateIndex(index);
    _pageController.animateToPage(
      index,
      duration: AppDimens.durationNormal,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppDimens.xl),
            ProductDetailsHeader(
              category: widget.category,
              totalVariants: widget.variants.length,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  context.read<ProductDetailsProvider>().updateIndex(index);
                },
                itemCount: widget.variants.length,
                itemBuilder: (context, index) {
                  final variant = widget.variants[index];
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: AppDimens.lg),
                        ProductHeroSection(product: variant),
                        const SizedBox(height: AppDimens.lg),
                        ProductInfoSection(product: variant),
                      ],
                    ),
                  );
                },
              ),
            ),
            ProductBottomControls(
              variants: widget.variants,
              onVariantChange: _changeVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailsHeader extends StatelessWidget {
  final String category;
  final int totalVariants;

  const ProductDetailsHeader({
    super.key,
    required this.category,
    required this.totalVariants,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.lg,
        vertical: AppDimens.sm,
      ),
      child: Row(
        children: [
          AppSquareIconButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => context.pop(),
            backgroundColor: context.colors.onPrimary.withValues(alpha: 0.2),
            iconColor: context.colors.onPrimary,
            iconSize: AppDimens.iconMd,
          ),
          Expanded(
            child: Text(
              context.l10n.translate(category).toUpperCase(),
              textAlign: TextAlign.center,
              style: context.subtitleStyle?.copyWith(
                color: context.colors.onPrimary,
                letterSpacing: 1.2,
                fontSize: AppDimens.fontMd,
              ),
            ),
          ),
          Selector<ProductDetailsProvider, int>(
            selector: (_, p) => p.currentIndex,
            builder: (_, currentIndex, _) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.colors.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                ),
                child: Text(
                  "${currentIndex + 1} / $totalVariants",
                  style: TextStyle(
                    color: context.colors.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ProductBottomControls extends StatelessWidget {
  final List<ProductModel> variants;
  final ValueChanged<int> onVariantChange;

  const ProductBottomControls({
    super.key,
    required this.variants,
    required this.onVariantChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.xl,
        vertical: AppDimens.lg,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withValues(alpha: 0.15),
            blurRadius: AppDimens.lg,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Selector<ProductDetailsProvider, int>(
        selector: (_, p) => p.currentIndex,
        builder: (context, currentIndex, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSquareIconButton(
                icon: Icons.arrow_back_ios_rounded,
                isEnabled: currentIndex > 0,
                onTap: currentIndex > 0
                    ? () => onVariantChange(currentIndex - 1)
                    : null,
                iconSize: AppDimens.iconMd,
              ),
              GestureDetector(
                onTap: variants.length > 1
                    ? () {
                        HapticFeedback.mediumImpact();
                        final provider = context.read<ProductDetailsProvider>();
                        final base = variants[provider.comparisonBaseIndex];
                        final current = variants[currentIndex];

                        context.showAppBottomSheet(
                          child: ComparisonSheet(base: base, current: current),
                        );
                      }
                    : null,
                child: Container(
                  width: 70,
                  height: AppDimens.buttonHeight,
                  decoration: BoxDecoration(
                    color: variants.length > 1
                        ? context.colors.primary
                        : context.colors.onSurface.withValues(
                            alpha: AppDimens.opacityLow,
                          ),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  child: Icon(
                    Icons.compare_arrows,
                    size: 26,
                    color: variants.length > 1
                        ? context.colors.onPrimary
                        : context.colors.onSurface.withValues(
                            alpha: AppDimens.opacityMed,
                          ),
                  ),
                ),
              ),
              AppSquareIconButton(
                icon: Icons.arrow_forward_ios_rounded,
                isEnabled: currentIndex < variants.length - 1,
                onTap: currentIndex < variants.length - 1
                    ? () => onVariantChange(currentIndex + 1)
                    : null,
                iconSize: AppDimens.iconMd,
              ),
            ],
          );
        },
      ),
    );
  }
}
