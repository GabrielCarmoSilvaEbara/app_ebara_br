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
    this.application = 'TODOS',
    this.line = 'TODOS',
    this.flowRate = 0.0,
    this.flowRateMeasure = 'm3/h',
    this.heightGauge = 0.0,
    this.heightGaugeMeasure = 'm',
    this.frequency = 60,
    this.types = 0,
    this.wellDiameter,
    this.cableLength,
    this.sunExposure = 5.0,
    this.activation = 'pressostato',
    this.bombsQuantity = 1,
    this.inverter = 'TODOS',
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
        categoryId == '27' || categoryId == 'sistemas-de-pressurizacao-1';

    if (isPressurizer) {
      params['activation'] = activation;
      if (activation == 'inversor') {
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
