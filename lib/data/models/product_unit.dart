import 'package:equatable/equatable.dart';

/// A purchasable measurement option for a product.
/// Examples: "Congo" of rice at ₦2,500, "Bag" of beans at ₦78,000.
class ProductUnit extends Equatable {
  final String unitName;
  final double price;
  final int stock;

  const ProductUnit({
    required this.unitName,
    required this.price,
    required this.stock,
  });

  bool get inStock => stock > 0;

  Map<String, dynamic> toMap() => {
        'unitName': unitName,
        'price': price,
        'stock': stock,
      };

  factory ProductUnit.fromMap(Map<String, dynamic> map) => ProductUnit(
        unitName: (map['unitName'] ?? '') as String,
        price: (map['price'] as num?)?.toDouble() ?? 0,
        stock: (map['stock'] as num?)?.toInt() ?? 0,
      );

  ProductUnit copyWith({String? unitName, double? price, int? stock}) =>
      ProductUnit(
        unitName: unitName ?? this.unitName,
        price: price ?? this.price,
        stock: stock ?? this.stock,
      );

  @override
  List<Object?> get props => [unitName, price, stock];
}
