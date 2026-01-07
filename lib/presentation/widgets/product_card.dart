import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/product_model.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/providers/home_provider.dart';
import '../../core/utils/ui_util.dart';
import '../theme/app_dimens.dart';
import '../widgets/app_skeletons.dart';
import 'app_buttons.dart';

class ProductCard extends StatelessWidget {
  final String category;
  final ProductModel product;
  final VoidCallback onActionPressed;

  const ProductCard({
    super.key,
    required this.category,
    required this.product,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasVariants = product.variants.isNotEmpty;

    return RepaintBoundary(
      child: Card(
        elevation: AppDimens.zero,
        color: context.theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          onTap: () {
            context.read<HomeProvider>().navigateToProduct(
              context,
              product,
              category,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ProductImage(
                    imageUrl: product.image,
                    hasImage: product.image.isNotEmpty,
                    heroTag: product.id,
                  ),
                ),
                const SizedBox(height: AppDimens.sm),
                CategoryLabel(category: category),
                ProductFooter(product: product, hasVariants: hasVariants),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  final String imageUrl;
  final bool hasImage;
  final String heroTag;

  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.hasImage,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasImage) {
      return const ErrorIcon();
    }

    return Center(
      child: Hero(
        tag: heroTag,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          memCacheWidth: UiUtil.cacheSize(context, 250),
          maxWidthDiskCache: 250,
          placeholder: (context, url) => const ProductCardSkeleton(),
          errorWidget: (context, url, error) => const ErrorIcon(),
        ),
      ),
    );
  }
}

class ErrorIcon extends StatelessWidget {
  const ErrorIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.image_not_supported,
      size: AppDimens.iconHuge,
      color: context.colors.onSurface.withValues(alpha: AppDimens.opacityMed),
    );
  }
}

class CategoryLabel extends StatelessWidget {
  final String category;

  const CategoryLabel({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Text(
      category,
      style: context.bodyStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class ProductFooter extends StatelessWidget {
  final ProductModel product;
  final bool hasVariants;

  const ProductFooter({
    super.key,
    required this.product,
    required this.hasVariants,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            product.name,
            style: context.textTheme.displayLarge?.copyWith(
              fontSize: AppDimens.fontXl,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppDimens.xs),
        ZoomButton(imageUrl: product.image, heroTag: product.id),
      ],
    );
  }
}

class ZoomButton extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const ZoomButton({super.key, required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppSquareIconButton(
      icon: Icons.zoom_in,
      onTap: () {
        context.read<HomeProvider>().openZoom(context, imageUrl, heroTag);
      },
      size: 26,
      iconSize: AppDimens.iconMd,
      backgroundColor: colors.primary,
      iconColor: colors.onPrimary,
    );
  }
}
