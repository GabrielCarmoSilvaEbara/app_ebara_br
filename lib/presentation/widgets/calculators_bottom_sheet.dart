import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../theme/app_colors.dart';
import 'app_form_fields.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(l10n, theme),
          Container(
            color: theme.scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  icon: const Icon(Icons.swap_horiz),
                  text: l10n.translate('unit_converter'),
                ),
                Tab(
                  icon: const Icon(Icons.water_drop),
                  text: l10n.translate('hydraulic_calc'),
                ),
                Tab(
                  icon: const Icon(Icons.flash_on),
                  text: l10n.translate('electric_calc'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _UnitConverterTab(),
                _HydraulicCalcTab(),
                _ElectricCalcTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.translate('calculators'),
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }
}

class _UnitConverterTab extends StatefulWidget {
  const _UnitConverterTab();

  @override
  State<_UnitConverterTab> createState() => _UnitConverterTabState();
}

class _UnitConverterTabState extends State<_UnitConverterTab> {
  String _category = 'flow';
  String _fromUnit = 'm3h';
  String _toUnit = 'ls';
  final TextEditingController _valueController = TextEditingController();
  String _result = '';

  final Map<String, List<String>> _units = {
    'flow': ['m3h', 'ls', 'lmin', 'gpm'],
    'pressure': ['mca', 'bar', 'psi', 'kgfcm2'],
    'power': ['cv', 'hp', 'kw'],
  };

