import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../core/services/ebara_data_service.dart';
import '../../core/localization/app_localizations.dart';

class FiltersBottomSheet extends StatefulWidget {
  final String categoryId;

  const FiltersBottomSheet({super.key, required this.categoryId});

  @override
  State<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<FiltersBottomSheet> {
  String? _selectedApplication;
  String? _selectedModel;
  String? _selectedFrequency;
  String? _selectedSystemType;
  String? _selectedWellDiameter;

  String _activationType = 'pressostato';

  final List<String> _activationOptions = ['pressostato', 'inversor'];

  String _selectedFlowUnit = 'm3/h';
  String _selectedHeadUnit = 'm';

  final TextEditingController _flowController = TextEditingController();
  final TextEditingController _headController = TextEditingController();
  final TextEditingController _cableLengthController = TextEditingController();
  final TextEditingController _bombsQuantityController = TextEditingController(
    text: '1',
  );

  List<String> _applications = [];
  List<String> _models = [];
  List<String> _frequencies = [];

  List<Map<String, dynamic>> _flowUnits = [];
  List<Map<String, dynamic>> _headUnits = [];

  List<Map<String, dynamic>> _systemTypes = [];
  List<String> _wellDiameters = [];

  bool _isLoading = true;

  bool get _isSolar => widget.categoryId == '26';
  bool get _isSubmersible => widget.categoryId == '23';
  bool get _isPressurizer =>
      widget.categoryId == '27' ||
      widget.categoryId == 'sistemas-de-pressurizacao-1';

  @override
  void initState() {
    super.initState();
    _loadFiltersData();
  }

  bool get _isFormValid {
    final basicValid =
        _selectedApplication != null &&
        _selectedModel != null &&
        _flowController.text.isNotEmpty &&
        _headController.text.isNotEmpty;

    if (_isPressurizer) {
      if (_activationType == 'inversor') {
        return basicValid && _bombsQuantityController.text.isNotEmpty;
      }
      return basicValid;
    }

    if (_isSolar) {
      return basicValid;
    }

    return basicValid && _selectedFrequency != null;
  }

  Future<void> _loadFiltersData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final baseFutures = [
        EbaraDataService.getApplicationsByCategory(widget.categoryId),
        EbaraDataService.getFrequencies(),
        EbaraDataService.getFlowRates(),
        EbaraDataService.getHeightGauges(),
      ];

      Future<List<Map<String, dynamic>>>? systemTypesFuture;
      Future<List<String>>? wellDiametersFuture;

      if (_isSolar) {
        systemTypesFuture = EbaraDataService.getSystemTypes();
      }

      if (_isSolar || _isSubmersible) {
        wellDiametersFuture = EbaraDataService.getWellDiameters();
      }

      final results = await Future.wait(baseFutures);

      final systemTypes = systemTypesFuture != null
          ? await systemTypesFuture
          : <Map<String, dynamic>>[];
      final wellDiametersRaw = wellDiametersFuture != null
          ? await wellDiametersFuture
          : <String>[];

      if (mounted) {
        setState(() {
          _applications = (results[0] as List)
              .map((e) => e['title'].toString())
              .toList();
          _frequencies = (results[1] as List)
              .map((e) => e['value'].toString())
              .toList();

          _flowUnits = (results[2] as List)
              .where((e) {
                if (!_isSolar && e['value'].toString() == 'md') {
                  return false;
                }
                return true;
              })
              .map(
                (e) => {
                  'value': e['value'].toString(),
                  'title': e['label'].toString(),
                },
              )
              .toList();

          _headUnits = (results[3] as List)
              .map(
                (e) => {
                  'value': e['value'].toString(),
                  'title': e['label'].toString(),
                },
              )
              .toList();

          _systemTypes = systemTypes;

          if (wellDiametersRaw.isNotEmpty) {
            _wellDiameters = ['0', ...wellDiametersRaw];
          } else {
            _wellDiameters = [];
          }

          if (_applications.isNotEmpty) {
            _selectedApplication = _applications.first;
            _fetchModels(_selectedApplication!);
          }

          if (_frequencies.isNotEmpty && !_isSolar && !_isPressurizer) {
            _selectedFrequency = _frequencies.first;
          }

          if (_flowUnits.isNotEmpty) {
            _selectedFlowUnit = _flowUnits.first['value'];
          }

          if (_headUnits.isNotEmpty) {
            _selectedHeadUnit = _headUnits.first['value'];
          }

          if (_systemTypes.isNotEmpty && _isSolar) {
            _selectedSystemType = _systemTypes.first['value'].toString();
          }

          if (_wellDiameters.isNotEmpty && (_isSolar || _isSubmersible)) {
            _selectedWellDiameter = _wellDiameters.first;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchModels(String application) async {
    setState(() => _selectedModel = null);
    final data = await EbaraDataService.getLines(
      widget.categoryId,
      application: application,
    );
    if (mounted) {
      setState(() {
        _models = data.map((e) => e['title_product'].toString()).toList();
        if (_models.isNotEmpty) {
          _selectedModel = _models.first;
        }
      });
    }
  }

  @override
  void dispose() {
    _flowController.dispose();
    _headController.dispose();
    _cableLengthController.dispose();
    _bombsQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _isLoading ? _buildSkeleton() : _buildContent(),
            ),
          ),
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildSearchButton(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownField(
          label: l10n.translate('applications'),
          hint: l10n.translate('pick_one'),
          value: _selectedApplication,
          items: _applications,
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedApplication = val);
              _fetchModels(val);
            }
          },
        ),
        const SizedBox(height: 16),

        if (_isSolar && _systemTypes.isNotEmpty) ...[
          _buildDynamicDropdownField(
            label: l10n.translate('system_type'),
            hint: l10n.translate('pick_one'),
            value: _selectedSystemType,
            items: _systemTypes,
            labelBuilder: (item) =>
                l10n.translate(item['label']?.toString() ?? ''),
            onChanged: (val) => setState(() => _selectedSystemType = val),
          ),
          const SizedBox(height: 16),
        ],

        _buildDropdownField(
          label: l10n.translate('models'),
          hint: l10n.translate('pick_one'),
          value: _selectedModel,
          items: _models,
          onChanged: (val) => setState(() => _selectedModel = val),
        ),
        const SizedBox(height: 20),

        if (!_isSolar && !_isPressurizer) ...[
          _buildFrequencySection(),
          const SizedBox(height: 20),
        ],

        if ((_isSolar || _isSubmersible) && _wellDiameters.isNotEmpty) ...[
          _buildDropdownField(
            label: l10n.translate('well_diameter'),
            hint: l10n.translate('pick_one'),
            value: _selectedWellDiameter,
            items: _wellDiameters,
            itemLabelBuilder: (val) => val == '0' ? l10n.translate('all') : val,
            onChanged: (val) => setState(() => _selectedWellDiameter = val),
          ),
          const SizedBox(height: 16),
        ],

        _buildNumericField(
          label: l10n.translate('flow'),
          controller: _flowController,
          unit: _selectedFlowUnit,
          units: _flowUnits,
          onUnitChanged: (val) => setState(() => _selectedFlowUnit = val!),
        ),
        const SizedBox(height: 16),

        _buildNumericField(
          label: l10n.translate('manometric_head'),
          controller: _headController,
          unit: _selectedHeadUnit,
          units: _headUnits,
          onUnitChanged: (val) => setState(() => _selectedHeadUnit = val!),
        ),
        const SizedBox(height: 16),

        if (_isSolar) ...[
          _buildSimpleNumericField(
            label: l10n.translate('cable_length'),
            controller: _cableLengthController,
          ),
          const SizedBox(height: 24),
        ],

        if (_isPressurizer) ...[
          _buildDropdownField(
            label: l10n.translate('activation_type'),
            hint: l10n.translate('pick_one'),
            value: _activationType,
            items: _activationOptions,
            itemLabelBuilder: (val) {
              final key = val == 'pressostato'
                  ? 'pressure_switch'
                  : 'frequency_inverter';
              return l10n.translate(key);
            },
            onChanged: (val) =>
                setState(() => _activationType = val ?? 'pressostato'),
          ),
          const SizedBox(height: 24),

          if (_activationType == 'inversor') ...[
            _buildSimpleNumericField(
              label: l10n.translate('pumps_quantity'),
              controller: _bombsQuantityController,
              isInteger: true,
            ),
            const SizedBox(height: 24),
          ],
        ],

        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 100, height: 14, color: Colors.grey[200]),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
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
            AppLocalizations.of(context)!.translate('filters'),
            style: AppTextStyles.text,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String Function(String)? itemLabelBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.text1.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.contains(value) ? value : null,
              hint: Text(hint, style: AppTextStyles.text4),
              icon: const Icon(Icons.unfold_more, color: AppColors.primary),
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        itemLabelBuilder != null
                            ? itemLabelBuilder(item)
                            : item,
                        style: AppTextStyles.text1,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<Map<String, dynamic>> items,
    required ValueChanged<String?> onChanged,
    required String Function(Map<String, dynamic>) labelBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.text1.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.any((i) => i['value'].toString() == value)
                  ? value
                  : null,
              hint: Text(hint, style: AppTextStyles.text4),
              icon: const Icon(Icons.unfold_more, color: AppColors.primary),
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item['value'].toString(),
                      child: Text(
                        labelBuilder(item),
                        style: AppTextStyles.text1,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('frequency'),
          style: AppTextStyles.text1.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _frequencies
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildFrequencyButton(f),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyButton(String freq) {
    final isSel = _selectedFrequency == freq;
    return InkWell(
      onTap: () => setState(() => _selectedFrequency = freq),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : Colors.white,
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            "${freq}Hz",
            style: AppTextStyles.text1.copyWith(
              color: isSel ? Colors.white : AppColors.primary,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumericField({
    required String label,
    required TextEditingController controller,
    required String unit,
    required List<Map<String, dynamic>> units,
    required ValueChanged<String?> onUnitChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.text1.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*,?\d*')),
                  ],
                  style: AppTextStyles.text1.copyWith(fontSize: 14),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    border: InputBorder.none,
                    hintText: '0,0',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: unit,
                    isDense: true,
                    items: units
                        .map(
                          (u) => DropdownMenuItem(
                            value: u['value'].toString(),
                            child: Text(
                              u['title'].toString(),
                              style: AppTextStyles.text1.copyWith(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onUnitChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleNumericField({
    required String label,
    required TextEditingController controller,
    bool isInteger = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.text1.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
            textInputAction: TextInputAction.done,
            inputFormatters: [
              isInteger
                  ? FilteringTextInputFormatter.digitsOnly
                  : FilteringTextInputFormatter.allow(RegExp(r'^\d*,?\d*')),
            ],
            style: AppTextStyles.text1.copyWith(fontSize: 14),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              border: InputBorder.none,
              hintText: '0,0',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _flowController,
          _headController,
          _cableLengthController,
          _bombsQuantityController,
        ]),
        builder: (context, child) {
          return ElevatedButton(
            onPressed: _isFormValid
                ? () {
                    final Map<String, dynamic> result = {
                      'application': _selectedApplication,
                      'line': _selectedModel,
                      'flow_rate': _flowController.text.replaceAll(',', '.'),
                      'flow_rate_measure': _selectedFlowUnit,
                      'height_gauge': _headController.text.replaceAll(',', '.'),
                      'height_gauge_measure': _selectedHeadUnit,
                    };

                    if (_isPressurizer) {
                      result['activation'] = _activationType;
                      if (_activationType == 'inversor') {
                        result['bombs_quantity'] =
                            int.tryParse(_bombsQuantityController.text) ?? 1;
                      }
                    } else if (_isSolar) {
                      result['types'] = _selectedSystemType;
                      result['cable_lenght'] = _cableLengthController.text
                          .replaceAll(',', '.');
                    } else {
                      result['frequency'] = _selectedFrequency;
                    }

                    if (_isSolar || _isSubmersible) {
                      result['well_diameter'] = _selectedWellDiameter;
                    }

                    Navigator.pop(context, result);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('search'),
              style: AppTextStyles.text2.copyWith(fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}
