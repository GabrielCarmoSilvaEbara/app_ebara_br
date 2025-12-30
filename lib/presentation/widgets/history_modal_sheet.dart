import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/history_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../pages/product_details_page.dart';

class HistoryModalSheet extends StatelessWidget {
  const HistoryModalSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final l10n = AppLocalizations.of(context)!;
    final list = historyProvider.history;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('recent_products'),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (list.isNotEmpty)
                TextButton(
                  onPressed: () => historyProvider.clearHistory(),
                  child: Text(
                    l10n.translate('clear'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  l10n.translate('no_recent_products'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                itemCount: list.length,
                padding: const EdgeInsets.only(bottom: 20),
                separatorBuilder: (context, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = list[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: item['image'] != null && item['image'].isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item['image'],
                              fit: BoxFit.contain,
                              errorWidget: (c, e, s) =>
                                  const Icon(Icons.image_not_supported),
                            )
                          : const Icon(Icons.image),
                    ),
                    title: Text(
                      item['name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      item['model'] ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(context);

                      final category = item['history_category'] ?? '';
                      final rawVariants = item['variants'] as List;
                      final variants = rawVariants
                          .map((e) => Map<String, dynamic>.from(e))
                          .toList();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsPage(
                            category: category,
                            variants: variants,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
