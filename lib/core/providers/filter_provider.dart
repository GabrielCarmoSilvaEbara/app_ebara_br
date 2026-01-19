import 'package:flutter/material.dart';
import '../services/ebara_data_service.dart';
import '../constants/app_constants.dart';
import '../enums/app_enums.dart';
import '../utils/parse_util.dart';

class FilterProvider with ChangeNotifier {
  final EbaraDataService _dataService;

  bool _isLoading = true;
  String _currentCategoryId = '';

  List<Map<String, dynamic>> _applications = [];
  List<Map<String, dynamic>> _models = [];
  List<String> _frequencies = [];
  List<Map<String, dynamic>> _systemTypes = [];
  List<String> _wellDiameters = [];
  List<Map<String, dynamic>> _flowUnits = [];
  List<Map<String, dynamic>> _headUnits = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get applications => _applications;
  List<Map<String, dynamic>> get models => _models;
  List<String> get frequencies => _frequencies;
  List<Map<String, dynamic>> get systemTypes => _systemTypes;
  List<String> get wellDiameters => _wellDiameters;
  List<Map<String, dynamic>> get flowUnits => _flowUnits;
  List<Map<String, dynamic>> get headUnits => _headUnits;

  String? selectedApplication;
  String? selectedModel;
  String? selectedFrequency;
  String? selectedSystemType;
  String? selectedWellDiameter;
  String activationType = ActivationType.pressostato.name;
  String selectedFlowUnit = SystemConstants.defaultFlowMeasure;
  String selectedHeadUnit = SystemConstants.defaultHeadMeasure;

  FilterProvider({required EbaraDataService dataService})
    : _dataService = dataService;

