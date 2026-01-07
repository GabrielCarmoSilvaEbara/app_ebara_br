import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/widget_extensions.dart';
import '../../../core/providers/calculator_provider.dart';
import '../../../core/utils/parse_util.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_shadows.dart';
import '../interactive_slider.dart';
import 'calculator_widgets.dart';

class ElectricCalcTab extends StatefulWidget {
  const ElectricCalcTab({super.key});

  @override
  State<ElectricCalcTab> createState() => _ElectricCalcTabState();
}

class _ElectricCalcTabState extends State<ElectricCalcTab> {
  final _currentCtrl = TextEditingController();
  final _voltCtrl = TextEditingController(text: '380');
  final _distCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();

  @override
  void dispose() {
    _currentCtrl.dispose();
    _voltCtrl.dispose();
    _distCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  void _recalc(BuildContext context) {
    context.read<CalculatorProvider>().calculateElectric(
      _currentCtrl.text,
      _voltCtrl.text,
      _distCtrl.text,
      _sectionCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Column(
        children: [
          InteractiveSliderInput(
            label: context.l10n.translate('current'),
            controller: _currentCtrl,
            suffix: 'A',
            max: 100,
            onChanged: () => _recalc(context),
          ),
          AppDimens.md.vGap,
          InteractiveSliderInput(
            label: context.l10n.translate('voltage'),
            controller: _voltCtrl,
            suffix: 'V',
            max: 500,
            onChanged: () => _recalc(context),
          ),
          AppDimens.md.vGap,
          InteractiveSliderInput(
            label: context.l10n.translate('length'),
            controller: _distCtrl,
            suffix: 'm',
            max: 500,
            onChanged: () => _recalc(context),
          ),
          AppDimens.md.vGap,
          InteractiveSliderInput(
            label: context.l10n.translate('cable_section'),
            controller: _sectionCtrl,
            suffix: 'mm²',
            max: 120,
            onChanged: () => _recalc(context),
          ),
          const SizedBox(height: AppDimens.radiusXxl),
          Row(
            children: [
              Expanded(
                child: Selector<CalculatorProvider, double>(
                  selector: (_, p) => p.voltageDropResult,
                  builder: (context, drop, _) {
                    return AnimatedGauge(
                      label: context.l10n.translate('voltage_drop'),
                      value: drop,
                      max: 50,
                      unit: 'V',
                      color: Colors.orange,
                    );
                  },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Consumer<CalculatorProvider>(
                  builder: (context, p, _) {
                    return Container(
                      height: 180,
                      padding: const EdgeInsets.all(AppDimens.lg),
                      decoration: BoxDecoration(
                        color: context.theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppShadows.sm(context.colors.shadow),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "%",
                            style: context.subtitleStyle?.copyWith(
                              fontSize: AppDimens.fontLg,
                              color: context.colors.onSurface.withValues(
                                alpha: AppDimens.opacityHigh,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimens.gridSpacing),
                          Text(
                            "${ParseUtil.formatValue(p.voltagePercent)}%",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: p.isVoltageDropCritical
                                  ? context.colors.error
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
