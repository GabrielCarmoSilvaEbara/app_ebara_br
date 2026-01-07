import 'package:flutter/material.dart' hide MaterialType;
import '../utils/calculator_util.dart';
import '../utils/parse_util.dart';
import '../enums/app_enums.dart';

class CalculatorProvider with ChangeNotifier {
  CalcCategory category = CalcCategory.flow;
  String fromUnit = FlowUnit.m3h.name;
  String toUnit = FlowUnit.ls.name;
  double converterResult = 0.0;

  List<String> get currentUnits {
    switch (category) {
      case CalcCategory.flow:
        return FlowUnit.values.map((e) => e.name).toList();
      case CalcCategory.pressure:
        return PressureUnit.values.map((e) => e.name).toList();
      case CalcCategory.power:
        return PowerUnit.values.map((e) => e.name).toList();
    }
  }

  void updateCategory(CalcCategory newCategory) {
    if (category == newCategory) return;
    category = newCategory;
    fromUnit = currentUnits.first;
    toUnit = currentUnits[1];
    converterResult = 0.0;
    notifyListeners();
  }

  void updateFromUnit(String unit) {
    if (fromUnit == unit) return;
    fromUnit = unit;
    notifyListeners();
  }

  void updateToUnit(String unit) {
    if (toUnit == unit) return;
    toUnit = unit;
    notifyListeners();
  }

  void convert(String valueStr) {
    final value = ParseUtil.toDoubleSafe(valueStr) ?? 0.0;
    double result = 0.0;

    switch (category) {
      case CalcCategory.flow:
        result = CalculatorUtil.convertFlow(value, fromUnit, toUnit);
        break;
      case CalcCategory.pressure:
        result = CalculatorUtil.convertPressure(value, fromUnit, toUnit);
        break;
      case CalcCategory.power:
        result = CalculatorUtil.convertPower(value, fromUnit, toUnit);
        break;
    }

    if (converterResult != result) {
      converterResult = result;
      notifyListeners();
    }
  }

  MaterialType material = MaterialType.pvc;
  double hydraulicResult = 0;

  void updateMaterial(MaterialType val) {
    if (material == val) return;
    material = val;
    notifyListeners();
  }

  void calculateHydraulic(String flowStr, String diamStr, String lenStr) {
    final flow = ParseUtil.toDoubleSafe(flowStr) ?? 0.0;
    final diam = ParseUtil.toDoubleSafe(diamStr) ?? 0.0;
    final len = ParseUtil.toDoubleSafe(lenStr) ?? 0.0;

    final result = CalculatorUtil.calculateHydraulicHeadLoss(
      flowM3h: flow,
      diameterMm: diam,
      lengthM: len,
      material: material.name,
    );

    if (hydraulicResult != result) {
      hydraulicResult = result;
      notifyListeners();
    }
  }

  double voltageDropResult = 0;
  double voltagePercent = 0.0;

  bool get isVoltageDropCritical => voltagePercent > 4;

  void calculateElectric(
    String currentStr,
    String voltStr,
    String distStr,
    String sectStr,
  ) {
    final i = ParseUtil.toDoubleSafe(currentStr) ?? 0.0;
    final v = ParseUtil.toDoubleSafe(voltStr) ?? 0.0;
    final l = ParseUtil.toDoubleSafe(distStr) ?? 0.0;
    final s = ParseUtil.toDoubleSafe(sectStr) ?? 0.0;

    final res = CalculatorUtil.calculateVoltageDrop(
      current: i,
      voltage: v,
      length: l,
      section: s,
    );

    if (voltageDropResult != res['drop'] || voltagePercent != res['percent']) {
      voltageDropResult = res['drop']!;
      voltagePercent = res['percent']!;
      notifyListeners();
    }
  }
}
