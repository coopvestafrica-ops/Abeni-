import 'package:equatable/equatable.dart';

import 'product.dart';
import 'product_unit.dart';

class CartItem extends Equatable {
  final Product product;
  final ProductUnit unit;
  final int quantity;

  const CartItem({
    required this.product,
    required this.unit,
    required this.quantity,
  });

  double get lineTotal => unit.price * quantity;

  String get key => '${product.id}::${unit.unitName}';

  CartItem copyWith({Product? product, ProductUnit? unit, int? quantity}) =>
      CartItem(
        product: product ?? this.product,
        unit: unit ?? this.unit,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toMap() => {
        'productId': product.id,
        'productName': product.name,
        'imageUrl': product.imageUrl,
        'unitName': unit.unitName,
        'unitPrice': unit.price,
        'quantity': quantity,
        'lineTotal': lineTotal,
      };

  @override
  List<Object?> get props => [product.id, unit.unitName, quantity];
}
