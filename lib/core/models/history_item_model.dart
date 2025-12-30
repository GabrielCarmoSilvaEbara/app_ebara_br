import 'dart:convert';

class HistoryItemModel {
  final String id;
  final String name;
  final String model;
  final String image;
  final String category;
  final int timestamp;
  final List<dynamic> variants;

  HistoryItemModel({
    required this.id,
    required this.name,
    required this.model,
    required this.image,
    required this.category,
    required this.timestamp,
    required this.variants,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'model': model,
      'image': image,
      'history_category': category,
      'timestamp': timestamp,
      'variants': variants,
    };
  }

  factory HistoryItemModel.fromMap(Map<String, dynamic> map) {
    return HistoryItemModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      model: map['model'] ?? '',
      image: map['image'] ?? '',
      category: map['history_category'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      variants: map['variants'] ?? [],
    );
  }

  String toJson() => json.encode(toMap());

  factory HistoryItemModel.fromJson(String source) =>
      HistoryItemModel.fromMap(json.decode(source));
}
