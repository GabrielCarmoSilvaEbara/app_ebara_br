import 'package:flutter/material.dart';
import '../services/ebara_data_service.dart';
import '../constants/app_constants.dart';
import '../enums/app_enums.dart';
import '../utils/parse_util.dart';

class FilterProvider with ChangeNotifier {
  final EbaraDataService _dataService;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _currentCategoryId = '';

  List<String> _applications = [];
  List<String> _models = [];
  List<String> _frequencies = [];
  List<Map<String, dynamic>> _systemTypes = [];
  List<String> _wellDiameters = [];
  List<Map<String, dynamic>> _flowUnits = [];
  List<Map<String, dynamic>> _headUnits = [];

  List<String> get applications => _applications;
  List<String> get models => _models;
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
  String selectedFlowUnit = AppConstantsStrings.m3h;
  String selectedHeadUnit = AppConstantsStrings.m;

  FilterProvider({required EbaraDataService dataService})
    : _dataService = dataService;

  Future<void> loadFiltersData(String categoryId) async {
    _isLoading = true;
    _currentCategoryId = categoryId;
    notifyListeners();

    try {
      final isSolar = categoryId == CategoryIds.solar;
      final isSubmersible = categoryId == CategoryIds.submersible;

      final baseFutures = [
        _dataService.getApplicationsByCategory(categoryId),
        _dataService.getFrequencies(),
        _dataService.getFlowRates(),
        _dataService.getHeightGauges(),
      ];

      Future<List<Map<String, dynamic>>>? systemTypesFuture;
      Future<List<String>>? wellDiametersFuture;

      if (isSolar) systemTypesFuture = _dataService.getSystemTypes();
      if (isSolar || isSubmersible) {
        wellDiametersFuture = _dataService.getWellDiameters();
      }

      final results = await Future.wait(baseFutures);
      final systemTypes = systemTypesFuture != null
          ? await systemTypesFuture
          : <Map<String, dynamic>>[];
      final wellDiametersRaw = wellDiametersFuture != null
          ? await wellDiametersFuture
          : <String>[];

      _applications = (results[0] as List)
          .map((e) => e['title'].toString())
          .toList();
      _frequencies = (results[1] as List)
          .map((e) => e['value'].toString())
          .toList();

      _flowUnits = (results[2] as List)
          .where((e) {
            if (!isSolar && e['value'].toString() == 'md') return false;
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
      _wellDiameters = wellDiametersRaw.isNotEmpty
          ? ['0', ...wellDiametersRaw]
          : [];

      if (_applications.isNotEmpty) {
        selectedApplication = _applications.first;
        await fetchModels(categoryId, selectedApplication!);
      }

      if (_frequencies.isNotEmpty &&
          !isSolar &&
          categoryId != CategoryIds.pressurizer &&
          categoryId != CategoryIds.pressurizerSlug) {
        selectedFrequency = _frequencies.first;
      }

      if (_flowUnits.isNotEmpty) selectedFlowUnit = _flowUnits.first['value'];
      if (_headUnits.isNotEmpty) selectedHeadUnit = _headUnits.first['value'];
      if (_systemTypes.isNotEmpty && isSolar) {
        selectedSystemType = _systemTypes.first['value'].toString();
      }
      if (_wellDiameters.isNotEmpty && (isSolar || isSubmersible)) {
        selectedWellDiameter = _wellDiameters.first;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchModels(String categoryId, String application) async {
    selectedModel = null;
    notifyListeners();
    final data = await _dataService.getLines(
      categoryId,
      application: application,
    );
    _models = data.map((e) => e['title_product'].toString()).toList();
    if (_models.isNotEmpty) selectedModel = _models.first;
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
        _currentCategoryId == CategoryIds.pressurizerSlug;

    if (selectedApplication == null ||
        selectedModel == null ||
        flow.isEmpty ||
        head.isEmpty) {
      return null;
    }

    if (isPressurizer &&
        activationType == ActivationType.inversor.name &&
        bombsQuantity.isEmpty) {
      return null;
    }

    if (!isSolar && !isPressurizer && selectedFrequency == null) {
      return null;
    }

    final isSubmersible = _currentCategoryId == CategoryIds.submersible;

    final Map<String, dynamic> result = {
      'application': selectedApplication,
      'line': selectedModel,
      'flow_rate': ParseUtil.toDoubleSafe(flow)?.toString() ?? '0',
      'flow_rate_measure': selectedFlowUnit,
      'height_gauge': ParseUtil.toDoubleSafe(head)?.toString() ?? '0',
      'height_gauge_measure': selectedHeadUnit,
    };

    if (isPressurizer) {
      result['activation'] = activationType;
      if (activationType == ActivationType.inversor.name) {
        result['bombs_quantity'] = ParseUtil.toIntSafe(bombsQuantity) ?? 1;
      }
    } else if (isSolar) {
      result['types'] = selectedSystemType;
      result['cable_lenght'] =
          ParseUtil.toDoubleSafe(cableLength)?.toString() ?? '0';
    } else {
      result['frequency'] = selectedFrequency;
    }

    if (isSolar || isSubmersible) {
      result['well_diameter'] = selectedWellDiameter;
    }

    return result;
  }
}
