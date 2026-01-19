import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/location_service.dart';
import '../services/analytics_service.dart';
import '../constants/app_constants.dart';

class LocationProvider with ChangeNotifier {
  static const String _recentLocationsKey = 'recent_locations';
  final LocationService _locationService;
  final Box _settingsBox = Hive.box(StorageKeys.boxSettings);

  List<Map<String, dynamic>> _results = [];
  List<Map<String, String>> _recentLocations = [];
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
  List<Map<String, String>> get recentLocations => _recentLocations;
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
    _loadRecentLocations();
    try {
      final cachedLocation = _settingsBox.get(StorageKeys.keyUserLocation);

      if (cachedLocation != null) {
        final data = Map<String, dynamic>.from(cachedLocation);
        _updateLocalData(
          data['city'] ?? '',
          data['state'] ?? '',
          data['country'] ?? '',
          (data['lat'] as num?)?.toDouble() ?? -23.5505,
          (data['lon'] as num?)?.toDouble() ?? -46.6333,
        );
        if (_city.isNotEmpty) {
          AnalyticsService.setUserLocation(_city, _state);
        }
        notifyListeners();
        return;
      }
    } catch (e) {
      await _settingsBox.delete(StorageKeys.keyUserLocation);
    }

    notifyListeners();
  }

  void _loadRecentLocations() {
    try {
      final List<dynamic>? stored = _settingsBox.get(_recentLocationsKey);
      if (stored != null) {
        _recentLocations = stored
            .map((e) => Map<String, String>.from(e))
            .toList();
      }
    } catch (_) {}
  }

  void addToRecent(Map<String, String> location) {
    _recentLocations.removeWhere(
      (e) => e['city'] == location['city'] && e['state'] == location['state'],
    );
    _recentLocations.insert(0, location);
    if (_recentLocations.length > 5) _recentLocations.removeLast();
    _settingsBox.put(_recentLocationsKey, _recentLocations);
    notifyListeners();
  }

  void addApiResultToRecent(Map<String, dynamic> apiCity) {
    final cityMap = {
      'city': apiCity['city']?.toString() ?? '',
      'state': apiCity['state']?.toString() ?? '',
      'country': apiCity['country']?.toString() ?? '',
    };
    addToRecent(cityMap);
  }

  Future<bool> useCurrentLocation() async {
    setGpsLoading(true);
    try {
      final loc = await _locationService.getCurrentCity();
      if (loc != null) {
        updateUserLocation(
          city: loc['city']!,
          state: loc['state']!,
          country: loc['country']!,
          lat: double.tryParse(loc['lat'] ?? '') ?? 0,
          lon: double.tryParse(loc['lon'] ?? '') ?? 0,
          saveToCache: true,
        );
        setGpsLoading(false);
        return true;
      }
    } catch (e) {
      // Ignore
    }
    setGpsLoading(false);
    return false;
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

  void updateUserLocation({
    required String city,
    required String state,
    required String country,
    required double lat,
    required double lon,
    bool saveToCache = true,
  }) {
    _updateLocalData(city, state, country, lat, lon);

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

  void _updateLocalData(
    String city,
    String state,
    String country,
    double lat,
    double lon,
  ) {
    _city = city;
    _state = state;
    _country = country;
    _lat = lat;
    _lon = lon;
    _updateLocaleByCountry(country);
  }

  void selectLocationFromIndex(int index) {
    if (index < 0 || index >= _results.length) return;
    final city = _results[index];
    _applySelection(city);
  }

  void selectCity(Map<String, dynamic> city) {
    _applySelection(city);
    addApiResultToRecent(city);
  }

  void _applySelection(Map<String, dynamic> cityData) {
    updateUserLocation(
      city: cityData['city']?.toString() ?? '',
      state: cityData['state']?.toString() ?? '',
      country: cityData['country']?.toString() ?? '',
      lat: double.tryParse(cityData['lat'].toString()) ?? 0,
      lon: double.tryParse(cityData['lon'].toString()) ?? 0,
      saveToCache: true,
    );
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

  Future<void> performSearch(String query) async {
    if (query.length < 3) return;

    _isLoading = true;
    notifyListeners();
    try {
      final cities = await _locationService.searchCities(query: query);
      _results = cities
          .map((c) => {...c, 'lat': c['lat'], 'lon': c['lon']})
          .toList();
      _currentIndex = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _results = [];
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
