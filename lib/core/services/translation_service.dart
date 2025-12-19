class TranslationService {
  static String currentLanguage = 'pt';

  static int getLanguageId() {
    switch (currentLanguage) {
      case 'pt':
        return 1;
      case 'en':
        return 2;
      case 'es':
        return 3;
      default:
        return 1;
    }
  }

  static void setLanguageByCountry(String country) {
    if (country.toLowerCase().contains('brasil') ||
        country.toLowerCase().contains('brazil')) {
      currentLanguage = 'pt';
    } else if (country.toLowerCase().contains('españa') ||
        country.toLowerCase().contains('spain') ||
        country.toLowerCase().contains('méxico') ||
        country.toLowerCase().contains('mexico') ||
        country.toLowerCase().contains('argentina') ||
        country.toLowerCase().contains('colombia') ||
        country.toLowerCase().contains('chile') ||
        country.toLowerCase().contains('perú') ||
        country.toLowerCase().contains('peru')) {
      currentLanguage = 'es';
    } else {
      currentLanguage = 'en';
    }
  }

  static String translate(String key) {
    final translations = {
      'location': {'en': 'Location', 'pt': 'Localização', 'es': 'Ubicación'},
      'search': {'en': 'Search...', 'pt': 'Buscar...', 'es': 'Buscar...'},
      'results': {'en': 'Results', 'pt': 'Resultados', 'es': 'Resultados'},
      'select_category': {
        'en': 'Select Category',
        'pt': 'Selecione a Categoria',
        'es': 'Seleccionar Categoría',
      },
      'no_products_found': {
        'en': 'No products found',
        'pt': 'Nenhum produto encontrado',
        'es': 'No se encontraron productos',
      },
      'choose_location': {
        'en': 'Choose location',
        'pt': 'Escolher localização',
        'es': 'Elegir ubicación',
      },
      'select_location': {
        'en': 'Select location',
        'pt': 'Selecione a localização',
        'es': 'Seleccionar ubicación',
      },
      'enter_city_name': {
        'en': 'Enter the city name',
        'pt': 'Digite o nome da cidade',
        'es': 'Ingrese el nombre de la ciudad',
      },
      'search_button': {'en': 'Search', 'pt': 'Buscar', 'es': 'Buscar'},
      'recent': {'en': 'Recent', 'pt': 'Recentes', 'es': 'Recientes'},
      'error_min_letters': {
        'en': 'Type at least 3 letters',
        'pt': 'Digite pelo menos 3 letras',
        'es': 'Escriba al menos 3 letras',
      },
      'error_fetching_cities': {
        'en': 'Error fetching cities',
        'pt': 'Erro ao buscar cidades',
        'es': 'Error al buscar ciudades',
      },
      'bombas-centrifugas': {
        'en': 'CENTRIFUGAL PUMPS',
        'pt': 'BOMBAS CENTRÍFUGAS',
        'es': 'BOMBAS CENTRÍFUGAS',
      },
      'bombas-submersas': {
        'en': 'SUBMERSIBLE PUMPS',
        'pt': 'BOMBAS SUBMERSÍVEIS',
        'es': 'BOMBAS SUMERGIBLES',
      },
      'bombas-submersiveis': {
        'en': 'SUBMERSIBLE PUMPS',
        'pt': 'BOMBAS SUBMERSÍVEIS',
        'es': 'BOMBAS SUMERGIBLES',
      },
      'filters': {'en': 'Filters', 'pt': 'Filtros', 'es': 'Filtros'},
      'pump': {'en': 'PUMP', 'pt': 'BOMBA', 'es': 'BOMBA'},
      'others': {'en': 'OTHERS', 'pt': 'OUTROS', 'es': 'OTROS'},
      'models': {'en': 'Models', 'pt': 'Modelos', 'es': 'Modelos'},
      'frequency': {'en': 'Frequency', 'pt': 'Frequência', 'es': 'Frecuencia'},
      'flow': {'en': 'Flow', 'pt': 'Vazão', 'es': 'Caudal'},
      'manometric_head': {
        'en': 'Manometric Head',
        'pt': 'Altura Manométrica',
        'es': 'Altura Manométrica',
      },
      'power': {'en': 'Power', 'pt': 'Potência', 'es': 'Potencia'},
      'voltage': {'en': 'Voltage', 'pt': 'Voltagem', 'es': 'Voltaje'},
      'rotation': {'en': 'Rotation', 'pt': 'Rotação', 'es': 'Rotación'},
      'max_pressure': {
        'en': 'Max Pressure',
        'pt': 'Pressão Máx.',
        'es': 'Presión Máx.',
      },
      'max_flow': {'en': 'Max Flow', 'pt': 'Vazão Máx.', 'es': 'Caudal Máx.'},
      'model_label': {'en': 'Mod.', 'pt': 'Mod.', 'es': 'Mod.'},
      'technical_sheet': {
        'en': 'Technical Sheet',
        'pt': 'Ficha Técnica',
        'es': 'Ficha Técnica',
      },
      'Ficha Técnica': {
        'en': 'Technical Sheet',
        'pt': 'Ficha Técnica',
        'es': 'Ficha Técnica',
      },
      'features': {
        'en': 'Features',
        'pt': 'Características',
        'es': 'Características',
      },
      'Características': {
        'en': 'Features',
        'pt': 'Características',
        'es': 'Características',
      },
      'specifications': {
        'en': 'Specifications',
        'pt': 'Especificações',
        'es': 'Especificaciones',
      },
      'Especificações': {
        'en': 'Specifications',
        'pt': 'Especificações',
        'es': 'Especificaciones',
      },
      'options': {'en': 'Options', 'pt': 'Opções', 'es': 'Opciones'},
      'Opções': {'en': 'Options', 'pt': 'Opções', 'es': 'Opciones'},
      'applications': {
        'en': 'Applications',
        'pt': 'Aplicações',
        'es': 'Aplicaciones',
      },
      'Aplicações': {
        'en': 'Applications',
        'pt': 'Aplicações',
        'es': 'Aplicaciones',
      },
      'technical_info_title': {
        'en': 'Technical Information',
        'pt': 'Informações Técnicas',
        'es': 'Información Técnica',
      },

      'Documentos': {'en': 'Documents', 'pt': 'Documentos', 'es': 'Documentos'},
      'Nenhum documento disponível': {
        'en': 'No documents available',
        'pt': 'Nenhum documento disponível',
        'es': 'No hay documentos disponibles',
      },
      'Abrir documento': {
        'en': 'Open document',
        'pt': 'Abrir documento',
        'es': 'Abrir documento',
      },
      'technical_comparison': {
        'en': 'Technical Comparison',
        'pt': 'Comparativo Técnico',
        'es': 'Comparación Técnica',
      },
      'current_tag': {'en': 'CURRENT', 'pt': 'ATUAL', 'es': 'ACTUAL'},
      'compare_with': {
        'en': 'Compare with:',
        'pt': 'Comparar com:',
        'es': 'Comparar con:',
      },
      'base_value': {'en': 'Base', 'pt': 'Base', 'es': 'Base'},
      'target_value': {'en': 'Target', 'pt': 'Alvo', 'es': 'Objetivo'},
      'Residencial': {
        'en': 'Residential',
        'pt': 'Residencial',
        'es': 'Residencial',
      },
      'Abastecimento': {
        'en': 'Water Supply',
        'pt': 'Abastecimento',
        'es': 'Abastecimiento',
      },
      'Irrigação': {'en': 'Irrigation', 'pt': 'Irrigação', 'es': 'Irrigación'},
      'Industrial': {
        'en': 'Industrial',
        'pt': 'Industrial',
        'es': 'Industrial',
      },
      'agricultural': {
        'en': 'Agricultural',
        'pt': 'Agrícola',
        'es': 'Agrícola',
      },
      'commercial': {'en': 'Commercial', 'pt': 'Comercial', 'es': 'Comercial'},
      'pick_one': {
        'en': 'Pick one',
        'pt': 'Selecione um',
        'es': 'Seleccionar uno',
      },
    };

    return translations[key]?[currentLanguage] ?? key;
  }
}
