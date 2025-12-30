import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/calculator_util.dart';
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
    final bottomInset = context.mediaQuery.viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      constraints: BoxConstraints(maxHeight: context.height * 0.90),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Container(
            color: context.theme.scaffoldBackgroundColor,
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

  Widget _buildHeader() {
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
            context.l10n.translate('calculators'),
            style: context.textTheme.displayLarge?.copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }
}

class InteractiveSliderInput extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String suffix;
  final double min;
  final double max;
  final VoidCallback onChanged;

  const InteractiveSliderInput({
    super.key,
    required this.label,
    required this.controller,
    required this.suffix,
    this.min = 0,
    this.max = 100,
    required this.onChanged,
  });

  @override
  State<InteractiveSliderInput> createState() => _InteractiveSliderInputState();
}

class _InteractiveSliderInputState extends State<InteractiveSliderInput> {
  double _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _currentValue = double.tryParse(widget.controller.text) ?? 0;
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    final val =
        double.tryParse(widget.controller.text.replaceAll(',', '.')) ?? 0;
    if (val != _currentValue) {
      setState(() {
        _currentValue = val.clamp(widget.min, widget.max);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: context.textTheme.displayMedium?.copyWith(fontSize: 14),
            ),
            Text(
              "${_currentValue.toStringAsFixed(1)} ${widget.suffix}",
              style: context.textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withValues(alpha: 0.1),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.1),
            trackHeight: 4,
          ),
          child: Slider(
            value: _currentValue,
            min: widget.min,
            max: widget.max,
            onChanged: (val) {
              setState(() => _currentValue = val);
              widget.controller.text = val.toStringAsFixed(1);
              widget.onChanged();
            },
          ),
        ),
        AppTextField(
          controller: widget.controller,
          suffixText: widget.suffix,
          onChanged: (_) => widget.onChanged(),
        ),
      ],
    );
  }
}

class AnimatedGauge extends StatelessWidget {
  final double value;
  final double max;
  final String label;
  final String unit;
  final Color color;

