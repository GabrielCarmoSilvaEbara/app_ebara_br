import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'location': 'Location',
      'search': 'Search...',
      'results': 'Results',
      'select_category': 'Select Category',
      'no_products_found': 'No products found',
      'choose_location': 'Choose location',
      'select_location': 'Select location',
      'enter_city_name': 'Enter the city name',
      'search_button': 'Search',
      'recent': 'Recent',
      'error_min_letters': 'Type at least 3 letters',
      'error_fetching_cities': 'Error fetching cities',
      'filters': 'Filters',
      'pump': 'PUMP',
      'others': 'OTHERS',
      'models': 'Models',
      'frequency': 'Frequency',
      'flow': 'Flow',
      'manometric_head': 'Manometric Head',
      'power': 'Power',
      'rotation': 'Rotation',
      'max_pressure': 'Max Pressure',
      'max_flow': 'Max Flow',
      'technical_sheet': 'Technical Sheet',
      'features': 'Features',
      'specifications': 'Specifications',
      'options': 'Options',
      'applications': 'Applications',
      'technical_comparison': 'Technical Comparison',
      'pick_one': 'Pick one',
      'Ficha Técnica': 'Technical Sheet',
      'Características': 'Features',
      'Especificações': 'Specifications',
      'Opções': 'Options',
      'Aplicações': 'Applications',
      'Documentos': 'Documents',
      'Nenhum documento disponível': 'No documents available',
    },
    'pt': {
      'location': 'Localização',
      'search': 'Buscar...',
      'results': 'Resultados',
      'select_category': 'Selecione a Categoria',
      'no_products_found': 'Nenhum produto encontrado',
      'choose_location': 'Escolher localização',
      'select_location': 'Selecione a localização',
      'enter_city_name': 'Digite o nome da cidade',
      'search_button': 'Buscar',
      'recent': 'Recentes',
      'error_min_letters': 'Digite pelo menos 3 letras',
      'error_fetching_cities': 'Erro ao buscar cidades',
      'filters': 'Filtros',
      'pump': 'BOMBA',
      'others': 'OUTROS',
      'models': 'Modelos',
      'frequency': 'Frequência',
      'flow': 'Vazão',
      'manometric_head': 'Altura Manométrica',
      'power': 'Potência',
      'rotation': 'Rotação',
      'max_pressure': 'Pressão Máx.',
      'max_flow': 'Vazão Máx.',
      'technical_sheet': 'Ficha Técnica',
      'features': 'Características',
      'specifications': 'Especificações',
      'options': 'Opções',
      'applications': 'Aplicações',
      'technical_comparison': 'Comparativo Técnico',
      'pick_one': 'Selecione um',
      'Ficha Técnica': 'Ficha Técnica',
      'Características': 'Características',
      'Especificações': 'Especificações',
      'Opções': 'Opções',
      'Aplicações': 'Aplicações',
      'Documentos': 'Documentos',
      'Nenhum documento disponível': 'Nenhum documento disponível',
    },
    'es': {
      'location': 'Ubicación',
      'search': 'Buscar...',
      'results': 'Resultados',
      'select_category': 'Seleccionar Categoría',
      'no_products_found': 'No se encontraron productos',
      'choose_location': 'Elegir ubicación',
      'select_location': 'Seleccionar ubicación',
      'enter_city_name': 'Ingrese el nombre de la ciudad',
      'search_button': 'Buscar',
      'recent': 'Recientes',
      'error_min_letters': 'Escriba al menos 3 letras',
      'error_fetching_cities': 'Error al buscar ciudades',
      'filters': 'Filtros',
      'pump': 'BOMBA',
      'others': 'OTROS',
      'models': 'Modelos',
      'frequency': 'Frecuencia',
      'flow': 'Caudal',
      'manometric_head': 'Altura Manométrica',
      'power': 'Potencia',
      'rotation': 'Rotación',
      'max_pressure': 'Presión Máx.',
      'max_flow': 'Caudal Máx.',
      'technical_sheet': 'Ficha Técnica',
      'features': 'Características',
      'specifications': 'Especificaciones',
      'options': 'Opciones',
      'applications': 'Aplicaciones',
      'technical_comparison': 'Comparación Técnica',
      'pick_one': 'Seleccionar uno',
      'Ficha Técnica': 'Ficha Técnica',
      'Características': 'Características',
      'Especificações': 'Especificaciones',
      'Opções': 'Opciones',
      'Aplicações': 'Aplicaciones',
      'Documentos': 'Documentos',
      'Nenhum documento disponível': 'No hay documentos disponibles',
    },
  };

  String translate(String key) {
    if (key == 'bombas-centrifugas' || key == 'centrifugal-pumps') {
      return locale.languageCode == 'pt' || locale.languageCode == 'es'
          ? 'BOMBAS CENTRÍFUGAS'
          : 'CENTRIFUGAL PUMPS';
    }
    if (key == 'bombas-submersas' || key == 'deep-well-pumps') {
      return locale.languageCode == 'pt'
          ? 'BOMBAS SUBMERSAS'
          : locale.languageCode == 'es'
          ? 'BOMBAS SUMERGIBLES'
          : 'DEEP WELL PUMPS';
    }
    if (key == 'bombas-submersiveis' || key == 'submersible-pumps') {
      return locale.languageCode == 'pt'
          ? 'BOMBAS SUBMERSÍVEIS'
          : locale.languageCode == 'es'
          ? 'BOMBAS SUMERGIBLES'
          : 'SUBMERSIBLE PUMPS';
    }

    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'pt', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
