import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../constants/app_constants.dart';
import '../utils/parse_util.dart';

class LocationService {
  final ApiService _api;

  LocationService({ApiService? api})
    : _api =
          api ??
          ApiService(
            baseUrl: AppConstants.nominatimUrl,
            defaultHeaders: {'User-Agent': AppConstants.userAgent},
          );

  static const minQueryLength = 3;
  static const searchLimit = 10;
  static const List<String> validCityAddresstypes = [
    'city',
    'town',
    'village',
    'municipality',
  ];

  Future<Map<String, String>?> getCurrentCity() async {
    try {
      final position = await _getCurrentPosition();
      if (position == null) return null;

      final locationData = await _reverseGeocode(position);
      if (locationData.isEmpty) return null;

      final parsedData = _parseLocationData(locationData);
      return {
        ...parsedData,
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
      };
    } catch (e) {
      return null;
    }
  }

  Future<Position?> _getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    final permission = await _checkAndRequestPermission();
    if (permission == null) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on Exception {
      return null;
    }
  }

  Future<LocationPermission?> _checkAndRequestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    return permission;
  }

  Future<Map<String, dynamic>> _reverseGeocode(Position position) async {
    final response = await _api.get<Map<String, dynamic>>(
      'reverse',
      queryParams: {
        'lat': position.latitude,
        'lon': position.longitude,
        'format': 'json',
        'addressdetails': '1',
      },
      cacheDuration: const Duration(days: 7),
      parser: (json) => json as Map<String, dynamic>,
    );
    return response.dataOrNull ?? {};
  }

  Map<String, String> _parseLocationData(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>? ?? {};
    return {
      'address_type': data['addresstype'] as String? ?? '',
      'city': _extractCity(address),
      'district': _extractDistrict(address),
      'state': address['state'] as String? ?? '',
      'country': address['country'] as String? ?? '',
    };
  }

  String _extractCity(Map<String, dynamic> address) {
    return address['city'] as String? ??
        address['town'] as String? ??
        address['village'] as String? ??
        address['municipality'] as String? ??
        '';
  }

  String _extractDistrict(Map<String, dynamic> address) {
    return address['city_district'] as String? ??
        address['suburb'] as String? ??
        address['neighbourhood'] as String? ??
        '';
  }

  Future<List<Map<String, String>>> searchCities({
    required String query,
  }) async {
    if (query.length < minQueryLength) return [];

    final response = await _api.get<List<dynamic>>(
      'search',
      queryParams: {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': searchLimit,
        'extratags': '0',
      },
      cacheDuration: const Duration(days: 30),
      parser: (json) => json as List<dynamic>,
    );

    if (!response.isSuccess) throw Exception('Falha ao buscar cidades');
    return _parseCitySearchResults(response.dataOrNull ?? []);
  }

  List<Map<String, String>> _parseCitySearchResults(List data) {
    return data
        .where((item) {
          final type = item['addresstype'] as String?;
          return type != null && validCityAddresstypes.contains(type);
        })
        .map<Map<String, String>>((item) {
          final address = item['address'] as Map<String, dynamic>? ?? {};
          return {
            'address_type': item['addresstype'] as String? ?? '',
            'city': _extractCity(address),
            'state': address['state'] as String? ?? '',
            'country': address['country'] as String? ?? '',
            'lat': ParseUtil.toDoubleSafe(item['lat']).toString(),
            'lon': ParseUtil.toDoubleSafe(item['lon']).toString(),
          };
        })
        .where((item) => item['city']!.isNotEmpty)
        .toList();
  }
}
