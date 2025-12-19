import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../core/services/translation_service.dart';
import '../../core/utils/parse_util.dart';
import '../../core/utils/file_type_util.dart';
import '../../core/services/ebara_data_service.dart';
import '../widgets/files_skeleton.dart';

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

class _ProductDetailsPageState extends State<ProductDetailsPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _comparisonBaseIndex = 0;
  final PageController _pageController = PageController();
  late Future<Map<String, dynamic>?> _descriptionsFuture;
  late Future<List<Map<String, dynamic>>> _applicationsFuture;
  late Future<List<Map<String, dynamic>>> _filesFuture;
  late String _productId;

  @override
  void initState() {
    super.initState();
    final int langId = TranslationService.getLanguageId();

    _productId = widget.variants.first['id_product'].toString();
    _descriptionsFuture = EbaraDataService.getProductDescriptions(
      _productId,
      idLanguage: langId,
    );
    _applicationsFuture = EbaraDataService.getProductApplications(
      _productId,
      idLanguage: langId,
    );
    _filesFuture = EbaraDataService.getProductFiles(
      _productId,
      idLanguage: langId,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _changeVariant(int index) {
    if (index < 0 || index >= widget.variants.length) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool get _canGoBack => _currentIndex > 0;
  bool get _canGoForward => _currentIndex < widget.variants.length - 1;
  bool get _hasMultipleVariants => widget.variants.length > 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 25),
            _buildHeader(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: widget.variants.length,
                itemBuilder: (context, index) {
                  final variant = widget.variants[index];
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildHeroImageSection(
                          variant['image'],
                          variant['ecommerce_link'],
                        ),
                        const SizedBox(height: 20),
                        _buildInfoContent(variant),
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _BackButton(onPressed: () => Navigator.pop(context)),
          Expanded(
            child: Text(
              TranslationService.translate(widget.category).toUpperCase(),
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
            current: _currentIndex + 1,
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

  Widget _buildHeroImageSection(String imageUrl, String? ecommerceLink) {
    final isBase = _currentIndex == _comparisonBaseIndex;
    final bool isEcommerceEnabled =
        ecommerceLink != null && ecommerceLink.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          _ProductImage(imageUrl: imageUrl, index: _currentIndex, height: 220),

          Positioned(
            top: 10,
            left: 10,
            child: _EcommerceButton(
              isEnabled: isEcommerceEnabled,
              onTap: isEcommerceEnabled
                  ? () => _launchEcommerce(ecommerceLink)
                  : null,
            ),
          ),

          Positioned(
            top: 10,
            right: 10,
            child: _PinButton(
              isActive: isBase,
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => _comparisonBaseIndex = _currentIndex);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoContent(Map<String, dynamic> variantData) {
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
          _ProductHeader(
            name: variantData['name'],
            model: variantData['model'],
          ),
          const SizedBox(height: 10),
          _SectionTitle(TranslationService.translate("Aplicações")),
          const SizedBox(height: 15),
          _ApplicationIcons(applicationsFuture: _applicationsFuture),
          _SectionTitle(TranslationService.translate("Ficha Técnica")),
          const SizedBox(height: 15),
          _TechnicalSpecs(data: variantData),

          FutureBuilder<Map<String, dynamic>?>(
            future: _descriptionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const FilesSkeleton();
              }

              final desc = snapshot.data;
              if (desc == null) return const SizedBox.shrink();

              return Column(
                children: [
                  _CollapsibleSection(
                    title: TranslationService.translate("Características"),
                    items: desc['description'] as List<String>,
                  ),
                  _CollapsibleSection(
                    title: TranslationService.translate("Especificações"),
                    items: desc['specifications'] as List<String>,
                  ),
                  _CollapsibleSection(
                    title: TranslationService.translate("Opções"),
                    items: desc['options'] as List<String>,
                  ),
                ],
              );
            },
          ),

          _FilesSection(filesFuture: _filesFuture),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
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
            isEnabled: _canGoBack,
            onTap: _canGoBack ? () => _changeVariant(_currentIndex - 1) : null,
          ),
          _ComparisonButton(
            isEnabled: _hasMultipleVariants,
            onTap: _hasMultipleVariants ? _showComparisonSheet : null,
          ),
          _NavigationButton(
            icon: Icons.arrow_forward_ios_rounded,
            isEnabled: _canGoForward,
            onTap: _canGoForward
                ? () => _changeVariant(_currentIndex + 1)
                : null,
          ),
        ],
      ),
    );
  }

  void _showComparisonSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ComparisonSheet(
        base: widget.variants[_comparisonBaseIndex],
        current: widget.variants[_currentIndex],
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
          label: TranslationService.translate('power'),
          value: "${ParseUtil.formatValue(data['power'])} CV",
        ),
        _TechTile(
          label: TranslationService.translate('rotation'),
          value: "${data['rpm'] ?? '---'} RPM",
        ),
        _TechTile(
          label: TranslationService.translate('max_pressure'),
          value: "${ParseUtil.formatValue(data['mca_max'])} MCA",
        ),
        _TechTile(
          label: TranslationService.translate('max_flow'),
          value: "${ParseUtil.formatValue(data['rate_max'])} m³/h",
        ),
        _TechTile(
          label: TranslationService.translate('frequency'),
          value: "${data['frequency'] ?? '---'} Hz",
        ),
      ],
    );
  }
}

