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
  String _selectedFlowUnit = 'mh';
  String _selectedHeadUnit = 'm';

  final TextEditingController _flowController = TextEditingController();
  final TextEditingController _headController = TextEditingController();

  List<String> _applications = [];
  List<String> _models = [];
  List<String> _frequencies = [];
  List<String> _flowUnits = [];
  List<String> _headUnits = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiltersData();
    _flowController.addListener(() => setState(() {}));
    _headController.addListener(() => setState(() {}));
  }

  bool get _isFormValid {
    return _selectedApplication != null &&
        _selectedModel != null &&
        _selectedFrequency != null &&
        _flowController.text.isNotEmpty &&
        _headController.text.isNotEmpty;
  }

  Future<void> _loadFiltersData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        EbaraDataService.getApplicationsByCategory(widget.categoryId),
        EbaraDataService.getFrequencies(),
        EbaraDataService.getFlowRates(),
        EbaraDataService.getHeightGauges(),
      ]);

      if (mounted) {
        setState(() {
          _applications = (results[0] as List)
              .map((e) => e['title'].toString())
              .toList();

          _frequencies = (results[1] as List)
              .map((e) => e['value'].toString())
              .toList();

          _flowUnits = (results[2] as List)
              .map((e) => e['value'].toString())
              .toList();

          _headUnits = (results[3] as List)
              .map((e) => e['value'].toString())
              .toList();

          if (_applications.isNotEmpty) {
            _selectedApplication = _applications.first;

            _fetchModels(_selectedApplication!);
          }

          if (_frequencies.isNotEmpty) {
            _selectedFrequency = _frequencies.first;
          }

          if (_flowUnits.isNotEmpty) {
            _selectedFlowUnit = _flowUnits.first;
          }

          if (_headUnits.isNotEmpty) {
            _selectedHeadUnit = _headUnits.first;
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
    try {
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
    } catch (e) {
      debugPrint("Erro ao buscar modelos: $e");
    }
  }

  @override
  void dispose() {
    _flowController.dispose();
    _headController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
              padding: const EdgeInsets.all(20),
              child: _isLoading ? _buildSkeleton() : _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownField(
          label: AppLocalizations.of(context)!.translate('applications'),
          hint: AppLocalizations.of(context)!.translate('pick_one'),
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
        _buildDropdownField(
          label: AppLocalizations.of(context)!.translate('models'),
          hint: AppLocalizations.of(context)!.translate('pick_one'),
          value: _selectedModel,
          items: _models,
          onChanged: (val) => setState(() => _selectedModel = val),
        ),
        const SizedBox(height: 20),
        _buildFrequencySection(),
        const SizedBox(height: 20),
        _buildNumericField(
          label: AppLocalizations.of(context)!.translate('flow'),
          controller: _flowController,
          unit: _selectedFlowUnit,
          units: _flowUnits,
          onUnitChanged: (val) => setState(() => _selectedFlowUnit = val!),
        ),
        const SizedBox(height: 16),
        _buildNumericField(
          label: AppLocalizations.of(context)!.translate('manometric_head'),
          controller: _headController,
          unit: _selectedHeadUnit,
          units: _headUnits,
          onUnitChanged: (val) => setState(() => _selectedHeadUnit = val!),
        ),
        const SizedBox(height: 24),
        _buildSearchButton(),
        const SizedBox(height: 16),
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
                      child: Text(item, style: AppTextStyles.text1),
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
    required List<String> units,
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
                            value: u,
                            child: Text(
                              u,
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

  Widget _buildSearchButton() {
    final bool active = _isFormValid;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: active
            ? () {
                Navigator.pop(context, {
                  'application': _selectedApplication,
                  'line': _selectedModel,
                  'frequency': _selectedFrequency,
                  'flow_rate': _flowController.text.replaceAll(',', '.'),
                  'flow_rate_measure': _selectedFlowUnit,
                  'height_gauge': _headController.text.replaceAll(',', '.'),
                  'height_gauge_measure': _selectedHeadUnit,
                });
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
      ),
    );
  }
}
