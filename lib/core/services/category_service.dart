import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class CategoryService {
  static const String _baseUrl = 'https://ebara.com.br/api';

  static const Map<String, IconData> _categoryIcons = {
    'bombas-centrifugas': Icons.tune,
    'bombas-submersas': Icons.water,
    'bombas-submersiveis': Icons.water_drop,
    'sistema-solar-ecaros-1': Icons.wb_sunny,
    'sistemas-de-pressurizacao-1': Icons.compress,
    'industrial': Icons.factory,
    'residencial': Icons.home,
    '22': Icons.tune,
    '23': Icons.water,
    '24': Icons.water_drop,
    '26': Icons.wb_sunny,
    '27': Icons.compress,
    '28': Icons.factory,
    '29': Icons.home,
  };

  static List<Map<String, dynamic>>? _cachedCategories;

  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    if (_cachedCategories != null) {
      return _cachedCategories!;
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/categories'),
      headers: {
        'Content-Type': 'application/json',
        'api-version': "1",
        'api-token': "EZTHB1985",
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
        final List<dynamic> data = jsonResponse['data'];

        List<Map<String, dynamic>> mainCategories = [];

        for (var category in data) {
          mainCategories.add(_mapCategory(category));
        }

        _cachedCategories = mainCategories;
        return mainCategories;
      } else {
        throw Exception('Resposta da API inválida');
      }
    } else {
      throw Exception('Falha ao carregar categorias: ${response.statusCode}');
    }
  }

  static Map<String, dynamic> _mapCategory(
    Map<String, dynamic> category, {
    bool isChild = false,
  }) {
    final String id = category['id'] ?? '';
    final String title = category['title'] ?? '';
    final String slug = category['slug'] ?? '';
    final String subtitle = category['subtitle'] ?? '';

    return {
      'id': id,
      'slug': slug,
      'title': title,
      'subtitle': subtitle,
      'icon': _getIconForCategory(slug, id),
      'id_icon': category['id_icon'],
      'id_image_app': category['id_image_app'],
      'image': category['image'],
      'icon_filename': category['icon'],
      'image_app_filename': category['image_app'],
      'status': category['status'],
      'status_app': category['status_app'],
      'type': category['type'],
      'isChild': isChild,
      'appSearchVariationUp': category['appSearchVariationUp'],
      'appSearchVariationDown': category['appSearchVariationDown'],
      'appMaxResults': category['appMaxResults'],
      'related': category['related'],
      'useRelated': category['useRelated'],
    };
  }

  static IconData _getIconForCategory(String slug, String id) {
    if (_categoryIcons.containsKey(slug)) {
      return _categoryIcons[slug]!;
    }

    if (_categoryIcons.containsKey(id)) {
      return _categoryIcons[id]!;
    }

    return Icons.category;
  }

  static Future<Map<String, dynamic>?> getCategoryBySlug(String slug) async {
    final categories = await fetchCategories();
    try {
      return categories.firstWhere((cat) => cat['slug'] == slug);
    } catch (e) {
      return null;
    }
  }

  static List<Map<String, dynamic>> filterMainCategories(
    List<Map<String, dynamic>> categories,
  ) {
    return categories.where((cat) => cat['isChild'] == false).toList();
  }

  static List<Map<String, dynamic>> filterSubCategories(
    List<Map<String, dynamic>> categories,
  ) {
    return categories.where((cat) => cat['isChild'] == true).toList();
  }

  static void clearCache() {
    _cachedCategories = null;
  }
}
