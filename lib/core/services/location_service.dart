import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class LocationService {
  static final ApiService _api = ApiService(
    baseUrl: 'https://nominatim.openstreetmap.org',
    defaultHeaders: {'User-Agent': 'app-ebara/1.0 (contato@seudominio.com)'},
  );

  static const minQueryLength = 3;
  static const searchLimit = 10;

  static const List<String> validCityAddresstypes = [
    'city',
    'town',
    'village',
    'municipality',
  ];

  static Future<Map<String, String>?> getCurrentCity() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return null;

      final locationData = await reverseGeocode(position);
      if (locationData.isEmpty) return null;

      final parsedData = parseLocationData(locationData);

      return {
        ...parsedData,
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
      };
    } catch (e) {
      return null;
    }
  }

  static Future<Position?> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    final permission = await checkAndRequestPermission();
    if (permission == null) return null;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    );

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
    } on Exception {
      return null;
    }
  }

  static Future<LocationPermission?> checkAndRequestPermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return permission;
  }

  static Future<Map<String, dynamic>> reverseGeocode(Position position) async {
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

  static Map<String, String> parseLocationData(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>? ?? {};

    return {
      'address_type': data['addresstype'] as String? ?? '',
      'city': extractCity(address),
      'district': extractDistrict(address),
      'state': address['state'] as String? ?? '',
      'country': address['country'] as String? ?? '',
    };
  }

  static String extractCity(Map<String, dynamic> address) {
    return address['city'] as String? ??
        address['town'] as String? ??
        address['village'] as String? ??
        address['municipality'] as String? ??
        '';
  }

  static String extractDistrict(Map<String, dynamic> address) {
    return address['city_district'] as String? ??
        address['suburb'] as String? ??
        address['neighbourhood'] as String? ??
        '';
  }

  static Future<List<Map<String, String>>> searchCities({
    required String query,
  }) async {
    if (query.length < minQueryLength) {
      throw ArgumentError('Query must be at least $minQueryLength characters');
    }

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

    if (!response.isSuccess) {
      throw Exception('Falha ao buscar cidades');
    }

    return parseCitySearchResults(response.dataOrNull ?? []);
  }

  static List<Map<String, String>> parseCitySearchResults(List data) {
    return data
        .where((item) {
          final type = item['addresstype'] as String?;
          return type != null && validCityAddresstypes.contains(type);
        })
        .map<Map<String, String>>((item) {
          final address = item['address'] as Map<String, dynamic>? ?? {};
          final city = extractCity(address);

          return {
            'address_type': item['addresstype'] as String? ?? '',
            'city': city,
            'state': address['state'] as String? ?? '',
            'country': address['country'] as String? ?? '',
            'lat': item['lat'],
            'lon': item['lon'],
          };
        })
        .where((item) => item['city']!.isNotEmpty)
        .toList();
  }
}
