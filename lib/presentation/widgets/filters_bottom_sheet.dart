import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class FiltersBottomSheet extends StatefulWidget {
  const FiltersBottomSheet({super.key});

  @override
  State<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<FiltersBottomSheet> {
  String? _selectedApplication;
  String? _selectedModel;
  String _selectedFrequency = '60Hz';
  String _selectedFlowUnit = 'm3/h';
  String _selectedHeadUnit = 'm3/h';
  final TextEditingController _flowController = TextEditingController(
    text: '20,5',
  );
  final TextEditingController _headController = TextEditingController(
    text: '35,1',
  );

  final List<String> _applications = [
    'Residential',
    'Industrial',
    'Agricultural',
    'Commercial',
  ];

  final List<String> _models = ['B-12 NR', 'TSW-250', 'B-10', 'TH-12'];

  final List<String> _flowUnits = ['m3/h', 'L/min', 'GPM'];
  final List<String> _headUnits = ['m3/h', 'm', 'ft'];

  @override
  void dispose() {
    _flowController.dispose();
    _headController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDropdownField(
                    label: 'Applications',
                    hint: 'Pick one',
                    value: _selectedApplication,
                    items: _applications,
                    onChanged: (value) =>
                        setState(() => _selectedApplication = value),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Models',
                    hint: 'Pick one',
                    value: _selectedModel,
                    items: _models,
                    onChanged: (value) =>
                        setState(() => _selectedModel = value),
                  ),
                  const SizedBox(height: 20),
                  _buildFrequencySection(),
                  const SizedBox(height: 20),
                  _buildNumericField(
                    label: 'Flow',
                    controller: _flowController,
                    unit: _selectedFlowUnit,
                    units: _flowUnits,
                    onUnitChanged: (value) =>
                        setState(() => _selectedFlowUnit = value!),
                  ),
                  const SizedBox(height: 16),
                  _buildNumericField(
                    label: 'Manometric Head',
                    controller: _headController,
                    unit: _selectedHeadUnit,
                    units: _headUnits,
                    onUnitChanged: (value) =>
                        setState(() => _selectedHeadUnit = value!),
                  ),
                  const SizedBox(height: 24),
                  _buildSearchButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
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
          Text('Filters', style: AppTextStyles.text),
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
              value: value,
              hint: Text(hint, style: AppTextStyles.text4),
              icon: const Icon(Icons.unfold_more, color: AppColors.primary),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item, style: AppTextStyles.text1),
                );
              }).toList(),
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
        Text('Frequency', style: AppTextStyles.text1.copyWith(fontSize: 14)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildFrequencyButton('60Hz')),
            const SizedBox(width: 12),
            Expanded(child: _buildFrequencyButton('50Hz')),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencyButton(String frequency) {
    final isSelected = _selectedFrequency == frequency;
    return InkWell(
      onTap: () => setState(() => _selectedFrequency = frequency),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.white : AppColors.primary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              frequency,
              style: AppTextStyles.text1.copyWith(
                color: isSelected ? Colors.white : AppColors.primary,
                fontSize: 14,
              ),
            ),
          ],
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
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                    hintText: '0,0',
                    hintStyle: AppTextStyles.text4,
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
                    icon: const Icon(
                      Icons.unfold_more,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    items: units.map((unitOption) {
                      return DropdownMenuItem(
                        value: unitOption,
                        child: Text(
                          unitOption,
                          style: AppTextStyles.text1.copyWith(fontSize: 14),
                        ),
                      );
                    }).toList(),
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
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context, {
            'application': _selectedApplication,
            'model': _selectedModel,
            'frequency': _selectedFrequency,
            'flow': _flowController.text,
            'flowUnit': _selectedFlowUnit,
            'head': _headController.text,
            'headUnit': _selectedHeadUnit,
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 20),
            const SizedBox(width: 8),
            Text('Search', style: AppTextStyles.text2.copyWith(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

void showFiltersBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const FiltersBottomSheet(),
  );
}
