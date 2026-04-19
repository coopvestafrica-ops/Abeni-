import 'package:equatable/equatable.dart';

import 'cart_item.dart';

/// Snapshot of a purchased item — what actually lives on an order.
/// Separate from [CartItem] so that reading an old order from Firestore
/// does not depend on rebuilding full [Product] / [ProductUnit] objects.
class OrderLine extends Equatable {
  final String productId;
  final String productName;
  final String imageUrl;
  final String unitName;
  final double unitPrice;
  final int quantity;

  const OrderLine({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.unitName,
    required this.unitPrice,
    required this.quantity,
  });

  double get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'imageUrl': imageUrl,
        'unitName': unitName,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'lineTotal': lineTotal,
      };

  factory OrderLine.fromMap(Map<String, dynamic> map) => OrderLine(
        productId: (map['productId'] ?? '') as String,
        productName: (map['productName'] ?? '') as String,
        imageUrl: (map['imageUrl'] ?? '') as String,
        unitName: (map['unitName'] ?? '') as String,
        unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      );

  factory OrderLine.fromCartItem(CartItem item) => OrderLine(
        productId: item.product.id,
        productName: item.product.name,
        imageUrl: item.product.imageUrl,
        unitName: item.unit.unitName,
        unitPrice: item.unit.price,
        quantity: item.quantity,
      );

  @override
  List<Object?> get props =>
      [productId, productName, unitName, unitPrice, quantity];
}
