import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static const _userAgent = 'app-ebara/1.0 (contato@seudominio.com)';

  static Future<Map<String, String>?> getCurrentCity() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${position.latitude}'
        '&lon=${position.longitude}'
        '&format=json'
        '&addressdetails=1',
      );

      final response = await http.get(uri, headers: {'User-Agent': _userAgent});

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      final address = data['address'] ?? {};

      return {
        'address_type': data['addresstype'] ?? '',
        'city':
            address['city'] ??
            address['town'] ??
            address['village'] ??
            address['municipality'] ??
            '',
        'district':
            address['city_district'] ??
            address['suburb'] ??
            address['neighbourhood'] ??
            '',
        'state': address['state'] ?? '',
        'country': address['country'] ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, String>>> searchCities({
    required String query,
  }) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=$query'
      '&format=json'
      '&addressdetails=1'
      '&limit=10',
    );

    final response = await http.get(uri, headers: {'User-Agent': _userAgent});

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar cidades');
    }

    final List data = json.decode(response.body);

    return data
        .where((item) {
          final type = item['addresstype'];
          return type == 'municipality';
        })
        .map<Map<String, String>>((item) {
          final address = item['address'] ?? {};

          return {
            'address_type': item['addresstype'] ?? '',
            'city':
                address['city'] ??
                address['town'] ??
                address['village'] ??
                address['municipality'] ??
                '',
            'state': address['state'] ?? '',
            'country': address['country'] ?? '',
          };
        })
        .where((item) => item['city']!.isNotEmpty)
        .toList();
  }
}
