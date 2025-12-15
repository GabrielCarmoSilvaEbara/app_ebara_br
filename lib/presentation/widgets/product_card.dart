import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../pages/product_details_page.dart';

class ProductCard extends StatelessWidget {
  final String category;
  final String productName;
  final String imageUrl;
  final bool isSearch;
  final VoidCallback onActionPressed;

  const ProductCard({
    super.key,
    required this.category,
    required this.productName,
    required this.imageUrl,
    required this.onActionPressed,
    this.isSearch = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.secondary, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsPage(
                productName: productName,
                category: category,
                imageUrl: imageUrl,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(),
              const SizedBox(height: 12),
              _buildCategoryLabel(),
              const SizedBox(height: 2),
              _buildProductInfo(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Expanded(
      child: Center(
        child: Image.asset(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.image_not_supported,
              size: 60,
              color: Colors.grey.shade400,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryLabel() {
    return Text(
      category,
      style: AppTextStyles.text3,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProductInfo(ColorScheme colorScheme) {
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
        _buildActionButton(colorScheme),
      ],
    );
  }

  Widget _buildActionButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: onActionPressed,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isSearch ? Icons.search : Icons.add,
          size: 18,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }
}
