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

  List<String> _locationSearchHistory = [];

  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isGpsLoading = false;

  String _city = '';
  String _state = '';
  String _country = '';
  String _countryCode = '';
  double _lat = -23.5505;
  double _lon = -46.6333;

  Locale _currentLocale = const Locale('pt');
  Locale get currentLocale => _currentLocale;

  static const Set<String> _spanishSpeakingCountries = {
    'es',
    'mx',
    'ar',
    'co',
    'pe',
    've',
    'cl',
    'ec',
    'gt',
    'cu',
    'bo',
    'do',
    'hn',
    'py',
    'sv',
    'ni',
    'cr',
    'pa',
    'uy',
    'gq',
    'pr',
  };

  static const Set<String> _portugueseSpeakingCountries = {
    'br',
    'pt',
    'ao',
    'mz',
    'cv',
    'gw',
    'st',
    'tl',
  };

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
  List<String> get locationSearchHistory => _locationSearchHistory;

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
    _loadSearchHistory();
    try {
      final cachedLocation = _settingsBox.get(StorageKeys.keyUserLocation);

      if (cachedLocation != null) {
        final data = Map<String, dynamic>.from(cachedLocation);
        _updateLocalData(
          data['city'] ?? '',
          data['state'] ?? '',
          data['country'] ?? '',
          data['country_code'] ?? '',
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

  void _loadSearchHistory() {
    _locationSearchHistory = _settingsBox
        .get('location_search_history', defaultValue: <String>[])
        .cast<String>();
  }

  void addToSearchHistory(String term) {
    if (term.trim().isEmpty) return;
    _locationSearchHistory.remove(term);
    _locationSearchHistory.insert(0, term);
    if (_locationSearchHistory.length > 5) _locationSearchHistory.removeLast();
    _settingsBox.put('location_search_history', _locationSearchHistory);
    notifyListeners();
  }

  void removeFromSearchHistory(String term) {
    _locationSearchHistory.remove(term);
    _settingsBox.put('location_search_history', _locationSearchHistory);
    notifyListeners();
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
      'country_code': apiCity['country_code']?.toString() ?? '',
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
          countryCode: loc['country_code'] ?? '',
          lat: double.tryParse(loc['lat'] ?? '') ?? 0,
          lon: double.tryParse(loc['lon'] ?? '') ?? 0,
          saveToCache: true,
        );
        setGpsLoading(false);
        return true;
      }
    } catch (e) {
      //
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
        'country_code': 'br',
        'lat': '-23.5505',
        'lon': '-46.6333',
      },
    ];
    _currentIndex = 0;
    _updateLocaleByCode('br');
    notifyListeners();
  }

  void initWithCurrentLocation() {
    _results = [
      {
        'city': _city,
        'state': _state,
        'country': _country,
        'country_code': _countryCode,
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
    String countryCode = '',
    required double lat,
    required double lon,
    bool saveToCache = true,
  }) {
    _updateLocalData(city, state, country, countryCode, lat, lon);

    if (saveToCache) {
      _settingsBox.put(StorageKeys.keyUserLocation, {
        'city': city,
        'state': state,
        'country': country,
        'country_code': countryCode,
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
    String countryCode,
    double lat,
    double lon,
  ) {
    _city = city;
    _state = state;
    _country = country;
    _countryCode = countryCode;
    _lat = lat;
    _lon = lon;
    _updateLocaleByCode(countryCode);
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
      countryCode: cityData['country_code']?.toString() ?? '',
      lat: double.tryParse(cityData['lat'].toString()) ?? 0,
      lon: double.tryParse(cityData['lon'].toString()) ?? 0,
      saveToCache: true,
    );
  }

  void _updateLocaleByCode(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) {
      _currentLocale = const Locale('en');
      return;
    }

    final code = countryCode.toLowerCase().trim();

    if (_portugueseSpeakingCountries.contains(code)) {
      _currentLocale = const Locale('pt');
    } else if (_spanishSpeakingCountries.contains(code)) {
      _currentLocale = const Locale('es');
    } else {
      _currentLocale = const Locale('en');
    }
  }

  Future<void> performSearch(String query) async {
    addToSearchHistory(query);
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
