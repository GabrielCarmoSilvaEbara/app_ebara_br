import 'package:flutter/material.dart' hide MaterialType;
import 'package:provider/provider.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/widget_extensions.dart';
import '../../../core/providers/calculator_provider.dart';
import '../../../core/enums/app_enums.dart';
import '../../theme/app_dimens.dart';
import '../app_form_fields.dart';
import '../interactive_slider.dart';
import 'calculator_widgets.dart';

class HydraulicCalcTab extends StatefulWidget {
  const HydraulicCalcTab({super.key});

  @override
  State<HydraulicCalcTab> createState() => _HydraulicCalcTabState();
}

class _HydraulicCalcTabState extends State<HydraulicCalcTab> {
  final _flowCtrl = TextEditingController();
  final _diamCtrl = TextEditingController();
  final _lenCtrl = TextEditingController();

  @override
  void dispose() {
    _flowCtrl.dispose();
    _diamCtrl.dispose();
    _lenCtrl.dispose();
    super.dispose();
  }

  void _recalc(BuildContext context) {
    context.read<CalculatorProvider>().calculateHydraulic(
      _flowCtrl.text,
      _diamCtrl.text,
      _lenCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CalculatorProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Column(
        children: [
          InteractiveSliderInput(
            label: context.l10n.translate('flow'),
            controller: _flowCtrl,
            suffix: 'm³/h',
            max: 200,
            onChanged: () => _recalc(context),
          ),
          AppDimens.md.vGap,
          InteractiveSliderInput(
            label: context.l10n.translate('diameter'),
            controller: _diamCtrl,
            suffix: 'mm',
            max: 300,
            onChanged: () => _recalc(context),
          ),
          AppDimens.md.vGap,
          InteractiveSliderInput(
            label: context.l10n.translate('length'),
            controller: _lenCtrl,
            suffix: 'm',
            max: 1000,
            onChanged: () => _recalc(context),
          ),
          AppDimens.md.vGap,
          Selector<CalculatorProvider, MaterialType>(
            selector: (_, p) => p.material,
            builder: (context, material, _) {
              return AppDropdown<MaterialType>(
                label: context.l10n.translate('material'),
                value: material,
                items: MaterialType.values.map((e) {
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
                    provider.updateMaterial(val);
                    _recalc(context);
                  }
                },
              );
            },
          ),
          const SizedBox(height: AppDimens.radiusXxl),
          Selector<CalculatorProvider, double>(
            selector: (_, p) => p.hydraulicResult,
            builder: (context, result, _) {
              return AnimatedGauge(
                label: context.l10n.translate('head_loss'),
                value: result,
                max: 50,
                unit: 'm.c.a',
              );
            },
          ),
        ],
      ),
    );
  }
}
