import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/utils/ui_util.dart';
import '../../../../../core/providers/product_details_provider.dart';
import '../../../../../core/models/product_model.dart';
import '../../../../../core/router/app_router.dart';
import '../../theme/app_dimens.dart';
import '../app_buttons.dart';

class ProductHeroSection extends StatelessWidget {
  final ProductModel product;

  const ProductHeroSection({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.image;
    final heroTag = product.id.isNotEmpty ? product.id : 'product_hero';
    final ecommerceLink = product.ecommerceLink;
    final isEcommerceEnabled =
        ecommerceLink != null && ecommerceLink.isNotEmpty;

    final btnBgColor = context.colors.onPrimary.withValues(
      alpha: AppDimens.opacityLow,
    );
    final btnIconColor = context.colors.onPrimary;
    final btnPadding = AppDimens.gridSpacing;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
      child: Stack(
        children: [
          SizedBox(
            height: AppDimens.heroImageHeight,
            width: double.infinity,
            child: RepaintBoundary(
              child: InteractiveViewer(
                maxScale: 4.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.xxxl,
                  ),
                  child: Hero(
                    tag: heroTag,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      memCacheHeight: UiUtil.cacheSize(
                        context,
                        AppDimens.heroImageHeight,
                      ),
                      placeholder: (context, url) => const SizedBox.shrink(),
                      errorWidget: (_, _, _) => Icon(
                        Icons.image_not_supported,
                        size: AppDimens.iconHuge,
                        color: context.colors.onSurface.withValues(
                          alpha: AppDimens.opacityMed,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: btnPadding,
            left: btnPadding,
            child: AppBouncingButton(
              onTap: isEcommerceEnabled
                  ? () => context
                        .read<ProductDetailsProvider>()
                        .launchEcommerce(ecommerceLink)
                  : null,
              child: _ActionButton(
                icon: Icons.monetization_on_outlined,
                isActive: isEcommerceEnabled,
                activeColor: btnBgColor,
                inactiveColor: context.colors.onPrimary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: btnPadding,
            right: btnPadding,
            child: Selector<ProductDetailsProvider, int>(
              selector: (_, p) => p.comparisonBaseIndex,
              builder: (context, baseIndex, _) {
                final currentIndex = context
                    .read<ProductDetailsProvider>()
                    .currentIndex;
                final isBase = currentIndex == baseIndex;

                return AppBouncingButton(
                  onTap: () => context
                      .read<ProductDetailsProvider>()
                      .setComparisonBase(currentIndex),
                  child: AnimatedContainer(
                    duration: AppDimens.durationNormal,
                    padding: const EdgeInsets.all(AppDimens.sm),
                    decoration: BoxDecoration(
                      color: btnBgColor,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      border: Border.all(
                        color: isBase
                            ? context.colors.onPrimary.withValues(alpha: 0.8)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      isBase ? Icons.push_pin : Icons.push_pin_outlined,
                      color: isBase ? context.colors.onPrimary : btnIconColor,
                      size: AppDimens.iconLg,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: btnPadding,
            left: btnPadding,
            child: AppBouncingButton(
              onTap: () => context.read<ProductDetailsProvider>().shareProduct(
                product,
                context.l10n.translate(
                  'share_text',
                  params: {'name': '{name}', 'model': '{model}'},
                ),
              ),
              child: _IconContainer(
                icon: Icons.share,
                bg: btnBgColor,
                fg: btnIconColor,
              ),
            ),
          ),
          Positioned(
            bottom: btnPadding,
            right: btnPadding,
            child: AppBouncingButton(
              onTap: () => context.pushNamed(
                AppRoutes.imageViewer,
                extra: {'imageUrl': imageUrl, 'heroTag': heroTag},
              ),
              child: _IconContainer(
                icon: Icons.zoom_in,
                bg: btnBgColor,
                fg: btnIconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;

  const _ActionButton({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDimens.durationNormal,
      padding: const EdgeInsets.all(AppDimens.sm),
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: isActive
              ? context.colors.onPrimary.withValues(alpha: AppDimens.opacityLow)
              : context.colors.onPrimary.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Icon(
        icon,
        color: isActive
            ? context.colors.onPrimary
            : context.colors.onPrimary.withValues(alpha: AppDimens.opacityMed),
        size: AppDimens.iconLg,
      ),
    );
  }
}

class _IconContainer extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;

  const _IconContainer({
    required this.icon,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: bg, width: 1.5),
      ),
      child: Icon(icon, color: fg, size: AppDimens.iconLg),
    );
  }
}
