import '../constants/app_constants.dart';
import '../enums/app_enums.dart';

class ProductFilterParams {
  final String categoryId;
  final String application;
  final String line;
  final double flowRate;
  final String flowRateMeasure;
  final double heightGauge;
  final String heightGaugeMeasure;
  final int frequency;
  final int types;
  final String? wellDiameter;
  final String? cableLength;
  final double sunExposure;
  final String activation;
  final int bombsQuantity;
  final String inverter;
  final int alignedEquipment;
  final int idLanguage;

  ProductFilterParams({
    required this.categoryId,
    this.application = AppConstantsStrings.all,
    this.line = AppConstantsStrings.all,
    this.flowRate = 0.0,
    this.flowRateMeasure = AppConstantsStrings.m3h,
    this.heightGauge = 0.0,
    this.heightGaugeMeasure = AppConstantsStrings.m,
    this.frequency = 60,
    this.types = 0,
    this.wellDiameter,
    this.cableLength,
    this.sunExposure = 5.0,
    this.activation = 'pressostato',
    this.bombsQuantity = 1,
    this.inverter = AppConstantsStrings.all,
    this.alignedEquipment = 0,
    this.idLanguage = 1,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> params = {
      'application': application,
      'line': line,
      'flow_rate': flowRate,
      'flow_rate_measure': flowRateMeasure,
      'height_gauge': heightGauge,
      'height_gauge_measure': heightGaugeMeasure,
      'id_language': idLanguage,
    };

    final bool isPressurizer =
        categoryId == CategoryIds.pressurizer ||
        categoryId == CategoryIds.pressurizerSlug;

    if (isPressurizer) {
      params['activation'] = activation;
      if (activation == ActivationType.inversor.name) {
        params['bombs_quantity'] = bombsQuantity;
      }
    } else {
      params['category'] = categoryId;
      params['frequency'] = frequency;
      params['types'] = types;
      params['inverter'] = inverter;
      params['aligned_equipment'] = alignedEquipment;
      params['sun_exposure'] = sunExposure;

      if (wellDiameter != null) {
        params['well_diameter'] = wellDiameter;
      }
      if (cableLength != null) {
        params['cable_lenght'] = cableLength;
      }
    }

    return params;
  }
}
