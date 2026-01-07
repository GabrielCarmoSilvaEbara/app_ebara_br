enum FlowUnit { m3h, ls, lmin, gpm }

enum PressureUnit { mca, bar, psi, kgfcm2 }

enum PowerUnit { cv, hp, kw }

enum MaterialType { pvc, iron }

enum CalcCategory { flow, pressure, power }

enum ActivationType { pressostato, inversor }

enum SystemType { directCurrent, alternatingCurrent }

class AppConstantsStrings {
  static const String all = 'TODOS';
  static const String m3h = 'm3/h';
  static const String m = 'm';
}
