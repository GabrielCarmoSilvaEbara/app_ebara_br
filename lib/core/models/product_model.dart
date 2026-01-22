import '../utils/parse_util.dart';

class ProductModel {
  final String id;
  final String productId;
  final String name;
  final String model;
  final String image;
  final String slugCategory;
  final String? slugProduct;
  final double power;
  final double frequency;
  final double rpm;
  final double rateMin;
  final double rateMax;
  final double mcaMin;
  final double mcaMax;
  final String? ecommerceLink;
  final String brandId;
  final List<ProductModel> variants;

  ProductModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.model,
    required this.image,
    required this.slugCategory,
    this.slugProduct,
    this.power = 0.0,
    this.frequency = 0.0,
    this.rpm = 0.0,
    this.rateMin = 0.0,
    this.rateMax = 0.0,
    this.mcaMin = 0.0,
    this.mcaMax = 0.0,
    this.ecommerceLink,
    this.brandId = '',
    this.variants = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      productId: json['id_product']?.toString() ?? '',
      name: json['title_product'] ?? json['name'] ?? '',
      model: json['model'] ?? '',
      image: json['file'] ?? json['image'] ?? '',
      slugCategory: json['slug_category'] ?? '',
      slugProduct: json['slug_product'],
      power: ParseUtil.toDoubleSafe(json['power']) ?? 0.0,
      frequency: ParseUtil.toDoubleSafe(json['frequency']) ?? 0.0,
      rpm: ParseUtil.toDoubleSafe(json['rpm']) ?? 0.0,
      rateMin: ParseUtil.toDoubleSafe(json['rate_min']) ?? 0.0,
      rateMax: ParseUtil.toDoubleSafe(json['rate_max']) ?? 0.0,
      mcaMin: ParseUtil.toDoubleSafe(json['mca_min']) ?? 0.0,
      mcaMax: ParseUtil.toDoubleSafe(json['mca_max']) ?? 0.0,
      ecommerceLink: json['ecommerce_link'],
      brandId: json['id_brand']?.toString() ?? '',
      variants: json['variants'] != null
          ? (json['variants'] as List)
                .map((v) => ProductModel.fromJson(v))
                .toList()
          : [],
    );
  }

  ProductModel copyWith({List<ProductModel>? variants}) {
    return ProductModel(
      id: id,
      productId: productId,
      name: name,
      model: model,
      image: image,
      slugCategory: slugCategory,
      slugProduct: slugProduct,
      power: power,
      frequency: frequency,
      rpm: rpm,
      rateMin: rateMin,
      rateMax: rateMax,
      mcaMin: mcaMin,
      mcaMax: mcaMax,
      ecommerceLink: ecommerceLink,
      brandId: brandId,
      variants: variants ?? this.variants,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_product': productId,
      'name': name,
      'model': model,
      'image': image,
      'power': power,
      'rpm': rpm,
      'mca_max': mcaMax,
      'rate_max': rateMax,
      'frequency': frequency,
      'ecommerce_link': ecommerceLink,
      'id_brand': brandId,
      'variants': variants.map((x) => x.toMap()).toList(),
    };
  }
}
