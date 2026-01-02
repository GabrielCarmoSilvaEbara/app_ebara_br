import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers/product_details_provider.dart';
import '../../core/utils/parse_util.dart';
import '../../core/utils/file_type_util.dart';
import '../widgets/files_skeleton.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/analytics_service.dart';
import '../../core/extensions/context_extensions.dart';
import '../widgets/auth_modal_sheet.dart';
import '../widgets/image_viewer.dart';
import '../widgets/app_buttons.dart';
import '../theme/app_dimens.dart';
import '../theme/app_shadows.dart';

class ProductDetailsPage extends StatefulWidget {
  final String category;
  final List<Map<String, dynamic>> variants;

  const ProductDetailsPage({
    super.key,
    required this.category,
    required this.variants,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late PageController _pageController;
  final ExpansibleController _featuresCtrl = ExpansibleController();
  final ExpansibleController _specsCtrl = ExpansibleController();
  final ExpansibleController _optionsCtrl = ExpansibleController();
  final ExpansibleController _docsCtrl = ExpansibleController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProductDetailsProvider>();
    final locProvider = context.read<LocationProvider>();
    final historyProvider = context.read<HistoryProvider>();
    final product = widget.variants.first;
    final id = product['id_product'];

    _pageController = PageController(initialPage: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.loadProductData(id, locProvider.apiLanguageId);

      final productMap = {...product, 'variants': widget.variants};
      historyProvider.addToHistory(productMap, widget.category);

      AnalyticsService.logViewProduct(
        product['id_product'],
        product['name'],
        widget.category,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleExpansion(ExpansibleController selected) {
    if (selected != _featuresCtrl && _featuresCtrl.isExpanded) {
      _featuresCtrl.collapse();
    }
    if (selected != _specsCtrl && _specsCtrl.isExpanded) {
      _specsCtrl.collapse();
    }
    if (selected != _optionsCtrl && _optionsCtrl.isExpanded) {
      _optionsCtrl.collapse();
    }
    if (selected != _docsCtrl && _docsCtrl.isExpanded) {
      _docsCtrl.collapse();
    }
  }

  void _changeVariant(int index, ProductDetailsProvider provider) {
    if (index < 0 || index >= widget.variants.length) {
      return;
    }
    HapticFeedback.lightImpact();
    provider.updateIndex(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _shareProduct(Map<String, dynamic> variant) {
    final String name = variant['name'] ?? '';
    final String model = variant['model'] ?? '';
    final String link = variant['ecommerce_link'] ?? 'https://ebara.com.br';

    final text = context.l10n.translate(
      'share_text',
      params: {'name': name, 'model': model},
    );

    SharePlus.instance.share(ShareParams(text: '$text $link'));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductDetailsProvider>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppDimens.xl),
            _buildHeader(provider),
            Expanded(
              child: PageView.builder(
                key: ValueKey(widget.variants.first['id_product']),
                controller: _pageController,
                onPageChanged: (index) => provider.updateIndex(index),
                itemCount: widget.variants.length,
                itemBuilder: (context, index) {
                  final v = widget.variants[index];

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: AppDimens.lg),
                        _buildHeroImageSection(v, provider),
                        const SizedBox(height: AppDimens.lg),
                        _buildInfoContent(v, provider),
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildBottomControls(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ProductDetailsProvider provider) {
    final textColor = context.colors.onPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.lg,
        vertical: AppDimens.sm,
      ),
      child: Row(
        children: [
          AppSquareIconButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => context.pop(),
            backgroundColor: context.colors.onPrimary.withValues(alpha: 0.2),
            iconColor: context.colors.onPrimary,
            iconSize: 18,
          ),
          Expanded(
            child: Text(
              context.l10n.translate(widget.category).toUpperCase(),
              textAlign: TextAlign.center,
              style: context.subtitleStyle?.copyWith(
                color: textColor,
                letterSpacing: 1.2,
                fontSize: 13,
              ),
            ),
          ),
          _VariantCounter(
            current: provider.currentIndex + 1,
            total: widget.variants.length,
          ),
        ],
      ),
    );
  }

  Future<void> _launchEcommerce(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildHeroImageSection(
    Map<String, dynamic> variant,
    ProductDetailsProvider provider,
  ) {
    final isBase = provider.currentIndex == provider.comparisonBaseIndex;
    final String? ecommerceLink = variant['ecommerce_link'];
    final bool isEcommerceEnabled =
        ecommerceLink != null && ecommerceLink.isNotEmpty;
    final String imageUrl = variant['image'] ?? '';
    final String heroTag = variant['id'] ?? 'product_hero';

    final btnBgColor = context.colors.onPrimary.withValues(alpha: 0.2);
    final btnIconColor = context.colors.onPrimary;

    return Dismissible(
      key: const Key('dismiss_image_section'),
      direction: DismissDirection.down,
      onDismissed: (_) {
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
        child: Stack(
          children: [
            _ProductImage(
              imageUrl: imageUrl,
              index: provider.currentIndex,
              height: 220,
              heroTag: heroTag,
            ),
            Positioned(
              top: 10,
              left: 10,
              child: AppBouncingButton(
                onTap: isEcommerceEnabled
                    ? () => _launchEcommerce(ecommerceLink)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isEcommerceEnabled
                        ? btnBgColor
                        : context.colors.onPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(
                      color: isEcommerceEnabled
                          ? btnIconColor.withValues(alpha: 0.2)
                          : context.colors.onPrimary.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.monetization_on_outlined,
                    color: isEcommerceEnabled
                        ? btnIconColor
                        : context.colors.onPrimary.withValues(alpha: 0.3),
                    size: 20,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: AppBouncingButton(
                onTap: () => provider.setComparisonBase(provider.currentIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: btnBgColor,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(
                      color: isBase
                          ? context.colors.onPrimary.withValues(alpha: 0.8)
                          : context.colors.surface.withValues(alpha: 0),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    isBase ? Icons.push_pin : Icons.push_pin_outlined,
                    color: isBase ? context.colors.onPrimary : btnIconColor,
                    size: 20,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: AppBouncingButton(
                onTap: () => _shareProduct(variant),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: btnBgColor,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(color: btnBgColor, width: 1.5),
                  ),
                  child: Icon(Icons.share, color: btnIconColor, size: 20),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: AppBouncingButton(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          ImageViewer(imageUrl: imageUrl, heroTag: heroTag),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: btnBgColor,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(color: btnBgColor, width: 1.5),
                  ),
                  child: Icon(Icons.zoom_in, color: btnIconColor, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContent(
    Map<String, dynamic> variantData,
    ProductDetailsProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  variantData['name'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.titleStyle?.copyWith(fontSize: 19),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                variantData['model'],
                style: context.bodyStyle?.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.sm),
          if (provider.isLoading)
            const FilesSkeleton()
          else ...[
            _SectionTitle(context.l10n.translate("Aplicações")),
            const SizedBox(height: AppDimens.md),
            _ApplicationIcons(apps: provider.applications),
            _SectionTitle(context.l10n.translate("Ficha Técnica")),
            const SizedBox(height: AppDimens.md),
            _TechnicalSpecs(data: variantData),
            if (provider.descriptions != null) ...[
              _CollapsibleSection(
                title: context.l10n.translate("Características"),
                items: provider.descriptions!['description'] as List<String>,
                controller: _featuresCtrl,
                onExpansionChanged: (isOpen) {
                  if (isOpen) _handleExpansion(_featuresCtrl);
                },
              ),
              _CollapsibleSection(
                title: context.l10n.translate("Especificações"),
                items: provider.descriptions!['specifications'] as List<String>,
                controller: _specsCtrl,
                onExpansionChanged: (isOpen) {
                  if (isOpen) _handleExpansion(_specsCtrl);
                },
              ),
              _CollapsibleSection(
                title: context.l10n.translate("Opções"),
                items: provider.descriptions!['options'] as List<String>,
                controller: _optionsCtrl,
                onExpansionChanged: (isOpen) {
                  if (isOpen) _handleExpansion(_optionsCtrl);
                },
              ),
            ],
            _FilesSection(
              files: provider.files,
              productName: variantData['name'],
              controller: _docsCtrl,
              onExpansionChanged: (isOpen) {
                if (isOpen) _handleExpansion(_docsCtrl);
              },
            ),
          ],
          const SizedBox(height: AppDimens.xxl),
        ],
      ),
    );
  }

  Widget _buildBottomControls(ProductDetailsProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.xl,
        vertical: AppDimens.lg,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: AppShadows.lg(context.colors.shadow),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppSquareIconButton(
            icon: Icons.arrow_back_ios_rounded,
            isEnabled: provider.currentIndex > 0,
            onTap: provider.currentIndex > 0
                ? () => _changeVariant(provider.currentIndex - 1, provider)
                : null,
            iconSize: 18,
          ),
          _ComparisonButton(
            isEnabled: widget.variants.length > 1,
            onTap: widget.variants.length > 1
                ? () {
                    HapticFeedback.mediumImpact();

                    final base = widget.variants[provider.comparisonBaseIndex];
                    final current = widget.variants[provider.currentIndex];

                    AnalyticsService.logCompareProducts(
                      base['id_product'],
                      current['id_product'],
                    );

                    context.showAppBottomSheet(
                      child: _ComparisonSheet(base: base, current: current),
                    );
                  }
                : null,
          ),
          AppSquareIconButton(
            icon: Icons.arrow_forward_ios_rounded,
            isEnabled: provider.currentIndex < widget.variants.length - 1,
            onTap: provider.currentIndex < widget.variants.length - 1
                ? () => _changeVariant(provider.currentIndex + 1, provider)
                : null,
            iconSize: 18,
          ),
        ],
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
        ? colors.onPrimary.withValues(alpha: 0.1)
        : colors.primary.withValues(alpha: 0.05);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: apps.map((app) {
          final String iconFile = app['icon_file'] ?? '';
          final String fullUrl =
              "https://ebara.com.br/userfiles/aplicacoes/$iconFile";

          return Tooltip(
            message: app['application_name'] ?? '',
            triggerMode: TooltipTriggerMode.tap,
            showDuration: const Duration(seconds: 3),
            waitDuration: Duration.zero,
            child: Container(
              padding: const EdgeInsets.all(8),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? colors.outline
                      : colors.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: iconFile.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: fullUrl,
                      fit: BoxFit.contain,
                      errorWidget: (c, e, s) => Icon(
                        Icons.image_not_supported_outlined,
                        size: 20,
                        color: iconColor.withValues(alpha: 0.5),
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

class _FilesSection extends StatelessWidget {
  final List<Map<String, dynamic>> files;
  final String productName;
  final ExpansibleController? controller;
  final ValueChanged<bool>? onExpansionChanged;

  const _FilesSection({
    required this.files,
    required this.productName,
    this.controller,
    this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? colors.onPrimary : colors.primary;

    return Theme(
      data: theme.copyWith(dividerColor: colors.surface.withValues(alpha: 0)),
      child: ExpansionTile(
        controller: controller,
        onExpansionChanged: onExpansionChanged,
        tilePadding: EdgeInsets.zero,
        title: Text(
          context.l10n.translate("Documentos"),
          style: context.subtitleStyle?.copyWith(
            color: textColor,
            fontSize: 12,
          ),
        ),
        iconColor: textColor,
        collapsedIconColor: textColor,
        children: [
          if (files.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_off_outlined,
                    size: 40,
                    color: colors.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.translate("Nenhum documento disponível"),
                    style: context.bodySmall,
                  ),
                ],
              ),
            )
          else
            ...files.map(
              (file) => _FileLinkItem(file: file, productName: productName),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _ComparisonSheet extends StatelessWidget {
  final Map<String, dynamic> base;
  final Map<String, dynamic> current;
  const _ComparisonSheet({required this.base, required this.current});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: context.height * 0.7,
      padding: const EdgeInsets.all(AppDimens.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: colors.outline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: AppDimens.lg),
          Text(
            context.l10n.translate('technical_comparison'),
            style: context.titleStyle?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppDimens.lg),
          Expanded(
            child: ListView(
              children: [
                _CompareCard(
                  label: context.l10n.translate('power'),
                  baseValue: base['power'],
                  currentValue: current['power'],
                  unit: "CV",
                ),
                _CompareCard(
                  label: context.l10n.translate('max_pressure'),
                  baseValue: base['mca_max'],
                  currentValue: current['mca_max'],
                  unit: "MCA",
                ),
                _CompareCard(
                  label: context.l10n.translate('max_flow'),
                  baseValue: base['rate_max'],
                  currentValue: current['rate_max'],
                  unit: "m³/h",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback? onTap;
  const _ComparisonButton({required this.isEnabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 55,
        decoration: BoxDecoration(
          color: isEnabled
              ? colors.primary
              : colors.onSurface.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Icon(
          Icons.compare_arrows,
          size: 26,
          color: isEnabled
              ? colors.onPrimary
              : colors.onSurface.withValues(alpha: 0.3),
        ),
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
    final colors = context.colors;
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? colors.onPrimary : colors.primary;

    return GestureDetector(
      onTap: () async {
        final authProvider = context.read<AuthProvider>();

        if (authProvider.status != AuthStatus.authenticated) {
          context.showAppBottomSheet(child: const AuthModalSheet());
          return;
        }

        AnalyticsService.logDownloadDocument(file['name'], productName);

        final Uri uri = Uri.parse(file['full_url']);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: isDark
                ? colors.outline
                : colors.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(FileTypeUtil.icon(file['extension']), color: textColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                file['name'],
                overflow: TextOverflow.ellipsis,
                style: context.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? colors.outline
                    : colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.open_in_new_rounded,
                color: textColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnicalSpecs extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TechnicalSpecs({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TechTile(
          label: context.l10n.translate('power'),
          value: "${ParseUtil.formatValue(data['power'])} CV",
        ),
        _TechTile(
          label: context.l10n.translate('rotation'),
          value: "${data['rpm'] ?? '---'} RPM",
        ),
        _TechTile(
          label: context.l10n.translate('max_pressure'),
          value: "${ParseUtil.formatValue(data['mca_max'])} MCA",
        ),
        _TechTile(
          label: context.l10n.translate('max_flow'),
          value: "${ParseUtil.formatValue(data['rate_max'])} m³/h",
        ),
        _TechTile(
          label: context.l10n.translate('frequency'),
          value: "${data['frequency'] ?? '---'} Hz",
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
    final theme = context.theme;
    final colors = context.colors;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? colors.onPrimary : colors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.subtitleStyle?.copyWith(
              color: textColor,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: context.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsibleSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final ExpansibleController? controller;
  final ValueChanged<bool>? onExpansionChanged;

  const _CollapsibleSection({
    required this.title,
    required this.items,
    this.controller,
    this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? colors.onPrimary : colors.primary;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Theme(
      data: theme.copyWith(dividerColor: colors.surface.withValues(alpha: 0)),
      child: ExpansionTile(
        controller: controller,
        onExpansionChanged: onExpansionChanged,
        tilePadding: EdgeInsets.zero,
        title: Text(
          title,
          style: context.subtitleStyle?.copyWith(
            color: textColor,
            fontSize: 12,
          ),
        ),
        iconColor: textColor,
        collapsedIconColor: textColor,
        children: [
          ...items.map(
            (text) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Text(
                text,
                style: context.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: textColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    return Text(
      title,
      style: context.subtitleStyle?.copyWith(
        color: isDark ? context.colors.onPrimary : context.colors.primary,
        fontSize: 12,
      ),
    );
  }
}

class _VariantCounter extends StatelessWidget {
  final int current;
  final int total;

  const _VariantCounter({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.onPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$current / $total",
        style: TextStyle(
          color: context.colors.onPrimary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String imageUrl;
  final int index;
  final double height;
  final String heroTag;

  const _ProductImage({
    required this.imageUrl,
    required this.index,
    required this.height,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: SizedBox(
        key: ValueKey<int>(index),
        height: height,
        width: double.infinity,
        child: InteractiveViewer(
          maxScale: 4.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Hero(
              tag: heroTag,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                memCacheHeight:
                    (context.height * context.mediaQuery.devicePixelRatio)
                        .toInt(),
                errorWidget: (context, url, error) => Icon(
                  Icons.image_not_supported,
                  size: 60,
                  color: context.colors.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  final String label;
  final dynamic baseValue;
  final dynamic currentValue;
  final String unit;

  const _CompareCard({
    required this.label,
    required this.baseValue,
    required this.currentValue,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textColor = colors.primary;

    final v1 = double.tryParse(baseValue?.toString() ?? '0') ?? 0;
    final v2 = double.tryParse(currentValue?.toString() ?? '0') ?? 0;
    final maxVal = (v1 > v2 ? v1 : v2);
    final safeMax = maxVal == 0 ? 1.0 : maxVal;

    final p1 = (v1 / safeMax).clamp(0.0, 1.0);
    final p2 = (v2 / safeMax).clamp(0.0, 1.0);

    final isDiff = v1 != v2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(15),
        border: isDiff
            ? Border.all(color: colors.primary.withValues(alpha: 0.1))
            : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(unit, style: context.bodySmall?.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          _Bar(
            value: v1,
            percent: p1,
            color: colors.error,
            label: context.l10n.translate('comparison_base'),
            labelColor: colors.error,
          ),
          const SizedBox(height: 8),
          _Bar(
            value: v2,
            percent: p2,
            color: colors.primary,
            label: context.l10n.translate('comparison_current'),
            labelColor: colors.primary,
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;
  final double percent;
  final Color color;
  final String label;
  final Color? labelColor;

  const _Bar({
    required this.value,
    required this.percent,
    required this.color,
    required this.label,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: labelColor ?? colors.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 20,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            value.toStringAsFixed(1),
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
