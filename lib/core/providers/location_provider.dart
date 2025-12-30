import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/location_service.dart';
import '../services/analytics_service.dart';
import '../constants/app_constants.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService;
  final Box _settingsBox = Hive.box(StorageKeys.boxSettings);

  List<Map<String, dynamic>> _results = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isGpsLoading = false;

  String _city = '';
  String _state = '';
  String _country = '';
  double _lat = -23.5505;
  double _lon = -46.6333;

  Locale _currentLocale = const Locale('pt');
  Locale get currentLocale => _currentLocale;

  LocationProvider({required LocationService locationService})
    : _locationService = locationService;

  int get apiLanguageId {
    switch (_currentLocale.languageCode) {
      case 'en':
        return 2;
      case 'es':
        return 3;
      default:
        return 1;
    }
  }

  List<Map<String, dynamic>> get results => _results;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  bool get isGpsLoading => _isGpsLoading;

  String get city => _city;
  String get state => _state;
  String get country => _country;
  double get lat => _lat;
  double get lon => _lon;

  double get previewLat {
    if (_results.isNotEmpty) {
      return double.tryParse(_results[_currentIndex]['lat'].toString()) ?? _lat;
    }
    return _lat;
  }

  double get previewLon {
    if (_results.isNotEmpty) {
      return double.tryParse(_results[_currentIndex]['lon'].toString()) ?? _lon;
    }
    return _lon;
  }

  Future<void> initLocation() async {
    try {
      final cachedLocation = _settingsBox.get(StorageKeys.keyUserLocation);

      if (cachedLocation != null) {
        final data = Map<String, dynamic>.from(cachedLocation);

        _city = data['city'] ?? '';
        _state = data['state'] ?? '';
        _country = data['country'] ?? '';
        _lat = (data['lat'] as num?)?.toDouble() ?? -23.5505;
        _lon = (data['lon'] as num?)?.toDouble() ?? -46.6333;

        _updateLocaleByCountry(_country);

        if (_city.isNotEmpty) {
          AnalyticsService.setUserLocation(_city, _state);
        }

        notifyListeners();
        return;
      }
    } catch (e) {
      await _settingsBox.delete(StorageKeys.keyUserLocation);
    }

    final location = await _locationService.getCurrentCity();

    if (location != null) {
      updateUserLocation(
        city: location['city'] ?? '',
        state: location['state'] ?? '',
        country: location['country'] ?? '',
        lat: double.tryParse(location['lat'] ?? '') ?? -23.5505,
        lon: double.tryParse(location['lon'] ?? '') ?? -46.6333,
        saveToCache: true,
      );
    } else {
      notifyListeners();
    }
  }

  void initDefaultLocation() {
    _results = [
      {
        'city': 'São Paulo',
        'state': 'São Paulo',
        'country': 'Brasil',
        'lat': '-23.5505',
        'lon': '-46.6333',
      },
    ];
    _currentIndex = 0;

    _updateLocaleByCountry('Brasil');

    notifyListeners();
  }

  void updateUserLocation({
    required String city,
    required String state,
    required String country,
    required double lat,
    required double lon,
    bool saveToCache = true,
  }) {
    _city = city;
    _state = state;
    _country = country;
    _lat = lat;
    _lon = lon;

    _updateLocaleByCountry(country);

    if (saveToCache) {
      _settingsBox.put(StorageKeys.keyUserLocation, {
        'city': city,
        'state': state,
        'country': country,
        'lat': lat,
        'lon': lon,
      });
    }

    AnalyticsService.setUserLocation(city, state);

    notifyListeners();
  }

  void _updateLocaleByCountry(String country) {
    final c = country.toLowerCase();
    if (c.contains('españa') ||
        c.contains('spain') ||
        c.contains('méxico') ||
        c.contains('mexico') ||
        c.contains('argentina') ||
        c.contains('colombia') ||
        c.contains('chile') ||
        c.contains('perú') ||
        c.contains('peru')) {
      _currentLocale = const Locale('es');
    } else if (c.contains('brasil') || c.contains('brazil')) {
      _currentLocale = const Locale('pt');
    } else {
      _currentLocale = const Locale('en');
    }
  }

  Future<void> search(String query) async {
    if (query.length < 3) {
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      _results = await _locationService.searchCities(query: query);
      _currentIndex = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void initWithCurrentLocation() {
    _results = [
      {
        'city': _city,
        'state': _state,
        'country': _country,
        'lat': _lat,
        'lon': _lon,
      },
    ];
    _currentIndex = 0;
    notifyListeners();
  }

  void updateIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void setGpsLoading(bool val) {
    _isGpsLoading = val;
    notifyListeners();
  }
}
