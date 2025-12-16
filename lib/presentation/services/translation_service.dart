class TranslationService {
  static String currentLanguage = 'en';

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
      'centrifugal_pumps': {
        'en': 'CENTRIFUGAL PUMPS',
        'pt': 'BOMBAS CENTRÍFUGAS',
        'es': 'BOMBAS CENTRÍFUGAS',
      },
      'submersible_pumps': {
        'en': 'SUBMERSIBLE PUMPS',
        'pt': 'BOMBAS SUBMERSÍVEIS',
        'es': 'BOMBAS SUMERGIBLES',
      },
      'residential': {
        'en': 'Residential',
        'pt': 'Residencial',
        'es': 'Residencial',
      },
      'industrial': {
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
      'applications': {
        'en': 'Applications',
        'pt': 'Aplicações',
        'es': 'Aplicaciones',
      },
      'models': {'en': 'Models', 'pt': 'Modelos', 'es': 'Modelos'},
      'frequency': {'en': 'Frequency', 'pt': 'Frequência', 'es': 'Frecuencia'},
      'flow': {'en': 'Flow', 'pt': 'Vazão', 'es': 'Caudal'},
      'manometric_head': {
        'en': 'Manometric Head',
        'pt': 'Altura Manométrica',
        'es': 'Altura Manométrica',
      },
      'pick_one': {
        'en': 'Pick one',
        'pt': 'Selecione um',
        'es': 'Seleccionar uno',
      },
      'pump': {'en': 'PUMP', 'pt': 'BOMBA', 'es': 'BOMBA'},
      'others': {'en': 'OTHERS', 'pt': 'OUTROS', 'es': 'OTROS'},
      'applications_title': {
        'en': 'Applications',
        'pt': 'Aplicações',
        'es': 'Aplicaciones',
      },
      'technical_info_title': {
        'en': 'Technical Information',
        'pt': 'Informações Técnicas',
        'es': 'Información Técnica',
      },
      'power': {'en': 'Power', 'pt': 'Potência', 'es': 'Potencia'},
      'voltage': {'en': 'Voltage', 'pt': 'Voltagem', 'es': 'Voltaje'},
      'product_description_1': {
        'en':
            'Single-Stage Centrifugal Pump - Monoblock - Single-Phase Motor in II Poles, 60Hz, 3500rpm - BSP threaded nozzles, Suction 3/4" x Discharge 3/4".',
        'pt':
            'Motobomba Centrífuga Monoestágio - Monobloco - Motor Monofásico em II Polos, 60Hz, 3500rpm - Bocais com rosca BSP, Sucção 3/4" x Recalque 3/4".',
        'es':
            'Bomba Centrífuga Monoetapa - Monobloque - Motor Monofásico en II Polos, 60Hz, 3500rpm - Boquillas con rosca BSP, Succión 3/4" x Descarga 3/4".',
      },
      'product_description_2': {
        'en':
            'Used for clean water up to 40ºC (Higher temperatures, consult options).',
        'pt':
            'Utilizada para água limpa até temperatura de 40ºC (Temperaturas superiores, consultar opções).',
        'es':
            'Utilizada para agua limpia hasta una temperatura de 40ºC (Temperaturas superiores, consultar opciones).',
      },
      'product_description_3': {
        'en': 'Pump casing in GG-20 cast iron.',
        'pt': 'Carcaça da bomba em ferro fundido GG-20.',
        'es': 'Carcasa de la bomba en hierro fundido GG-20.',
      },
      'product_description_4': {
        'en':
            'Closed impeller in thermoplastic. Casing O\'ring seal in Buna N.',
        'pt':
            'Rotor fechado em termoplástico. Anel O\'ring de vedação da carcaça em Buna N.',
        'es':
            'Rodete cerrado en termoplástico. Anillo O\'ring de sellado de la carcasa en Buna N.',
      },
      'product_description_5': {
        'en': 'Mechanical seal: Graphite and ceramic faces.',
        'pt': 'Selo mecânico: Faces em grafite e cerâmica.',
        'es': 'Sello mecánico: Caras en grafito y cerámica.',
      },
      'product_description_6': {
        'en': 'Spring in stainless steel 304 and elastomer (rubber) in Buna N.',
        'pt': 'Mola em inox 304 e elastômero (borracha) em Buna N.',
        'es': 'Muelle en acero inoxidable 304 y elastómero (goma) en Buna N.',
      },
    };

    return translations[key]?[currentLanguage] ?? key;
  }
}
