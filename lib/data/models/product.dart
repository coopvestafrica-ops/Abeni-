import 'package:equatable/equatable.dart';

import 'product_unit.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String categoryId;
  final String description;
  final String imageUrl;
  final List<ProductUnit> units;
  final bool featured;

  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.description,
    required this.imageUrl,
    required this.units,
    this.featured = false,
  });

  double get startingPrice {
    if (units.isEmpty) return 0;
    return units.map((u) => u.price).reduce((a, b) => a < b ? a : b);
  }

  bool get hasStock => units.any((u) => u.inStock);

  ProductUnit? unitByName(String name) {
    for (final u in units) {
      if (u.unitName == name) return u;
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
        'productId': id,
        'productName': name,
        'categoryId': categoryId,
        'description': description,
        'imageUrl': imageUrl,
        'featured': featured,
        'units': units.map((u) => u.toMap()).toList(),
      };

  factory Product.fromMap(String id, Map<String, dynamic> map) => Product(
        id: (map['productId'] ?? id) as String,
        name: (map['productName'] ?? '') as String,
        categoryId: (map['categoryId'] ?? '') as String,
        description: (map['description'] ?? '') as String,
        imageUrl: (map['imageUrl'] ?? '') as String,
        featured: (map['featured'] ?? false) as bool,
        units: ((map['units'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => ProductUnit.fromMap(Map<String, dynamic>.from(m)))
            .toList(),
      );

  @override
  List<Object?> get props =>
      [id, name, categoryId, description, imageUrl, units, featured];
}