  Future<void> loadFiltersData(String categoryId) async {
    _isLoading = true;
    _currentCategoryId = categoryId;
    notifyListeners();

    try {
      final isSolar = categoryId == CategoryIds.solar;
      final isSubmersible = categoryId == CategoryIds.submersible;

      await _fetchBaseData(isSolar);
      await _fetchSpecificData(isSolar, isSubmersible);
      await _initializeDefaults(categoryId, isSolar);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchBaseData(bool isSolar) async {
    final results = await Future.wait([
      _dataService.getApplicationsByCategory(_currentCategoryId),
      _dataService.getFrequencies(),
      _dataService.getFlowRates(),
      _dataService.getHeightGauges(),
    ]);

    _applications = (results[0] as List)
        .map(
          (e) => {
            'value': e['id']?.toString() ?? '',
            'title': e['title']?.toString() ?? '',
          },
        )
        .toList();

    _frequencies = (results[1] as List)
        .map((e) => e['value'].toString())
        .toList();

    _flowUnits = (results[2] as List)
        .where((e) {
          if (!isSolar && e['value'].toString() == 'md') return false;
          return true;
        })
        .map((e) {
          String label = e['label'].toString();
          String value = ParseUtil.normalizeSpecialChars(label);
          return {'value': value, 'title': label};
        })
        .toList();

    _headUnits = (results[3] as List).map((e) {
      String label = e['label'].toString();
      String value = ParseUtil.normalizeSpecialChars(label);
      return {'value': value, 'title': label};
    }).toList();
  }

  Future<void> _fetchSpecificData(bool isSolar, bool isSubmersible) async {
    if (isSolar) {
      _systemTypes = await _dataService.getSystemTypes();
    } else {
      _systemTypes = [];
    }

    if (isSolar || isSubmersible) {
      final rawDiameters = await _dataService.getWellDiameters();
      _wellDiameters = rawDiameters.isNotEmpty
          ? [SystemConstants.defaultValueZero, ...rawDiameters]
          : [];
    } else {
      _wellDiameters = [];
    }
  }

  Future<void> _initializeDefaults(String categoryId, bool isSolar) async {
    if (_applications.isNotEmpty) {
      selectedApplication = _applications.first['value'];
      await fetchModels(categoryId, selectedApplication!);
    }

    final isPressurizer =
        categoryId == CategoryIds.pressurizer ||
        categoryId == CategorySlugs.pressurizer;

    if (_frequencies.isNotEmpty && !isSolar && !isPressurizer) {
      selectedFrequency = _frequencies.first;
    }

    if (_flowUnits.isNotEmpty) selectedFlowUnit = _flowUnits.first['value'];
    if (_headUnits.isNotEmpty) selectedHeadUnit = _headUnits.first['value'];

    if (_systemTypes.isNotEmpty && isSolar) {
      selectedSystemType = _systemTypes.first['value'].toString();
    }

    if (_wellDiameters.isNotEmpty) {
      selectedWellDiameter = _wellDiameters.first;
    }
  }

  Future<void> fetchModels(String categoryId, String application) async {
    selectedModel = null;
    notifyListeners();

    final data = await _dataService.getLines(
      categoryId,
      application: application,
    );

    _models = data
        .map(
          (e) => {
            'value': e['title_product'].toString(),
            'title': e['title_product'].toString(),
          },
        )
        .toList();

    if (_models.isNotEmpty) selectedModel = _models.first['value'];
    notifyListeners();
  }

  void setApplication(String categoryId, String? val) {
    if (val != null) {
      selectedApplication = val;
      fetchModels(categoryId, val);
    }
  }

  void setSystemType(String? val) {
    selectedSystemType = val;
    notifyListeners();
  }

  void setModel(String? val) {
    selectedModel = val;
    notifyListeners();
  }

  void setFrequency(String val) {
    selectedFrequency = val;
    notifyListeners();
  }

  void setWellDiameter(String? val) {
    selectedWellDiameter = val;
    notifyListeners();
  }

  void setFlowUnit(String? val) {
    selectedFlowUnit = val!;
    notifyListeners();
  }

  void setHeadUnit(String? val) {
    selectedHeadUnit = val!;
    notifyListeners();
  }

  void setActivationType(String? val) {
    activationType = val ?? ActivationType.pressostato.name;
    notifyListeners();
  }

  Map<String, dynamic>? getFilterResult({
    required String flow,
    required String head,
    required String cableLength,
    required String bombsQuantity,
  }) {
    final isSolar = _currentCategoryId == CategoryIds.solar;
    final isPressurizer =
        _currentCategoryId == CategoryIds.pressurizer ||
        _currentCategoryId == CategorySlugs.pressurizer;
    final isSubmersible = _currentCategoryId == CategoryIds.submersible;

    if (_isInvalidInput(flow, head, bombsQuantity, isPressurizer, isSolar)) {
      return null;
    }

    final Map<String, dynamic> result = {
      'application':
          (selectedApplication == null || selectedApplication!.isEmpty)
          ? SystemConstants.all
          : selectedApplication,
      'line': (selectedModel == null || selectedModel!.isEmpty)
          ? SystemConstants.all
          : selectedModel,
      'flow_rate':
          ParseUtil.toDoubleSafe(flow)?.toString() ??
          SystemConstants.defaultValueZero,
      'flow_rate_measure': selectedFlowUnit,
      'height_gauge':
          ParseUtil.toDoubleSafe(head)?.toString() ??
          SystemConstants.defaultValueZero,
      'height_gauge_measure': selectedHeadUnit,
    };

    if (isPressurizer) {
      _addPressurizerParams(result, bombsQuantity);
    } else if (isSolar) {
      _addSolarParams(result, cableLength);
    } else {
      result['frequency'] = selectedFrequency;
    }

    if (isSolar || isSubmersible) {
      result['well_diameter'] = selectedWellDiameter;
    }

    return result;
  }

  bool _isInvalidInput(
    String flow,
    String head,
    String bombsQuantity,
    bool isPressurizer,
    bool isSolar,
  ) {
    if (selectedApplication == null ||
        selectedModel == null ||
        flow.isEmpty ||
        head.isEmpty) {
      return true;
    }

    if (isPressurizer &&
        activationType == ActivationType.inversor.name &&
        bombsQuantity.isEmpty) {
      return true;
    }

    if (!isSolar && !isPressurizer && selectedFrequency == null) {
      return true;
    }

    return false;
  }

  void _addPressurizerParams(Map<String, dynamic> result, String qty) {
    result['activation'] = activationType;
    if (activationType == ActivationType.inversor.name) {
      result['bombs_quantity'] = ParseUtil.toIntSafe(qty) ?? 1;
    }
  }

  void _addSolarParams(Map<String, dynamic> result, String cable) {
    result['types'] = selectedSystemType;
    result['cable_lenght'] =
        ParseUtil.toDoubleSafe(cable)?.toString() ??
        SystemConstants.defaultValueZero;
  }
}
