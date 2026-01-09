import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/extensions/widget_extensions.dart';
import '../../../../../core/providers/product_details_provider.dart';
import '../../../../../core/utils/parse_util.dart';
import '../../../../../core/utils/file_type_util.dart';
import '../../../../../core/models/product_model.dart';
import '../../theme/app_dimens.dart';
import '../app_skeletons.dart';
import '../auth_modal_sheet.dart';
import '../../../../../core/providers/auth_provider.dart';
import '../../../../../core/services/analytics_service.dart';
import '../app_expansion_tile.dart';

class ProductInfoSection extends StatefulWidget {
  final ProductModel product;

  const ProductInfoSection({super.key, required this.product});

  @override
  State<ProductInfoSection> createState() => _ProductInfoSectionState();
}

class _ProductInfoSectionState extends State<ProductInfoSection> {
  final ExpansibleController _featuresCtrl = ExpansibleController();
  final ExpansibleController _specsCtrl = ExpansibleController();
  final ExpansibleController _optionsCtrl = ExpansibleController();
  final ExpansibleController _docsCtrl = ExpansibleController();

  void _handleSectionExpansion(ExpansibleController selected) {
    if (selected != _featuresCtrl && _featuresCtrl.isExpanded) {
      _featuresCtrl.collapse();
    }
    if (selected != _specsCtrl && _specsCtrl.isExpanded) _specsCtrl.collapse();
    if (selected != _optionsCtrl && _optionsCtrl.isExpanded) {
      _optionsCtrl.collapse();
    }
    if (selected != _docsCtrl && _docsCtrl.isExpanded) _docsCtrl.collapse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.xl,
        AppDimens.radiusXxl,
        AppDimens.xl,
        AppDimens.zero,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.xxxl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleRow(product: widget.product),
          AppDimens.sm.vGap,
          Selector<ProductDetailsProvider, bool>(
            selector: (_, p) => p.isLoading,
            builder: (context, isLoading, child) {
              if (isLoading) return const FilesSkeleton();
              return child!;
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: context.l10n.translate("Aplicações")),
                AppDimens.md.vGap,
                Selector<ProductDetailsProvider, List<Map<String, dynamic>>>(
                  selector: (_, p) => p.applications,
                  builder: (_, apps, _) => _ApplicationIcons(apps: apps),
                ),
                _SectionTitle(title: context.l10n.translate("Ficha Técnica")),
                AppDimens.md.vGap,
                _TechnicalSpecs(product: widget.product),
                Selector<ProductDetailsProvider, Map<String, dynamic>?>(
                  selector: (_, p) => p.descriptions,
                  builder: (context, descriptions, _) {
                    if (descriptions == null) return const SizedBox.shrink();
                    return Column(
                      children: [
                        _buildListSection(
                          context,
                          title: "Características",
                          items: descriptions['description'],
                          controller: _featuresCtrl,
                        ),
                        _buildListSection(
                          context,
                          title: "Especificações",
                          items: descriptions['specifications'],
                          controller: _specsCtrl,
                        ),
                        _buildListSection(
                          context,
                          title: "Opções",
                          items: descriptions['options'],
                          controller: _optionsCtrl,
                        ),
                      ],
                    );
                  },
                ),
                AppExpansionTile(
                  controller: _docsCtrl,
                  title: context.l10n.translate("Documentos"),
                  onExpansionChanged: (isOpen) {
                    if (isOpen) _handleSectionExpansion(_docsCtrl);
                  },
                  children: [
                    Selector<
                      ProductDetailsProvider,
                      List<Map<String, dynamic>>
                    >(
                      selector: (_, p) => p.files,
                      builder: (context, files, _) {
                        if (files.isEmpty) return const _EmptyDocuments();
                        return Column(
                          children: files
                              .map(
                                (file) => _FileLinkItem(
                                  file: file,
                                  productName: widget.product.name,
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: AppDimens.gridSpacing),
                  ],
                ),
              ],
            ),
          ),
          AppDimens.xxl.vGap,
        ],
      ),
    );
  }

  Widget _buildListSection(
    BuildContext context, {
    required String title,
    required List<dynamic> items,
    required ExpansibleController controller,
  }) {
    final isDark = context.theme.brightness == Brightness.dark;
    final textColor = isDark
        ? context.colors.onPrimary
        : context.colors.primary;
    final list = items.cast<String>();

    return AppExpansionTile(
      controller: controller,
      title: context.l10n.translate(title),
      onExpansionChanged: (isOpen) {
        if (isOpen) _handleSectionExpansion(controller);
      },
      children: list
          .map(
            (text) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppDimens.xs),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.md,
                vertical: AppDimens.sm,
              ),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Text(
                text,
                style: context.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: AppDimens.fontMd,
                  color: textColor,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TitleRow extends StatelessWidget {
  final ProductModel product;
  const _TitleRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.titleStyle?.copyWith(fontSize: 19),
          ),
        ),
        AppDimens.sm.hGap,
        Text(
          product.model,
          style: context.bodyStyle?.copyWith(fontSize: AppDimens.fontMd),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    return Text(
      title,
      style: context.subtitleStyle?.copyWith(
        color: isDark ? context.colors.onPrimary : context.colors.primary,
        fontSize: AppDimens.fontSm,
      ),
    );
  }
}

