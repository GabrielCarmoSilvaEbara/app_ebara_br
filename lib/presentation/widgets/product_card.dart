import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/product_model.dart';
import '../theme/app_text_styles.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final hasVariants = product.variants.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.secondary.withValues(alpha: 0.5),
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
                colorScheme: colorScheme,
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
      style: AppTextStyles.text3,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ProductFooter extends StatelessWidget {
  final ProductModel product;
  final bool hasVariants;
  final ColorScheme colorScheme;

  const _ProductFooter({
    required this.product,
    required this.hasVariants,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            product.name,
            style: AppTextStyles.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        _ZoomButton(
          imageUrl: product.image,
          heroTag: product.id,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final ColorScheme colorScheme;

  const _ZoomButton({
    required this.imageUrl,
    required this.heroTag,
    required this.colorScheme,
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
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _openZoom(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          child: Icon(Icons.zoom_in, size: 18, color: colorScheme.onPrimary),
        ),
      ),
    );
  }
}

class AnimatedProductCard extends StatefulWidget {
  final String category;
  final ProductModel product;
  final VoidCallback onActionPressed;

  const AnimatedProductCard({
    super.key,
    required this.category,
    required this.product,
    required this.onActionPressed,
  });

  @override
  State<AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<AnimatedProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: RepaintBoundary(
          child: ProductCard(
            category: widget.category,
            product: widget.product,
            onActionPressed: widget.onActionPressed,
          ),
        ),
      ),
    );
  }
}
