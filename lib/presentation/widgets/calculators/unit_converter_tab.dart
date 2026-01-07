import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/widget_extensions.dart';
import '../../../core/providers/calculator_provider.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/parse_util.dart';
import '../../theme/app_dimens.dart';
import '../app_form_fields.dart';
import '../interactive_slider.dart';
import 'calculator_widgets.dart';

class UnitConverterTab extends StatefulWidget {
  const UnitConverterTab({super.key});

  @override
  State<UnitConverterTab> createState() => _UnitConverterTabState();
}

class _UnitConverterTabState extends State<UnitConverterTab> {
  final TextEditingController _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  String _getUnitLabel(String key) {
    switch (key) {
      case 'm3h':
        return 'm³/h';
      case 'ls':
        return 'l/s';
      case 'lmin':
        return 'l/min';
      case 'gpm':
        return 'GPM';
      case 'mca':
        return 'm.c.a';
      case 'bar':
        return 'bar';
      case 'psi':
        return 'psi';
      case 'kgfcm2':
        return 'kgf/cm²';
      case 'cv':
        return 'CV';
      case 'hp':
        return 'HP';
      case 'kw':
        return 'kW';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.read<CalculatorProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Selector<CalculatorProvider, CalcCategory>(
            selector: (_, p) => p.category,
            builder: (context, category, _) {
              return AppDropdown<CalcCategory>(
                label: context.l10n.translate('select_category'),
                value: category,
                items: CalcCategory.values.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(
                      context.l10n.translate(e.name),
                      style: context.subtitleStyle?.copyWith(
                        fontSize: AppDimens.fontLg,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    provider.updateCategory(val);
                    _valueController.clear();
                  }
                },
              );
            },
          ),
          AppDimens.md.vGap,
          Row(
            children: [
              Expanded(
                child: Consumer<CalculatorProvider>(
                  builder: (context, p, _) {
                    return _UnitSelector(
                      label: context.l10n.translate('from'),
                      value: p.fromUnit,
                      units: p.currentUnits,
                      labelBuilder: _getUnitLabel,
                      onChanged: (val) {
                        p.updateFromUnit(val!);
                        p.convert(_valueController.text);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 15),
              Icon(
                Icons.arrow_forward,
                color: colors.onSurface.withValues(
                  alpha: AppDimens.opacityHigh,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Consumer<CalculatorProvider>(
                  builder: (context, p, _) {
                    return _UnitSelector(
                      label: context.l10n.translate('to'),
                      value: p.toUnit,
                      units: p.currentUnits,
                      labelBuilder: _getUnitLabel,
                      onChanged: (val) {
                        p.updateToUnit(val!);
                        p.convert(_valueController.text);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          AppDimens.lg.vGap,
          Selector<CalculatorProvider, String>(
            selector: (_, p) => p.fromUnit,
            builder: (context, fromUnit, _) {
              return InteractiveSliderInput(
                label: context.l10n.translate('input_value'),
                controller: _valueController,
                suffix: _getUnitLabel(fromUnit),
                max: 500,
                onChanged: () => provider.convert(_valueController.text),
              );
            },
          ),
          AppDimens.xl.vGap,
          Selector<CalculatorProvider, (double, String)>(
            selector: (_, p) => (p.converterResult, p.toUnit),
            builder: (context, data, _) {
              final result = ParseUtil.formatValue(data.$1);
              final toUnit = data.$2;

              return AnimatedCopyButton(
                textToCopy: result,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimens.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primary.withValues(alpha: AppDimens.opacityLow),
                        colors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(
                      color: colors.primary.withValues(
                        alpha: AppDimens.opacityLow,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        context.l10n.translate('result'),
                        style: context.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$result ${_getUnitLabel(toUnit)}",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      AppDimens.xs.vGap,
                      Text(
                        context.l10n.translate('tap_to_copy'),
                        style: context.bodySmall?.copyWith(
                          fontSize: AppDimens.fontXs,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UnitSelector extends StatelessWidget {
  final String label;
  final String value;
  final List<String> units;
  final String Function(String) labelBuilder;
  final ValueChanged<String?> onChanged;

  const _UnitSelector({
    required this.label,
    required this.value,
    required this.units,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppDropdown<String>(
      label: label,
      value: value,
      items: units.map((e) {
        return DropdownMenuItem(
          value: e,
          child: Text(
            labelBuilder(e),
            style: context.subtitleStyle?.copyWith(fontSize: AppDimens.fontLg),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
