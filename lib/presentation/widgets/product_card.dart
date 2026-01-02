import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/product_model.dart';
import '../../core/extensions/context_extensions.dart';
import '../theme/app_dimens.dart';
import '../pages/product_details_page.dart';
import '../widgets/product_card_skeleton.dart';
import 'image_viewer.dart';
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
    final colors = context.colors;
    final hasVariants = product.variants.isNotEmpty;

    return Card(
      elevation: 0,
      color: context.theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        side: BorderSide(
          color: colors.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        onTap: () => _navigateToDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProductImage(
                  imageUrl: product.image,
                  hasImage: product.image.isNotEmpty,
                  heroTag: product.id,
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              _CategoryLabel(category: category),
              _ProductFooter(product: product, hasVariants: hasVariants),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    if (product.variants.isEmpty) {
      return;
    }

    final variantsMap = product.variants.map((v) => v.toMap()).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailsPage(category: category, variants: variantsMap),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String imageUrl;
  final bool hasImage;
  final String heroTag;

  const _ProductImage({
    required this.imageUrl,
    required this.hasImage,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasImage) {
      return const _ErrorIcon();
    }

    return Center(
      child: Hero(
        tag: heroTag,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          memCacheWidth: 500,
          maxWidthDiskCache: 500,
          placeholder: (context, url) => const ProductCardSkeleton(),
          errorWidget: (context, url, error) => const _ErrorIcon(),
        ),
      ),
    );
  }
}

class _ErrorIcon extends StatelessWidget {
  const _ErrorIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.image_not_supported,
      size: 60,
      color: context.colors.onSurface.withValues(alpha: 0.3),
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  final String category;

  const _CategoryLabel({required this.category});

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

class _ProductFooter extends StatelessWidget {
  final ProductModel product;
  final bool hasVariants;

  const _ProductFooter({required this.product, required this.hasVariants});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            product.name,
            style: context.textTheme.displayLarge?.copyWith(fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        _ZoomButton(imageUrl: product.image, heroTag: product.id),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _ZoomButton({required this.imageUrl, required this.heroTag});

  void _openZoom(BuildContext context) {
    if (imageUrl.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            ImageViewer(imageUrl: imageUrl, heroTag: heroTag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppSquareIconButton(
      icon: Icons.zoom_in,
      onTap: () => _openZoom(context),
      size: 26,
      iconSize: 18,
      backgroundColor: colors.primary,
      iconColor: colors.onPrimary,
    );
  }
}
