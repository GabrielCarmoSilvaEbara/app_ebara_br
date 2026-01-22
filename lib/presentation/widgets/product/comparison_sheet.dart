import 'package:flutter/material.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/extensions/widget_extensions.dart';
import '../../../../../core/models/product_model.dart';
import '../../theme/app_dimens.dart';
import '../app_modal_wrapper.dart';

class ComparisonSheet extends StatefulWidget {
  final List<ProductModel> variants;

  const ComparisonSheet({super.key, required this.variants});

  @override
  State<ComparisonSheet> createState() => _ComparisonSheetState();
}

class _ComparisonSheetState extends State<ComparisonSheet> {
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    if (widget.variants.isNotEmpty) {
      _selectedIndices.add(0);
      if (widget.variants.length > 1) {
        _selectedIndices.add(1);
      }
    }
  }

  void _toggleVariant(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        if (_selectedIndices.length > 1) {
          _selectedIndices.remove(index);
        }
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppModalWrapper(
      title: context.l10n.translate('technical_comparison'),
      maxHeightFactor: AppDimens.modalHeightLg,
      backgroundColor: colors.surface,
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
              scrollDirection: Axis.horizontal,
              itemCount: widget.variants.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppDimens.sm),
              itemBuilder: (context, index) {
                final isSelected = _selectedIndices.contains(index);
                return Center(
                  child: FilterChip(
                    label: Text(
                      "${context.l10n.translate('variation')} ${index + 1}",
                    ),
                    selected: isSelected,
                    onSelected: (_) => _toggleVariant(index),
                    backgroundColor: colors.surfaceContainer,
                    selectedColor: colors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? colors.onPrimary : colors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    checkmarkColor: colors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                      side: BorderSide(
                        color: isSelected
                            ? colors.primary
                            : colors.surfaceContainer,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimens.lg),
              children: [
                _MultiComparisonItem(
                  label: context.l10n.translate('power'),
                  unit: "CV",
                  variants: widget.variants,
                  selectedIndices: _selectedIndices,
                  valueGetter: (p) => p.power,
                ),
                _MultiComparisonItem(
                  label: context.l10n.translate('rotation'),
                  unit: "RPM",
                  variants: widget.variants,
                  selectedIndices: _selectedIndices,
                  valueGetter: (p) => p.rpm,
                ),
                _MultiComparisonItem(
                  label: context.l10n.translate('max_pressure'),
                  unit: "MCA",
                  variants: widget.variants,
                  selectedIndices: _selectedIndices,
                  valueGetter: (p) => p.mcaMax,
                ),
                _MultiComparisonItem(
                  label: context.l10n.translate('max_flow'),
                  unit: "m³/h",
                  variants: widget.variants,
                  selectedIndices: _selectedIndices,
                  valueGetter: (p) => p.rateMax,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiComparisonItem extends StatelessWidget {
  final String label;
  final String unit;
  final List<ProductModel> variants;
  final Set<int> selectedIndices;
  final double Function(ProductModel) valueGetter;

  const _MultiComparisonItem({
    required this.label,
    required this.unit,
    required this.variants,
    required this.selectedIndices,
    required this.valueGetter,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.theme.brightness == Brightness.dark;
    final textColor = isDark ? colors.onPrimary : colors.primary;

    double maxValue = 0.0;
    final sortedIndices = selectedIndices.toList()..sort();

    for (final idx in sortedIndices) {
      final val = valueGetter(variants[idx]);
      if (val > maxValue) maxValue = val;
    }
    if (maxValue == 0) maxValue = 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.md),
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: AppDimens.fontMd,
                ),
              ),
              Text(
                unit,
                style: context.bodySmall?.copyWith(fontSize: AppDimens.fontXs),
              ),
            ],
          ),
          AppDimens.sm.vGap,
          ...sortedIndices.map((index) {
            final val = valueGetter(variants[index]);
            final percent = (val / maxValue).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _StatBar(
                value: val,
                percent: percent,
                color: colors.primary,
                label: "${context.l10n.translate('variation')} ${index + 1}",
                labelColor: colors.onSurface.withValues(alpha: 0.7),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final double value;
  final double percent;
  final Color color;
  final String label;
  final Color? labelColor;

  const _StatBar({
    required this.value,
    required this.percent,
    required this.color,
    required this.label,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppDimens.fontXs,
              color: labelColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: AppDimens.lg,
                decoration: BoxDecoration(
                  color: context.colors.onSurface.withValues(
                    alpha: AppDimens.opacityLow,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  height: AppDimens.lg,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        AppDimens.xs.hGap,
        SizedBox(
          width: 50,
          child: Text(
            value.toStringAsFixed(1),
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppDimens.fontSm,
            ),
          ),
        ),
      ],
    );
  }
}