class _ApplicationIcons extends StatelessWidget {
  final List<Map<String, dynamic>> apps;
  const _ApplicationIcons({required this.apps});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.theme.brightness == Brightness.dark;
    final iconColor = isDark ? colors.onPrimary : colors.primary;
    final bgColor = isDark
        ? colors.onPrimary.withValues(alpha: AppDimens.opacityLow)
        : colors.primary.withValues(alpha: 0.05);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.md),
      child: Wrap(
        spacing: AppDimens.sm,
        runSpacing: AppDimens.sm,
        children: apps.map((app) {
          final String iconFile = app['icon_file'] ?? '';
          final String fullUrl =
              "https://ebara.com.br/userfiles/aplicacoes/$iconFile";

          return Tooltip(
            message: app['application_name'] ?? '',
            triggerMode: TooltipTriggerMode.tap,
            showDuration: const Duration(seconds: 3),
            child: Container(
              padding: const EdgeInsets.all(AppDimens.xs),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppDimens.gridSpacing),
                border: Border.all(
                  color: isDark ? colors.outline : colors.primary
                    ..withValues(alpha: AppDimens.opacityLow),
                ),
              ),
              child: iconFile.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: fullUrl,
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) => Icon(
                        Icons.image_not_supported_outlined,
                        size: AppDimens.iconLg,
                        color: iconColor
                          ..withValues(alpha: AppDimens.opacityHigh),
                      ),
                    )
                  : Icon(Icons.apps, color: iconColor),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TechnicalSpecs extends StatelessWidget {
  final ProductModel product;
  const _TechnicalSpecs({required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TechTile(
          label: context.l10n.translate('power'),
          value: "${ParseUtil.formatValue(product.power)} CV",
        ),
        _TechTile(
          label: context.l10n.translate('rotation'),
          value: "${product.rpm} RPM",
        ),
        _TechTile(
          label: context.l10n.translate('max_pressure'),
          value: "${ParseUtil.formatValue(product.mcaMax)} MCA",
        ),
        _TechTile(
          label: context.l10n.translate('max_flow'),
          value: "${ParseUtil.formatValue(product.rateMax)} m³/h",
        ),
        _TechTile(
          label: context.l10n.translate('frequency'),
          value: "${product.frequency} Hz",
        ),
      ],
    );
  }
}

class _TechTile extends StatelessWidget {
  final String label;
  final String value;
  const _TechTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final textColor = isDark
        ? context.colors.onPrimary
        : context.colors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.sm,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.subtitleStyle?.copyWith(
              color: textColor,
              fontSize: AppDimens.fontMd,
            ),
          ),
          Text(
            value,
            style: context.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: AppDimens.fontMd,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDocuments extends StatelessWidget {
  const _EmptyDocuments();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.lg),
      child: Column(
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: AppDimens.xxxl,
            color: context.colors.onSurface
              ..withValues(alpha: AppDimens.opacityMed),
          ),
          const SizedBox(height: AppDimens.xs),
          Text(
            context.l10n.translate("Nenhum documento disponível"),
            style: context.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FileLinkItem extends StatelessWidget {
  final Map<String, dynamic> file;
  final String productName;

  const _FileLinkItem({required this.file, required this.productName});

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final textColor = isDark
        ? context.colors.onPrimary
        : context.colors.primary;

    return GestureDetector(
      onTap: () async {
        if (context.read<AuthProvider>().status != AuthStatus.authenticated) {
          context.showAppBottomSheet(child: const AuthModalSheet());
          return;
        }
        AnalyticsService.logDownloadDocument(file['name'], productName);
        await context.read<ProductDetailsProvider>().launchEcommerce(
          file['full_url'],
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.xs),
        padding: const EdgeInsets.all(AppDimens.sm),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: isDark ? context.colors.outline : context.colors.primary
              ..withValues(alpha: AppDimens.opacityLow),
          ),
        ),
        child: Row(
          children: [
            Icon(FileTypeUtil.icon(file['extension']), color: textColor),
            AppDimens.sm.hGap,
            Expanded(
              child: Text(
                file['name'],
                overflow: TextOverflow.ellipsis,
                style: context.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              color: textColor,
              size: AppDimens.iconLg,
            ),
          ],
        ),
      ),
    );
  }
}
