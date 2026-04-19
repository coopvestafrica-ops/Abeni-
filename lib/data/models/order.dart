import 'package:equatable/equatable.dart';

import 'order_line.dart';

enum OrderStatus { pending, processing, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'processing':
        return OrderStatus.processing;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }
}

enum FulfillmentType { delivery, pickup }

extension FulfillmentTypeX on FulfillmentType {
  String get label => this == FulfillmentType.delivery ? 'Delivery' : 'Pickup';

  static FulfillmentType fromString(String? v) =>
      (v ?? '').toLowerCase() == 'pickup'
          ? FulfillmentType.pickup
          : FulfillmentType.delivery;
}

enum PaymentMethod { payOnDelivery, bankTransfer }

extension PaymentMethodX on PaymentMethod {
  String get label => this == PaymentMethod.payOnDelivery
      ? 'Pay on Delivery'
      : 'Bank Transfer';

  static PaymentMethod fromString(String? v) =>
      (v ?? '').toLowerCase() == 'banktransfer'
          ? PaymentMethod.bankTransfer
          : PaymentMethod.payOnDelivery;
}

class AbeniOrder extends Equatable {
  final String id;
  final String userId;
  final List<OrderLine> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final FulfillmentType fulfillmentType;
  final PaymentMethod paymentMethod;
  final String deliveryAddress;
  final String phone;
  final OrderStatus status;
  final DateTime createdAt;

  const AbeniOrder({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.fulfillmentType,
    required this.paymentMethod,
    required this.deliveryAddress,
    required this.phone,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'fulfillmentType':
            fulfillmentType == FulfillmentType.delivery ? 'delivery' : 'pickup',
        'paymentMethod': paymentMethod == PaymentMethod.bankTransfer
            ? 'bankTransfer'
            : 'payOnDelivery',
        'deliveryAddress': deliveryAddress,
        'phone': phone,
        'status': status.label.toLowerCase(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory AbeniOrder.fromMap(String id, Map<String, dynamic> map) => AbeniOrder(
        id: id,
        userId: (map['userId'] ?? '') as String,
        items: ((map['items'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => OrderLine.fromMap(Map<String, dynamic>.from(m)))
            .toList(),
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
        deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0,
        total: (map['total'] as num?)?.toDouble() ?? 0,
        fulfillmentType:
            FulfillmentTypeX.fromString(map['fulfillmentType'] as String?),
        paymentMethod:
            PaymentMethodX.fromString(map['paymentMethod'] as String?),
        deliveryAddress: (map['deliveryAddress'] ?? '') as String,
        phone: (map['phone'] ?? '') as String,
        status: OrderStatusX.fromString(map['status'] as String?),
        createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );

  @override
  List<Object?> get props => [id, userId, items, total, status, createdAt];
}
