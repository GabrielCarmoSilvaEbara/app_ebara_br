import 'package:flutter/material.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/extensions/widget_extensions.dart';
import '../../../../../core/models/product_model.dart';
import '../../theme/app_dimens.dart';
import '../app_modal_wrapper.dart';

class ComparisonSheet extends StatelessWidget {
  final ProductModel base;
  final ProductModel current;

  const ComparisonSheet({super.key, required this.base, required this.current});

  @override
  Widget build(BuildContext context) {
    return AppModalWrapper(
      title: context.l10n.translate('technical_comparison'),
      maxHeightFactor: AppDimens.modalHeightMd,
      child: ListView(
        padding: const EdgeInsets.all(AppDimens.lg),
        children: [
          ComparisonItem(
            label: context.l10n.translate('power'),
            baseValue: base.power,
            currentValue: current.power,
            unit: "CV",
          ),
          ComparisonItem(
            label: context.l10n.translate('max_pressure'),
            baseValue: base.mcaMax,
            currentValue: current.mcaMax,
            unit: "MCA",
          ),
          ComparisonItem(
            label: context.l10n.translate('max_flow'),
            baseValue: base.rateMax,
            currentValue: current.rateMax,
            unit: "m³/h",
          ),
        ],
      ),
    );
  }
}

class ComparisonItem extends StatelessWidget {
  final String label;
  final double baseValue;
  final double currentValue;
  final String unit;

  const ComparisonItem({
    super.key,
    required this.label,
    required this.baseValue,
    required this.currentValue,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final maxVal = (baseValue > currentValue ? baseValue : currentValue);
    final safeMax = maxVal == 0 ? 1.0 : maxVal;

    final p1 = (baseValue / safeMax).clamp(0.0, 1.0);
    final p2 = (currentValue / safeMax).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.sm),
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: baseValue != currentValue
            ? Border.all(
                color: colors.primary..withValues(alpha: AppDimens.opacityLow),
              )
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
                  color: colors.primary,
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
          StatBar(
            value: baseValue,
            percent: p1,
            color: colors.error,
            label: context.l10n.translate('comparison_base'),
            labelColor: colors.error,
          ),
          AppDimens.xs.vGap,
          StatBar(
            value: currentValue,
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

class StatBar extends StatelessWidget {
  final double value;
  final double percent;
  final Color color;
  final String label;
  final Color? labelColor;

  const StatBar({
    super.key,
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
          width: AppDimens.xxxxl,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppDimens.fontXs,
              color: labelColor ?? context.colors.onSurface
                ..withValues(alpha: AppDimens.opacityHigh),
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
                  color: context.colors.onSurface
                    ..withValues(alpha: AppDimens.opacityLow),
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
