import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/product_model.dart';
import '../pages/product_details_page.dart';
import '../widgets/product_card_skeleton.dart';
import 'image_viewer.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasVariants = product.variants.isNotEmpty;

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark
            ? BorderSide.none
            : BorderSide(
                color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                width: 1,
              ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(8),
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
              const SizedBox(height: 12),
              _CategoryLabel(category: category),
              _ProductFooter(
                product: product,
                hasVariants: hasVariants,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    if (product.variants.isEmpty) return;

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
    if (!hasImage) return const _ErrorIcon();

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
    return Icon(Icons.image_not_supported, size: 60, color: Colors.grey[400]);
  }
}

class _CategoryLabel extends StatelessWidget {
  final String category;

  const _CategoryLabel({required this.category});

  @override
  Widget build(BuildContext context) {
    return Text(
      category,
      style: Theme.of(context).textTheme.labelMedium,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ProductFooter extends StatelessWidget {
  final ProductModel product;
  final bool hasVariants;
  final ThemeData theme;

  const _ProductFooter({
    required this.product,
    required this.hasVariants,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            product.name,
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        _ZoomButton(imageUrl: product.image, heroTag: product.id, theme: theme),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final ThemeData theme;

  const _ZoomButton({
    required this.imageUrl,
    required this.heroTag,
    required this.theme,
  });

  void _openZoom(BuildContext context) {
    if (imageUrl.isEmpty) return;

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
    return Material(
      color: theme.primaryColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _openZoom(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          child: Icon(
            Icons.zoom_in,
            size: 18,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
