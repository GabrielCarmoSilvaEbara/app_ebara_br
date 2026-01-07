import 'dart:math';

class CalculatorUtil {
  static double convertFlow(double value, String from, String to) {
    double base = 0;

    if (from == 'm3h') {
      base = value;
    } else if (from == 'ls') {
      base = value * 3.6;
    } else if (from == 'lmin') {
      base = value * 0.06;
    } else if (from == 'gpm') {
      base = value * 0.2271;
    }

    if (to == 'm3h') {
      return base;
    } else if (to == 'ls') {
      return base / 3.6;
    } else if (to == 'lmin') {
      return base / 0.06;
    } else if (to == 'gpm') {
      return base / 0.2271;
    }
    return 0.0;
  }

  static double convertPressure(double value, String from, String to) {
    double base = 0;

    if (from == 'mca') {
      base = value;
    } else if (from == 'bar') {
      base = value * 10.197;
    } else if (from == 'psi') {
      base = value * 0.703;
    } else if (from == 'kgfcm2') {
      base = value * 10;
    }

    if (to == 'mca') {
      return base;
    } else if (to == 'bar') {
      return base / 10.197;
    } else if (to == 'psi') {
      return base / 0.703;
    } else if (to == 'kgfcm2') {
      return base / 10;
    }
    return 0.0;
  }

  static double convertPower(double value, String from, String to) {
    double base = 0;

    if (from == 'cv') {
      base = value * 0.7355;
    } else if (from == 'hp') {
      base = value * 0.7457;
    } else if (from == 'kw') {
      base = value;
    }

    if (to == 'cv') {
      return base / 0.7355;
    } else if (to == 'hp') {
      return base / 0.7457;
    } else if (to == 'kw') {
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

    final c = material == 'pvc' ? 150 : 100;
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
