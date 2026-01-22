import '../utils/parse_util.dart';

class RepresentativeModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String country;
  final String state;
  final String stateUf;
  final String city;
  final String description;
  final String email;
  final String phone;

  RepresentativeModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.country,
    required this.state,
    required this.stateUf,
    required this.city,
    required this.description,
    required this.email,
    required this.phone,
  });

  factory RepresentativeModel.fromJson(Map<String, dynamic> json) {
    return RepresentativeModel(
      id: json['representative_id']?.toString() ?? '',
      name: json['representative_name'] ?? '',
      address: json['address'] ?? '',
      latitude: ParseUtil.toDoubleSafe(json['latitude']) ?? 0.0,
      longitude: ParseUtil.toDoubleSafe(json['longitude']) ?? 0.0,
      country: json['country_name'] ?? '',
      state: json['state_name'] ?? '',
      stateUf: json['state_uf'] ?? '',
      city: json['city_name'] ?? '',
      description: json['description_text'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}