  const AnimatedGauge({
    super.key,
    required this.value,
    this.max = 100,
    required this.label,
    required this.unit,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value / max).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: context.textTheme.displayMedium?.copyWith(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 120,
            width: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1.0,
                  color: Colors.grey.withValues(alpha: 0.1),
                  strokeWidth: 10,
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percentage),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, _) {
                    return CircularProgressIndicator(
                      value: val,
                      color: color,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value.toStringAsFixed(2),
                        style: context.textTheme.displayLarge?.copyWith(
                          fontSize: 24,
                          color: color,
                        ),
                      ),
                      Text(
                        unit,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
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

    if (_category == 'flow') {
      _result = CalculatorUtil.convertFlow(value, _fromUnit, _toUnit);
    } else if (_category == 'pressure') {
      _result = CalculatorUtil.convertPressure(value, _fromUnit, _toUnit);
    } else if (_category == 'power') {
      _result = CalculatorUtil.convertPower(value, _fromUnit, _toUnit);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDropdown<String>(
            label: context.l10n.translate('select_category'),
            value: _category,
            items: ['flow', 'pressure', 'power']
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      context.l10n.translate(e),
                      style: context.textTheme.displayMedium?.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _category = val;
                  _fromUnit = _units[_category]!.first;
                  _toUnit = _units[_category]![1];
                  _result = '';
                  _valueController.clear();
                });
              }
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
                            style: context.textTheme.displayMedium?.copyWith(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _fromUnit = val);
                      _convert();
                    }
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
                            style: context.textTheme.displayMedium?.copyWith(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _toUnit = val);
                      _convert();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InteractiveSliderInput(
            label: context.l10n.translate('input_value'),
            controller: _valueController,
            suffix: _getUnitLabel(_fromUnit),
            max: 500,
            onChanged: _convert,
          ),
          const SizedBox(height: 24),
          if (_result.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    context.l10n.translate('result'),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$_result ${_getUnitLabel(_toUnit)}",
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
  double _result = 0;

  void _calculate() {
    final flow = double.tryParse(_flowCtrl.text.replaceAll(',', '.')) ?? 0;
    final diam = double.tryParse(_diamCtrl.text.replaceAll(',', '.')) ?? 0;
    final len = double.tryParse(_lenCtrl.text.replaceAll(',', '.')) ?? 0;

    final loss = CalculatorUtil.calculateHydraulicHeadLoss(
      flowM3h: flow,
      diameterMm: diam,
      lengthM: len,
      material: _material,
    );

    setState(() => _result = loss);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          InteractiveSliderInput(
            label: context.l10n.translate('flow'),
            controller: _flowCtrl,
            suffix: 'm³/h',
            max: 200,
            onChanged: _calculate,
          ),
          const SizedBox(height: 16),
          InteractiveSliderInput(
            label: context.l10n.translate('diameter'),
            controller: _diamCtrl,
            suffix: 'mm',
            max: 300,
            onChanged: _calculate,
          ),
          const SizedBox(height: 16),
          InteractiveSliderInput(
            label: context.l10n.translate('length'),
            controller: _lenCtrl,
            suffix: 'm',
            max: 1000,
            onChanged: _calculate,
          ),
          const SizedBox(height: 16),
          AppDropdown<String>(
            label: context.l10n.translate('material'),
            value: _material,
            items: [
              DropdownMenuItem(
                value: 'pvc',
                child: Text(
                  context.l10n.translate('pvc'),
                  style: context.textTheme.displayMedium?.copyWith(
                    fontSize: 14,
                  ),
                ),
              ),
              DropdownMenuItem(
                value: 'iron',
                child: Text(
                  context.l10n.translate('iron'),
                  style: context.textTheme.displayMedium?.copyWith(
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _material = val);
                _calculate();
              }
            },
          ),
          const SizedBox(height: 30),
          AnimatedGauge(
            label: context.l10n.translate('head_loss'),
            value: _result,
            max: 50,
            unit: 'm.c.a',
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
  double _result = 0;
  String _pct = '0.00';

  void _calculate() {
    final i = double.tryParse(_currentCtrl.text.replaceAll(',', '.')) ?? 0;
    final v = double.tryParse(_voltCtrl.text.replaceAll(',', '.')) ?? 0;
    final l = double.tryParse(_distCtrl.text.replaceAll(',', '.')) ?? 0;
    final s = double.tryParse(_sectionCtrl.text.replaceAll(',', '.')) ?? 0;

    final res = CalculatorUtil.calculateVoltageDrop(
      current: i,
      voltage: v,
      length: l,
      section: s,
    );

    setState(() {
      _result = double.tryParse(res['drop']!) ?? 0;
      _pct = res['percent']!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InteractiveSliderInput(
                  label: context.l10n.translate('current'),
                  controller: _currentCtrl,
                  suffix: 'A',
                  max: 100,
                  onChanged: _calculate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InteractiveSliderInput(
                  label: context.l10n.translate('voltage'),
                  controller: _voltCtrl,
                  suffix: 'V',
                  max: 500,
                  onChanged: _calculate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InteractiveSliderInput(
            label: context.l10n.translate('length'),
            controller: _distCtrl,
            suffix: 'm',
            max: 500,
            onChanged: _calculate,
          ),
          const SizedBox(height: 16),
          InteractiveSliderInput(
            label: context.l10n.translate('cable_section'),
            controller: _sectionCtrl,
            suffix: 'mm²',
            max: 120,
            onChanged: _calculate,
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: AnimatedGauge(
                  label: context.l10n.translate('voltage_drop'),
                  value: _result,
                  max: 50,
                  unit: 'V',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Container(
                  height: 180,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "%",
                        style: context.textTheme.displayMedium?.copyWith(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "$_pct%",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: double.tryParse(_pct)! > 4
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
