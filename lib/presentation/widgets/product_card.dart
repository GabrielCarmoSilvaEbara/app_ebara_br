import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../pages/product_details_page.dart';

class ProductCard extends StatelessWidget {
  final String category;
  final Map<String, dynamic> productData;
  final VoidCallback onActionPressed;

  const ProductCard({
    super.key,
    required this.category,
    required this.productData,
    required this.onActionPressed,
  });

  String get _imageUrl => productData['image'] as String? ?? '';
  String get _productName => productData['name'] as String? ?? '';
  List<Map<String, dynamic>> get _variants =>
      (productData['variants'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ??
      [];
  bool get _hasImage => _imageUrl.isNotEmpty;
  bool get _hasVariants => _variants.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                child: _ProductImage(imageUrl: _imageUrl, hasImage: _hasImage),
              ),
              const SizedBox(height: 12),
              _CategoryLabel(category: category),
              _ProductFooter(
                productName: _productName,
                hasVariants: _hasVariants,
                colorScheme: colorScheme,
                onActionPressed: onActionPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    if (_variants.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailsPage(category: category, variants: _variants),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String imageUrl;
  final bool hasImage;

  const _ProductImage({required this.imageUrl, required this.hasImage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: hasImage
          ? Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _LoadingIndicator(progress: loadingProgress);
              },
              errorBuilder: (context, error, stackTrace) => const _ErrorIcon(),
            )
          : const _ErrorIcon(),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  final ImageChunkEvent progress;

  const _LoadingIndicator({required this.progress});

  @override
  Widget build(BuildContext context) {
    final expectedBytes = progress.expectedTotalBytes;
    final value = expectedBytes != null
        ? progress.cumulativeBytesLoaded / expectedBytes
        : null;

    return Center(
      child: CircularProgressIndicator(value: value, strokeWidth: 2),
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
  final String productName;
  final bool hasVariants;
  final ColorScheme colorScheme;
  final VoidCallback onActionPressed;

  const _ProductFooter({
    required this.productName,
    required this.hasVariants,
    required this.colorScheme,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            productName,
            style: AppTextStyles.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        _ActionButton(
          hasVariants: hasVariants,
          colorScheme: colorScheme,
          onPressed: onActionPressed,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool hasVariants;
  final ColorScheme colorScheme;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.hasVariants,
    required this.colorScheme,
    required this.onPressed,
  });

  IconData get _icon => hasVariants ? Icons.layers_outlined : Icons.search;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          child: Icon(_icon, size: 18, color: colorScheme.onPrimary),
        ),
      ),
    );
  }
}

class AnimatedProductCard extends StatefulWidget {
  final String category;
  final Map<String, dynamic> productData;
  final VoidCallback onActionPressed;

  const AnimatedProductCard({
    super.key,
    required this.category,
    required this.productData,
    required this.onActionPressed,
  });

  @override
  State<AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<AnimatedProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

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
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
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
        child: ProductCard(
          category: widget.category,
          productData: widget.productData,
          onActionPressed: widget.onActionPressed,
        ),
      ),
    );
  }
}
