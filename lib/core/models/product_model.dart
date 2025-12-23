class ProductModel {
  final String id;
  final String productId;
  final String name;
  final String model;
  final String image;
  final String slugCategory;
  final String? slugProduct;
  final dynamic power;
  final dynamic frequency;
  final dynamic rpm;
  final dynamic rateMin;
  final dynamic rateMax;
  final dynamic mcaMin;
  final dynamic mcaMax;
  final String? ecommerceLink;
  final List<ProductModel> variants;

  ProductModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.model,
    required this.image,
    required this.slugCategory,
    this.slugProduct,
    this.power,
    this.frequency,
    this.rpm,
    this.rateMin,
    this.rateMax,
    this.mcaMin,
    this.mcaMax,
    this.ecommerceLink,
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
      power: json['power'],
      frequency: json['frequency'],
      rpm: json['rpm'],
      rateMin: json['rate_min'],
      rateMax: json['rate_max'],
      mcaMin: json['mca_min'],
      mcaMax: json['mca_max'],
      ecommerceLink: json['ecommerce_link'],
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
    };
  }
}
