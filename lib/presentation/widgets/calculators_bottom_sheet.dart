import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/providers/calculator_provider.dart';
import '../theme/app_dimens.dart';
import 'app_modal_wrapper.dart';
import 'calculators/unit_converter_tab.dart';
import 'calculators/hydraulic_calc_tab.dart';
import 'calculators/electric_calc_tab.dart';

class CalculatorsBottomSheet extends StatefulWidget {
  const CalculatorsBottomSheet({super.key});

  @override
  State<CalculatorsBottomSheet> createState() => _CalculatorsBottomSheetState();
}

class _CalculatorsBottomSheetState extends State<CalculatorsBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ChangeNotifierProvider(
      create: (_) => CalculatorProvider(),
      child: AppModalWrapper(
        title: context.l10n.translate('calculators'),
        child: Column(
          children: [
            Container(
              color: context.theme.scaffoldBackgroundColor,
              child: TabBar(
                controller: _tabController,
                labelColor: colors.primary,
                unselectedLabelColor: colors.onSurface.withValues(
                  alpha: AppDimens.opacityHigh,
                ),
                indicatorColor: colors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.swap_horiz),
                    text: context.l10n.translate('unit_converter'),
                  ),
                  Tab(
                    icon: const Icon(Icons.water_drop),
                    text: context.l10n.translate('hydraulic_calc'),
                  ),
                  Tab(
                    icon: const Icon(Icons.flash_on),
                    text: context.l10n.translate('electric_calc'),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.outline.withValues(alpha: 0.2)),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  UnitConverterTab(),
                  HydraulicCalcTab(),
                  ElectricCalcTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