  void _convert() {
    final value =
        double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0;
    double base = 0;

    if (_category == 'flow') {
      if (_fromUnit == 'm3h') base = value;
      if (_fromUnit == 'ls') base = value * 3.6;
      if (_fromUnit == 'lmin') base = value * 0.06;
      if (_fromUnit == 'gpm') base = value * 0.2271;

      if (_toUnit == 'm3h') _result = base.toStringAsFixed(2);
      if (_toUnit == 'ls') _result = (base / 3.6).toStringAsFixed(2);
      if (_toUnit == 'lmin') _result = (base / 0.06).toStringAsFixed(2);
      if (_toUnit == 'gpm') _result = (base / 0.2271).toStringAsFixed(2);
    } else if (_category == 'pressure') {
      if (_fromUnit == 'mca') base = value;
      if (_fromUnit == 'bar') base = value * 10.197;
      if (_fromUnit == 'psi') base = value * 0.703;
      if (_fromUnit == 'kgfcm2') base = value * 10;

      if (_toUnit == 'mca') _result = base.toStringAsFixed(2);
      if (_toUnit == 'bar') _result = (base / 10.197).toStringAsFixed(2);
      if (_toUnit == 'psi') _result = (base / 0.703).toStringAsFixed(2);
      if (_toUnit == 'kgfcm2') _result = (base / 10).toStringAsFixed(2);
    } else if (_category == 'power') {
      if (_fromUnit == 'cv') base = value * 0.7355;
      if (_fromUnit == 'hp') base = value * 0.7457;
      if (_fromUnit == 'kw') base = value;

      if (_toUnit == 'cv') _result = (base / 0.7355).toStringAsFixed(2);
      if (_toUnit == 'hp') _result = (base / 0.7457).toStringAsFixed(2);
      if (_toUnit == 'kw') _result = base.toStringAsFixed(2);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDropdown<String>(
            label: l10n.translate('select_category'),
            value: _category,
            items: ['flow', 'pressure', 'power']
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      l10n.translate(e),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              setState(() {
                _category = val!;
                _fromUnit = _units[_category]!.first;
                _toUnit = _units[_category]![1];
                _result = '';
                _valueController.clear();
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppDropdown<String>(
                  label: 'De',
                  value: _fromUnit,
                  items: _units[_category]!
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            _getUnitLabel(e),
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() => _fromUnit = val!);
                    _convert();
                  },
                ),
              ),
              const SizedBox(width: 15),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              const SizedBox(width: 15),
              Expanded(
                child: AppDropdown<String>(
                  label: 'Para',
                  value: _toUnit,
                  items: _units[_category]!
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            _getUnitLabel(e),
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() => _toUnit = val!);
                    _convert();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: l10n.translate('input_value'),
            controller: _valueController,
            onChanged: (_) => _convert(),
          ),
          const SizedBox(height: 24),
          if (_result.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.translate('result'),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _result,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
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
}

class _HydraulicCalcTab extends StatefulWidget {
  const _HydraulicCalcTab();

  @override
  State<_HydraulicCalcTab> createState() => _HydraulicCalcTabState();
}

class _HydraulicCalcTabState extends State<_HydraulicCalcTab> {
  final _flowCtrl = TextEditingController();
  final _diamCtrl = TextEditingController();
  final _lenCtrl = TextEditingController();
  String _material = 'pvc';
  String _result = '';

  void _calculate() {
    final qm3h = double.tryParse(_flowCtrl.text.replaceAll(',', '.')) ?? 0;
    final dmm = double.tryParse(_diamCtrl.text.replaceAll(',', '.')) ?? 0;
    final L = double.tryParse(_lenCtrl.text.replaceAll(',', '.')) ?? 0;

    if (qm3h > 0 && dmm > 0 && L > 0) {
      final C = _material == 'pvc' ? 150 : 100;
      final dm = dmm / 1000.0;
      final qm3s = qm3h / 3600.0;
      final J = 10.643 * pow(qm3s, 1.852) * pow(C, -1.852) * pow(dm, -4.87);
      final totalHead = J * L;
      setState(() => _result = totalHead.toStringAsFixed(2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          AppTextField(
            label: l10n.translate('flow'),
            controller: _flowCtrl,
            suffixText: 'm³/h',
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: l10n.translate('diameter'),
            controller: _diamCtrl,
            suffixText: 'mm',
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: l10n.translate('length'),
            controller: _lenCtrl,
            suffixText: 'm',
          ),
          const SizedBox(height: 16),
          AppDropdown<String>(
            label: l10n.translate('material'),
            value: _material,
            items: [
              DropdownMenuItem(
                value: 'pvc',
                child: Text(
                  l10n.translate('pvc'),
                  style: theme.textTheme.displayMedium?.copyWith(fontSize: 14),
                ),
              ),
              DropdownMenuItem(
                value: 'iron',
                child: Text(
                  l10n.translate('iron'),
                  style: theme.textTheme.displayMedium?.copyWith(fontSize: 14),
                ),
              ),
            ],
            onChanged: (val) {
              setState(() => _material = val!);
              _calculate();
            },
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.translate('calculate'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_result.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate('head_loss'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    "$_result m.c.a",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ElectricCalcTab extends StatefulWidget {
  const _ElectricCalcTab();

  @override
  State<_ElectricCalcTab> createState() => _ElectricCalcTabState();
}

class _ElectricCalcTabState extends State<_ElectricCalcTab> {
  final _currentCtrl = TextEditingController();
  final _voltCtrl = TextEditingController(text: '380');
  final _distCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  String _result = '';
  String _pct = '';

  void _calculate() {
    final I = double.tryParse(_currentCtrl.text.replaceAll(',', '.')) ?? 0;
    final V = double.tryParse(_voltCtrl.text.replaceAll(',', '.')) ?? 0;
    final L = double.tryParse(_distCtrl.text.replaceAll(',', '.')) ?? 0;
    final S = double.tryParse(_sectionCtrl.text.replaceAll(',', '.')) ?? 0;

    if (I > 0 && V > 0 && L > 0 && S > 0) {
      final rho = 0.0172;
      final drop = (sqrt(3) * rho * L * I) / S;
      final percent = (drop / V) * 100;

      setState(() {
        _result = drop.toStringAsFixed(2);
        _pct = percent.toStringAsFixed(2);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: l10n.translate('current'),
                  controller: _currentCtrl,
                  suffixText: 'A',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppTextField(
                  label: l10n.translate('voltage'),
                  controller: _voltCtrl,
                  suffixText: 'V',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: l10n.translate('length'),
            controller: _distCtrl,
            suffixText: 'm',
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: l10n.translate('cable_section'),
            controller: _sectionCtrl,
            suffixText: 'mm²',
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.translate('calculate'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_result.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.translate('voltage_drop'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        "$_result V",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Divider(color: Colors.orange.shade200),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "%",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        "$_pct %",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: double.parse(_pct) > 4
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
