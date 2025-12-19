import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static const userAgent = 'app-ebara/1.0 (contato@seudominio.com)';
  static const baseUrl = 'https://nominatim.openstreetmap.org';
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

      return parseLocationData(locationData);
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
    final uri = Uri.parse(
      '$baseUrl/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json&addressdetails=1',
    );

    final response = await http.get(uri, headers: {'User-Agent': userAgent});

    if (response.statusCode != 200) {
      return {};
    }

    return json.decode(response.body) as Map<String, dynamic>;
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

    final uri = Uri.parse(
      '$baseUrl/search?q=$query&format=json&addressdetails=1&limit=$searchLimit&extratags=0',
    );

    final response = await http.get(uri, headers: {'User-Agent': userAgent});

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to search cities. Status: ${response.statusCode}',
      );
    }

    final data = json.decode(response.body) as List<dynamic>;
    return parseCitySearchResults(data);
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
          };
        })
        .where((item) => item['city']!.isNotEmpty)
        .toList();
  }
}
