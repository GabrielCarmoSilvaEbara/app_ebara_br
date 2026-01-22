import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/extensions/widget_extensions.dart';
import '../../../../../core/providers/product_details_provider.dart';
import '../../../../../core/providers/location_provider.dart';
import '../../../../../core/utils/parse_util.dart';
import '../../../../../core/utils/file_type_util.dart';
import '../../../../../core/models/product_model.dart';
import '../../../../../core/models/representative_model.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_shadows.dart';
import '../app_skeletons.dart';
import '../app_expansion_tile.dart';
import '../app_buttons.dart';
import '../app_modal_wrapper.dart';

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
          ProductTitle(product: widget.product),
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
                _SectionHeader(title: context.l10n.translate('Aplicações')),
                AppDimens.md.vGap,
                const ProductApplications(),
                _SectionHeader(title: context.l10n.translate('Ficha Técnica')),
                AppDimens.md.vGap,
                ProductTechnicalSpecs(product: widget.product),
                Selector<ProductDetailsProvider, Map<String, dynamic>?>(
                  selector: (_, p) => p.descriptions,
                  builder: (context, descriptions, _) {
                    if (descriptions == null) return const SizedBox.shrink();
                    return Column(
                      children: [
                        ProductDescriptionSection(
                          title: 'Características',
                          items: descriptions[ProductDescKeys.description],
                          controller: _featuresCtrl,
                          onExpansionChanged: (isOpen) {
                            if (isOpen) _handleSectionExpansion(_featuresCtrl);
                          },
                        ),
                        ProductDescriptionSection(
                          title: 'Especificações',
                          items: descriptions[ProductDescKeys.specifications],
                          controller: _specsCtrl,
                          onExpansionChanged: (isOpen) {
                            if (isOpen) _handleSectionExpansion(_specsCtrl);
                          },
                        ),
                        ProductDescriptionSection(
                          title: 'Opções',
                          items: descriptions[ProductDescKeys.options],
                          controller: _optionsCtrl,
                          onExpansionChanged: (isOpen) {
                            if (isOpen) _handleSectionExpansion(_optionsCtrl);
                          },
                        ),
                      ],
                    );
                  },
                ),
                ProductDocumentsSection(
                  controller: _docsCtrl,
                  productName: widget.product.name,
                  onExpansionChanged: (isOpen) {
                    if (isOpen) _handleSectionExpansion(_docsCtrl);
                  },
                ),
                AppDimens.xxl.vGap,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductTitle extends StatelessWidget {
  final ProductModel product;
  const ProductTitle({super.key, required this.product});

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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

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

class ProductApplications extends StatelessWidget {
  const ProductApplications({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ProductDetailsProvider, List<Map<String, dynamic>>>(
      selector: (_, p) => p.applications,
      builder: (_, apps, _) {
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
              final String fullUrl = iconFile.isNotEmpty
                  ? "https://ebara.com.br/userfiles/aplicacoes/$iconFile"
                  : '';

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
                      color: isDark
                          ? colors.outline
                          : colors.primary.withValues(
                              alpha: AppDimens.opacityLow,
                            ),
                    ),
                  ),
                  child: iconFile.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: fullUrl,
                          fit: BoxFit.contain,
                          errorWidget: (_, _, _) => Icon(
                            Icons.image_not_supported_outlined,
                            size: AppDimens.iconLg,
                            color: iconColor.withValues(
                              alpha: AppDimens.opacityHigh,
                            ),
                          ),
                        )
                      : Icon(Icons.apps, color: iconColor),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class ProductTechnicalSpecs extends StatelessWidget {
  final ProductModel product;
  const ProductTechnicalSpecs({super.key, required this.product});

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

class ProductDescriptionSection extends StatelessWidget {
  final String title;
  final List<dynamic>? items;
  final ExpansibleController controller;
  final ValueChanged<bool> onExpansionChanged;

  const ProductDescriptionSection({
    super.key,
    required this.title,
    required this.items,
    required this.controller,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (items == null || items!.isEmpty) return const SizedBox.shrink();

    final isDark = context.theme.brightness == Brightness.dark;
    final textColor = isDark
        ? context.colors.onPrimary
        : context.colors.primary;
    final list = items!.cast<String>();

    return AppExpansionTile(
      controller: controller,
      title: context.l10n.translate(title),
      onExpansionChanged: onExpansionChanged,
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

class ProductDocumentsSection extends StatelessWidget {
  final ExpansibleController controller;
  final String productName;
  final ValueChanged<bool> onExpansionChanged;

  const ProductDocumentsSection({
    super.key,
    required this.controller,
    required this.productName,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppExpansionTile(
      controller: controller,
      title: context.l10n.translate('Documentos'),
      onExpansionChanged: onExpansionChanged,
      children: [
        Selector<ProductDetailsProvider, List<Map<String, dynamic>>>(
          selector: (_, p) => p.files,
          builder: (context, files, _) {
            if (files.isEmpty) return const _EmptyDocuments();
            return Column(
              children: files
                  .map(
                    (file) => ProductDocumentTile(
                      file: file,
                      productName: productName,
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: AppDimens.gridSpacing),
      ],
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
            color: context.colors.onSurface.withValues(
              alpha: AppDimens.opacityMed,
            ),
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

class ProductDocumentTile extends StatefulWidget {
  final Map<String, dynamic> file;
  final String productName;

  const ProductDocumentTile({
    super.key,
    required this.file,
    required this.productName,
  });

  @override
  State<ProductDocumentTile> createState() => _ProductDocumentTileState();
}

class _ProductDocumentTileState extends State<ProductDocumentTile> {
  bool _isDownloading = false;
  bool _isDownloaded = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkFileStatus();
  }

  Future<void> _checkFileStatus() async {
    final provider = context.read<ProductDetailsProvider>();
    final exists = await provider.checkFileStatus(widget.file['file']);
    if (mounted) {
      setState(() {
        _isDownloaded = exists;
      });
    }
  }

  void _handleAction() {
    if (_isDownloading) return;

    final provider = context.read<ProductDetailsProvider>();

    provider.openDocument(
      context,
      fileData: widget.file,
      productName: widget.productName,
      onStart: () {
        if (mounted) setState(() => _isDownloading = true);
      },
      onProgress: (val) {
        if (mounted) setState(() => _progress = val);
      },
      onFinish: () {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _isDownloaded = true;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final textColor = isDark
        ? context.colors.onPrimary
        : context.colors.primary;

    return GestureDetector(
      onTap: _handleAction,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.xs),
        padding: const EdgeInsets.all(AppDimens.sm),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: isDark
                ? context.colors.outline
                : context.colors.primary.withValues(
                    alpha: AppDimens.opacityLow,
                  ),
          ),
        ),
        child: Row(
          children: [
            Icon(FileTypeUtil.icon(widget.file['extension']), color: textColor),
            AppDimens.sm.hGap,
            Expanded(
              child: Text(
                widget.file['name'],
                overflow: TextOverflow.ellipsis,
                style: context.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isDownloading)
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 3,
                        color: textColor,
                      ),
                    ),
                  Icon(
                    _isDownloaded
                        ? (widget.file['extension'] == 'pdf'
                              ? Icons.visibility
                              : Icons.file_open_outlined)
                        : (_isDownloading
                              ? Icons.stop_rounded
                              : Icons.file_download_outlined),
                    color: textColor,
                    size: AppDimens.iconLg,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RepresentativesModal extends StatelessWidget {
  final String? brandId;

  const RepresentativesModal({super.key, this.brandId});

  @override
  Widget build(BuildContext context) {
    final locProvider = context.read<LocationProvider>();
    final productProvider = context.read<ProductDetailsProvider>();

    return AppModalWrapper(
      title: context.l10n.translate('representatives'),
      maxHeightFactor: null,
      backgroundColor: context.colors.surface,
      child: FutureBuilder<List<RepresentativeModel>>(
        future: productProvider.fetchRepresentatives(
          state: locProvider.state,
          languageId: locProvider.apiLanguageId,
          brandId: brandId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return _EmptyState(city: locProvider.city);
          }

          final List<RepresentativeModel> reps = snapshot.data!;
          return _RepresentativesCarousel(representatives: reps);
        },
      ),
    );
  }
}

class _RepresentativesCarousel extends StatelessWidget {
  final List<RepresentativeModel> representatives;

  const _RepresentativesCarousel({required this.representatives});

  @override
  Widget build(BuildContext context) {
    final int initialPage = 1000 * representatives.length;

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: PageController(
          viewportFraction: 0.9,
          initialPage: initialPage,
        ),
        itemBuilder: (context, index) {
          final rep = representatives[index % representatives.length];
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.xxs,
              vertical: AppDimens.sm,
            ),
            child: _RepresentativeCardV2(data: rep),
          );
        },
      ),
    );
  }
}

class _RepresentativeCardV2 extends StatelessWidget {
  final RepresentativeModel data;

  const _RepresentativeCardV2({required this.data});

  void _launch(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _openWhatsapp(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isNotEmpty) {
      _launch("https://wa.me/55$clean");
    }
  }

  void _call(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isNotEmpty) {
      _launch("tel:$clean");
    }
  }

  void _openMaps(String address, String city, String state) {
    final query = Uri.encodeComponent("$address, $city, $state");
    _launch("https://maps.google.com/?q=$query");
  }

  void _sendEmail(String email) {
    if (email.isEmpty) return;
    _launch("mailto:$email");
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final hasAddress = data.address.isNotEmpty || data.city.isNotEmpty;
    final hasPhone = data.phone.isNotEmpty;
    final hasEmail = data.email.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        boxShadow: AppShadows.md(colors.shadow),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.store,
                  color: colors.primary,
                  size: AppDimens.iconLg,
                ),
              ),
              AppDimens.sm.hGap,
              Expanded(
                child: Text(
                  data.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.subtitleStyle?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: AppDimens.fontXl,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AppSquareIconButton(
                icon: Icons.map_outlined,
                isEnabled: hasAddress,
                onTap: hasAddress
                    ? () => _openMaps(data.address, data.city, data.stateUf)
                    : null,
                backgroundColor: colors.primary,
                iconColor: colors.onPrimary,
                size: 55,
                iconSize: 26,
              ),
              AppSquareIconButton(
                icon: Icons.phone,
                isEnabled: hasPhone,
                onTap: hasPhone ? () => _call(data.phone) : null,
                backgroundColor: colors.primary,
                iconColor: colors.onPrimary,
                size: 55,
                iconSize: 26,
              ),
              AppSquareIconButton(
                icon: Icons.message,
                isEnabled: hasPhone,
                onTap: hasPhone ? () => _openWhatsapp(data.phone) : null,
                backgroundColor: colors.primary,
                iconColor: colors.onPrimary,
                size: 55,
                iconSize: 26,
              ),
              AppSquareIconButton(
                icon: Icons.email_outlined,
                isEnabled: hasEmail,
                onTap: hasEmail ? () => _sendEmail(data.email) : null,
                backgroundColor: colors.primary,
                iconColor: colors.onPrimary,
                size: 55,
                iconSize: 26,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String city;

  const _EmptyState({required this.city});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: AppDimens.iconHuge,
            color: context.colors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimens.md),
          Text(
            context.l10n.translate(
              'no_representatives_found',
              params: {'city': city},
            ),
            textAlign: TextAlign.center,
            style: context.bodyStyle,
          ),
        ],
      ),
    );
  }
}