class _FilesSection extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> filesFuture;
  const _FilesSection({required this.filesFuture});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: _SectionTitle(TranslationService.translate("Documentos")),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.primary,
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: filesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const FilesSkeleton();
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    TranslationService.translate("Nenhum documento disponível"),
                    style: AppTextStyles.text4.copyWith(color: Colors.grey),
                  ),
                );
              }
              final files = snapshot.data!;
              return Column(
                children: files.map((file) {
                  return _FileLinkItem(file: file);
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _FileLinkItem extends StatelessWidget {
  final Map<String, dynamic> file;

  const _FileLinkItem({required this.file});

  Future<void> _openLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String fileUrl = file['full_url'];

    return GestureDetector(
      onTap: () => _openLink(fileUrl),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file['name'],
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.text4.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
        title: _SectionTitle(title),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.primary,
        children: [
          Column(
            children: items
                .map((text) => _FormattedItemTile(text: text))
                .toList(),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _FormattedItemTile extends StatelessWidget {
  final String text;
  const _FormattedItemTile({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BackButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
      style: IconButton.styleFrom(backgroundColor: AppColors.primary),
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
  const _ProductImage({
    required this.imageUrl,
    required this.index,
    required this.height,
  });
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Container(
        key: ValueKey<int>(index),
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Image.network(imageUrl, fit: BoxFit.contain),
      ),
    );
  }
}

class _PinButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _PinButton({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: isActive ? 0.5 : 0.1),
            width: 1.5,
          ),
        ),
        child: Icon(
          isActive ? Icons.push_pin : Icons.push_pin_outlined,
          color: AppColors.primary.withValues(alpha: isActive ? 1.0 : 0.4),
          size: 20,
        ),
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  final String name;
  final String model;
  const _ProductHeader({required this.name, required this.model});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            name,
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
          model,
          style: AppTextStyles.text3.copyWith(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _ApplicationIcons extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> applicationsFuture;

  const _ApplicationIcons({required this.applicationsFuture});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: applicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Wrap(
              spacing: 12,
              children: List.generate(4, (index) => _buildSkeletonIcon()),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }

          final apps = snapshot.data!;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: apps.map((app) {
              final String name = app['application_name'] ?? '';
              final String iconFile = app['icon_file'] ?? '';
              final String fullUrl =
                  "https://ebara.com.br/userfiles/aplicacoes/$iconFile";

              return Tooltip(
                message: name,
                triggerMode: TooltipTriggerMode.longPress,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
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
                      ? Image.network(
                          fullUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.image_not_supported_outlined,
                            size: 20,
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        )
                      : Icon(Icons.apps, color: AppColors.primary),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _EcommerceButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback? onTap;

  const _EcommerceButton({required this.isEnabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.monetization_on_outlined,
          color: isEnabled
              ? AppColors.primary
              : Colors.grey.withValues(alpha: 0.5),
          size: 20,
        ),
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
            TranslationService.translate('technical_comparison'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _CompareCard(
                  label: TranslationService.translate('power'),
                  baseValue: base['power'],
                  currentValue: current['power'],
                  unit: "CV",
                ),
                _CompareCard(
                  label: TranslationService.translate('max_pressure'),
                  baseValue: base['mca_max'],
                  currentValue: current['mca_max'],
                  unit: "MCA",
                ),
                _CompareCard(
                  label: TranslationService.translate('max_flow'),
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
