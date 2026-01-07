import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/history_provider.dart';
import '../../core/providers/home_provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/models/history_item_model.dart';
import '../../core/utils/ui_util.dart';
import '../theme/app_dimens.dart';
import 'app_modal_wrapper.dart';

class HistoryModalSheet extends StatelessWidget {
  const HistoryModalSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final list = historyProvider.history;
    final colors = context.colors;

    return AppModalWrapper(
      maxHeightFactor: 0.7,
      title: context.l10n.translate('recent_products'),
      headerAction: list.isNotEmpty
          ? TextButton(
              onPressed: () => historyProvider.clearHistory(),
              child: Text(
                context.l10n.translate('clear'),
                style: TextStyle(color: colors.error),
              ),
            )
          : null,
      child: list.isEmpty
          ? const EmptyHistoryView()
          : ListView.separated(
              itemCount: list.length,
              padding: const EdgeInsets.only(
                bottom: AppDimens.lg,
                left: AppDimens.lg,
                right: AppDimens.lg,
              ),
              separatorBuilder: (context, _) => Divider(
                height: 1,
                color: colors.outline.withValues(alpha: AppDimens.opacityLow),
              ),
              itemBuilder: (context, index) {
                final item = list[index];
                return HistoryItemTile(item: item);
              },
            ),
    );
  }
}

class EmptyHistoryView extends StatelessWidget {
  const EmptyHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: AppDimens.iconHuge,
            color: context.colors.onSurface.withValues(
              alpha: AppDimens.opacityMed,
            ),
          ),
          const SizedBox(height: AppDimens.md),
          Text(
            context.l10n.translate('no_recent_products'),
            style: context.bodySmall,
          ),
        ],
      ),
    );
  }
}

class HistoryItemTile extends StatelessWidget {
  final HistoryItemModel item;

  const HistoryItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const imageSize = 50.0;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimens.lg),
        color: colors.error,
        child: Icon(Icons.delete_outline, color: colors.onError),
      ),
      onDismissed: (direction) {
        context.read<HistoryProvider>().removeFromHistory(item.id);
      },
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: item.image.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: item.image,
                  fit: BoxFit.contain,
                  memCacheHeight: UiUtil.cacheSize(context, imageSize),
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
            fontSize: AppDimens.fontLg,
          ),
        ),
        subtitle: Text(
          item.model,
          style: context.bodySmall?.copyWith(fontSize: AppDimens.fontSm),
        ),
        onTap: () {
          Navigator.pop(context);
          context.read<HomeProvider>().navigateToHistoryItem(context, item);
        },
      ),
    );
  }
}
