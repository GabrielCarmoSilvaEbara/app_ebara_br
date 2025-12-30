import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../core/services/ebara_data_service.dart';
import '../../core/localization/app_localizations.dart';
import 'app_form_fields.dart';

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
          _buildHeader(theme),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _isLoading ? _buildSkeleton(theme) : _buildContent(theme),
            ),
          ),
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildSearchButton(theme),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppDropdown<String>(
          label: l10n.translate('applications'),
          hint: l10n.translate('pick_one'),
          value: _selectedApplication,
          items: _applications
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontSize: 14,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedApplication = val);
              _fetchModels(val);
            }
          },
        ),
        const SizedBox(height: 16),

        if (_isSolar && _systemTypes.isNotEmpty) ...[
          AppDropdown<String>(
            label: l10n.translate('system_type'),
            hint: l10n.translate('pick_one'),
            value: _selectedSystemType,
            items: _systemTypes
                .map(
                  (item) => DropdownMenuItem(
                    value: item['value'].toString(),
                    child: Text(
                      l10n.translate(item['label']?.toString() ?? ''),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedSystemType = val),
          ),
          const SizedBox(height: 16),
        ],

        AppDropdown<String>(
          label: l10n.translate('models'),
          hint: l10n.translate('pick_one'),
          value: _selectedModel,
          items: _models
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontSize: 14,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _selectedModel = val),
        ),
        const SizedBox(height: 20),

        if (!_isSolar && !_isPressurizer) ...[
          _buildFrequencySection(theme),
          const SizedBox(height: 20),
        ],

        if ((_isSolar || _isSubmersible) && _wellDiameters.isNotEmpty) ...[
          AppDropdown<String>(
            label: l10n.translate('well_diameter'),
            hint: l10n.translate('pick_one'),
            value: _selectedWellDiameter,
            items: _wellDiameters
                .map(
                  (val) => DropdownMenuItem(
                    value: val,
                    child: Text(
                      val == '0' ? l10n.translate('all') : val,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedWellDiameter = val),
          ),
          const SizedBox(height: 16),
        ],

        AppNumericDropdown(
          label: l10n.translate('flow'),
          controller: _flowController,
          unitValue: _selectedFlowUnit,
          unitItems: _flowUnits,
          onUnitChanged: (val) => setState(() => _selectedFlowUnit = val!),
        ),
        const SizedBox(height: 16),

        AppNumericDropdown(
          label: l10n.translate('manometric_head'),
          controller: _headController,
          unitValue: _selectedHeadUnit,
          unitItems: _headUnits,
          onUnitChanged: (val) => setState(() => _selectedHeadUnit = val!),
        ),
        const SizedBox(height: 16),

        if (_isSolar) ...[
          AppTextField(
            label: l10n.translate('cable_length'),
            controller: _cableLengthController,
          ),
          const SizedBox(height: 24),
        ],

        if (_isPressurizer) ...[
          AppDropdown<String>(
            label: l10n.translate('activation_type'),
            hint: l10n.translate('pick_one'),
            value: _activationType,
            items: _activationOptions
                .map(
                  (val) => DropdownMenuItem(
                    value: val,
                    child: Text(
                      l10n.translate(
                        val == 'pressostato'
                            ? 'pressure_switch'
                            : 'frequency_inverter',
                      ),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) =>
                setState(() => _activationType = val ?? 'pressostato'),
          ),
          const SizedBox(height: 24),

          if (_activationType == 'inversor') ...[
            AppTextField(
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

  Widget _buildSkeleton(ThemeData theme) {
    final baseColor = theme.brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.grey.shade200;
    final containerColor = theme.brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade100;

    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 100, height: 14, color: baseColor),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
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
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('frequency'),
          style: theme.textTheme.displayMedium?.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _frequencies
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildFrequencyButton(f, theme),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyButton(String freq, ThemeData theme) {
    final isSel = _selectedFrequency == freq;
    return InkWell(
      onTap: () => setState(() => _selectedFrequency = freq),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : theme.cardColor,
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            "${freq}Hz",
            style: theme.textTheme.displayMedium?.copyWith(
              color: isSel ? Colors.white : AppColors.primary,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton(ThemeData theme) {
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
              disabledBackgroundColor: theme.disabledColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('search'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 16,
                color: _isFormValid ? Colors.white : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
