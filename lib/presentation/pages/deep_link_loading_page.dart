import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/ebara_data_service.dart';
import '../../core/models/product_filter_params.dart';
import '../../core/extensions/context_extensions.dart';
import 'product_details_page.dart';

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
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    final dataService = context.read<EbaraDataService>();

    try {
      final results = await dataService.searchProducts(
        ProductFilterParams(categoryId: widget.categoryId, line: 'TODOS'),
      );

      final group = dataService.groupProducts(results);
      final product = group.firstWhere(
        (p) =>
            p.productId == widget.productId ||
            p.variants.any((v) => v.productId == widget.productId),
        orElse: () =>
            throw Exception(context.l10n.translate('product_not_found')),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(
              category: widget.categoryId,
              variants: product.variants.map((e) => e.toMap()).toList(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        context.pushReplacementNamed('/home');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.translate('product_not_found'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
