import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/products_provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/router/app_router.dart';

class DeepLinkLoadingPage extends StatefulWidget {
  final String categoryId;
  final String productId;

  const DeepLinkLoadingPage({
    super.key,
    required this.categoryId,
    required this.productId,
  });

  @override
  State<DeepLinkLoadingPage> createState() => _DeepLinkLoadingPageState();
}

class _DeepLinkLoadingPageState extends State<DeepLinkLoadingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndNavigate();
    });
  }

  Future<void> _loadAndNavigate() async {
    final productsProvider = context.read<ProductsProvider>();

    try {
      final product = await productsProvider.fetchProductByDeepLink(
        widget.categoryId,
        widget.productId,
      );

      if (!mounted) return;

      if (product != null) {
        context.pushReplacementNamed(
          AppRoutes.productDetails,
          extra: {'category': widget.categoryId, 'variants': product.variants},
        );
      } else {
        _handleError();
      }
    } catch (_) {
      if (mounted) _handleError();
    }
  }

  void _handleError() {
    context.pushReplacementNamed(AppRoutes.home);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.translate('product_not_found'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
