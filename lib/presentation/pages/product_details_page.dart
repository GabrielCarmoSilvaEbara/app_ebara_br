import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/product_details_provider.dart';
import '../../core/utils/parse_util.dart';
import '../../core/utils/file_type_util.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/files_skeleton.dart';
import '../../core/providers/location_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../widgets/image_viewer.dart';

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

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProductDetailsProvider>();
    final locProvider = context.read<LocationProvider>();
    final id = widget.variants.first['id_product'];

    _pageController = PageController(initialPage: provider.currentIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.loadProductData(id, locProvider.apiLanguageId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _changeVariant(int index, ProductDetailsProvider provider) {
    if (index < 0 || index >= widget.variants.length) return;
    HapticFeedback.lightImpact();
    provider.updateIndex(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductDetailsProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 25),
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
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildHeroImageSection(v, provider),
                        const SizedBox(height: 20),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          IconButton.filled(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
          ),
          Expanded(
            child: Text(
              AppLocalizations.of(
                context,
              )!.translate(widget.category).toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTextStyles.text1.copyWith(
                color: AppColors.primary,
                letterSpacing: 1.2,
                fontSize: 13,
                fontWeight: FontWeight.bold,
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
    if (url == null || url.isEmpty) return;
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
            child: GestureDetector(
              onTap: isEcommerceEnabled
                  ? () => _launchEcommerce(ecommerceLink)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isEcommerceEnabled
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isEcommerceEnabled
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.monetization_on_outlined,
                  color: isEcommerceEnabled
                      ? AppColors.primary
                      : Colors.grey.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => provider.setComparisonBase(provider.currentIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(
                      alpha: isBase ? 0.5 : 0.1,
                    ),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isBase ? Icons.push_pin : Icons.push_pin_outlined,
                  color: AppColors.primary.withValues(
                    alpha: isBase ? 1.0 : 0.4,
                  ),
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.zoom_in,
                  color: AppColors.primary.withValues(alpha: 0.8),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoContent(
    Map<String, dynamic> variantData,
    ProductDetailsProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 30, 25, 120),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
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
                  style: AppTextStyles.text.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                variantData['model'],
                style: AppTextStyles.text3.copyWith(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (provider.isLoading)
            const FilesSkeleton()
          else ...[
            _SectionTitle(
              AppLocalizations.of(context)!.translate("Aplicações"),
            ),
            const SizedBox(height: 15),
            _ApplicationIcons(apps: provider.applications),
            _SectionTitle(
              AppLocalizations.of(context)!.translate("Ficha Técnica"),
            ),
            const SizedBox(height: 15),
            _TechnicalSpecs(data: variantData),
            if (provider.descriptions != null) ...[
              _CollapsibleSection(
                title: AppLocalizations.of(
                  context,
                )!.translate("Características"),
                items: provider.descriptions!['description'] as List<String>,
              ),
              _CollapsibleSection(
                title: AppLocalizations.of(
                  context,
                )!.translate("Especificações"),
                items: provider.descriptions!['specifications'] as List<String>,
              ),
              _CollapsibleSection(
                title: AppLocalizations.of(context)!.translate("Opções"),
                items: provider.descriptions!['options'] as List<String>,
              ),
            ],
            _FilesSection(files: provider.files),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildBottomControls(ProductDetailsProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavigationButton(
            icon: Icons.arrow_back_ios_rounded,
            isEnabled: provider.currentIndex > 0,
            onTap: provider.currentIndex > 0
                ? () => _changeVariant(provider.currentIndex - 1, provider)
                : null,
          ),
          _ComparisonButton(
            isEnabled: widget.variants.length > 1,
            onTap: widget.variants.length > 1
                ? () {
                    HapticFeedback.mediumImpact();
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => _ComparisonSheet(
                        base: widget.variants[provider.comparisonBaseIndex],
                        current: widget.variants[provider.currentIndex],
                      ),
                    );
                  }
                : null,
          ),
          _NavigationButton(
            icon: Icons.arrow_forward_ios_rounded,
            isEnabled: provider.currentIndex < widget.variants.length - 1,
            onTap: provider.currentIndex < widget.variants.length - 1
                ? () => _changeVariant(provider.currentIndex + 1, provider)
                : null,
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
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
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
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    )
                  : Icon(Icons.apps, color: AppColors.primary),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilesSection extends StatelessWidget {
  final List<Map<String, dynamic>> files;
  const _FilesSection({required this.files});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          AppLocalizations.of(context)!.translate("Documentos"),
          style: AppTextStyles.text1.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.primary,
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
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.translate("Nenhum documento disponível"),
                    style: AppTextStyles.text4.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...files.map((file) => _FileLinkItem(file: file)),
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.translate('technical_comparison'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _CompareCard(
                  label: AppLocalizations.of(context)!.translate('power'),
                  baseValue: base['power'],
                  currentValue: current['power'],
                  unit: "CV",
                ),
                _CompareCard(
                  label: AppLocalizations.of(
                    context,
                  )!.translate('max_pressure'),
                  baseValue: base['mca_max'],
                  currentValue: current['mca_max'],
                  unit: "MCA",
                ),
                _CompareCard(
                  label: AppLocalizations.of(context)!.translate('max_flow'),
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

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback? onTap;
  const _NavigationButton({
    required this.icon,
    required this.isEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled ? AppColors.primary : Colors.grey[300],
        ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 55,
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.primary : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.compare_arrows, size: 26, color: Colors.white),
      ),
    );
  }
}

class _FileLinkItem extends StatelessWidget {
  final Map<String, dynamic> file;
  const _FileLinkItem({required this.file});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final Uri uri = Uri.parse(file['full_url']);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(
              FileTypeUtil.icon(file['extension']),
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                file['name'],
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.text4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.open_in_new_rounded,
                color: AppColors.primary,
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
          label: AppLocalizations.of(context)!.translate('power'),
          value: "${ParseUtil.formatValue(data['power'])} CV",
        ),
        _TechTile(
          label: AppLocalizations.of(context)!.translate('rotation'),
          value: "${data['rpm'] ?? '---'} RPM",
        ),
        _TechTile(
          label: AppLocalizations.of(context)!.translate('max_pressure'),
          value: "${ParseUtil.formatValue(data['mca_max'])} MCA",
        ),
        _TechTile(
          label: AppLocalizations.of(context)!.translate('max_flow'),
          value: "${ParseUtil.formatValue(data['rate_max'])} m³/h",
        ),
        _TechTile(
          label: AppLocalizations.of(context)!.translate('frequency'),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.text1.copyWith(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.text4.copyWith(
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
  const _CollapsibleSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          title,
          style: AppTextStyles.text1.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.primary,
        children: [
          ...items.map(
            (text) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: AppTextStyles.text4.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.primary,
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
    return Text(
      title,
      style: AppTextStyles.text1.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
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
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$current / $total",
        style: const TextStyle(
          color: Colors.white,
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
                errorWidget: (context, url, error) => const Icon(
                  Icons.image_not_supported,
                  size: 60,
                  color: Colors.grey,
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
    final val1 = ParseUtil.formatValue(baseValue);
    final val2 = ParseUtil.formatValue(currentValue);
    final isDiff = val1 != val2;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDiff
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(15),
        border: isDiff
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Row(
            children: [
              Text(
                val1,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Icon(Icons.arrow_right_alt, size: 16, color: Colors.grey),
              Text(
                "$val2 $unit",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDiff ? AppColors.primary : Colors.black,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
