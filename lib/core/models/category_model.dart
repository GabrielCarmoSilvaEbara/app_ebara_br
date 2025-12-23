import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String slug;
  final String title;
  final String subtitle;
  final IconData? icon;
  final String? image;

  CategoryModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.subtitle,
    this.icon,
    this.image,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json, {IconData? icon}) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      image: json['image'],
      icon: icon,
    );
  }
}
