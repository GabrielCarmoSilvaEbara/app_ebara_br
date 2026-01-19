import 'dart:math';
import '../enums/app_enums.dart';

class CalculatorUtil {
  static double convertFlow(double value, String from, String to) {
    double base = 0;

    if (from == FlowUnit.m3h.name) {
      base = value;
    } else if (from == FlowUnit.ls.name) {
      base = value * 3.6;
    } else if (from == FlowUnit.lmin.name) {
      base = value * 0.06;
    } else if (from == FlowUnit.gpm.name) {
      base = value * 0.2271;
    }

    if (to == FlowUnit.m3h.name) {
      return base;
    } else if (to == FlowUnit.ls.name) {
      return base / 3.6;
    } else if (to == FlowUnit.lmin.name) {
      return base / 0.06;
    } else if (to == FlowUnit.gpm.name) {
      return base / 0.2271;
    }
    return 0.0;
  }

  static double convertPressure(double value, String from, String to) {
    double base = 0;

    if (from == PressureUnit.mca.name) {
      base = value;
    } else if (from == PressureUnit.bar.name) {
      base = value * 10.197;
    } else if (from == PressureUnit.psi.name) {
      base = value * 0.703;
    } else if (from == PressureUnit.kgfcm2.name) {
      base = value * 10;
    }

    if (to == PressureUnit.mca.name) {
      return base;
    } else if (to == PressureUnit.bar.name) {
      return base / 10.197;
    } else if (to == PressureUnit.psi.name) {
      return base / 0.703;
    } else if (to == PressureUnit.kgfcm2.name) {
      return base / 10;
    }
    return 0.0;
  }

  static double convertPower(double value, String from, String to) {
    double base = 0;

    if (from == PowerUnit.cv.name) {
      base = value * 0.7355;
    } else if (from == PowerUnit.hp.name) {
      base = value * 0.7457;
    } else if (from == PowerUnit.kw.name) {
      base = value;
    }

    if (to == PowerUnit.cv.name) {
      return base / 0.7355;
    } else if (to == PowerUnit.hp.name) {
      return base / 0.7457;
    } else if (to == PowerUnit.kw.name) {
      return base;
    }
    return 0.0;
  }

  static double calculateHydraulicHeadLoss({
    required double flowM3h,
    required double diameterMm,
    required double lengthM,
    required String material,
  }) {
    if (flowM3h <= 0 || diameterMm <= 0 || lengthM <= 0) {
      return 0.0;
    }

    final c = material == MaterialType.pvc.name ? 150 : 100;
    final dm = diameterMm / 1000.0;
    final qm3s = flowM3h / 3600.0;

    final j = 10.643 * pow(qm3s, 1.852) * pow(c, -1.852) * pow(dm, -4.87);
    return j * lengthM;
  }

  static Map<String, double> calculateVoltageDrop({
    required double current,
    required double voltage,
    required double length,
    required double section,
  }) {
    if (current <= 0 || voltage <= 0 || length <= 0 || section <= 0) {
      return {'drop': 0.0, 'percent': 0.0};
    }

    const rho = 0.0172;
    final drop = (sqrt(3) * rho * length * current) / section;
    final percent = (drop / voltage) * 100;

    return {'drop': drop, 'percent': percent};
  }
}
