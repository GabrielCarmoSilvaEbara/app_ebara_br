import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/history_provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../pages/product_details_page.dart';
import '../theme/app_dimens.dart';

class HistoryModalSheet extends StatelessWidget {
  const HistoryModalSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final list = historyProvider.history;
    final colors = context.colors;

    return Container(
      constraints: BoxConstraints(maxHeight: context.height * 0.7),
      padding: const EdgeInsets.fromLTRB(
        AppDimens.lg,
        AppDimens.lg,
        AppDimens.lg,
        0,
      ),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
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
                context.l10n.translate('recent_products'),
                style: context.titleStyle?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (list.isNotEmpty)
                TextButton(
                  onPressed: () => historyProvider.clearHistory(),
                  child: Text(
                    context.l10n.translate('clear'),
                    style: TextStyle(color: colors.error),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (list.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 60,
                      color: colors.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.translate('no_recent_products'),
                      style: context.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                itemCount: list.length,
                padding: const EdgeInsets.only(bottom: 20),
                separatorBuilder: (context, _) => Divider(
                  height: 1,
                  color: colors.outline.withValues(alpha: 0.1),
                ),
                itemBuilder: (context, index) {
                  final item = list[index];
                  return Dismissible(
                    key: Key(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: colors.error,
                      child: Icon(Icons.delete_outline, color: colors.onError),
                    ),
                    onDismissed: (direction) {
                      historyProvider.removeFromHistory(item.id);
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: item.image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.image,
                                fit: BoxFit.contain,
                                errorWidget: (c, e, s) =>
                                    const Icon(Icons.image_not_supported),
                              )
                            : const Icon(Icons.image),
                      ),
                      title: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.subtitleStyle?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        item.model,
                        style: context.bodySmall?.copyWith(fontSize: 12),
                      ),
                      onTap: () {
                        context.pop();

                        final variants = item.variants
                            .map((e) => Map<String, dynamic>.from(e))
                            .toList();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailsPage(
                              category: item.category,
                              variants: variants,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
