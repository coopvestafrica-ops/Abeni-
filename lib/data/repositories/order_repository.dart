import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/order_line.dart';
import '../services/firebase_service.dart';

class OrderRepository {
  OrderRepository();

  static const Uuid _uuid = Uuid();

  /// In-memory store used in demo mode.
  static final List<AbeniOrder> _demoOrders = [];

  bool get _useFirebase => FirebaseService.isInitialized;

  Future<AbeniOrder> placeOrder({
    required String userId,
    required List<CartItem> items,
    required FulfillmentType fulfillmentType,
    required PaymentMethod paymentMethod,
    required String deliveryAddress,
    required String phone,
    required double deliveryFee,
  }) async {
    final lines = items.map(OrderLine.fromCartItem).toList();
    final subtotal =
        lines.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final fee =
        fulfillmentType == FulfillmentType.delivery ? deliveryFee : 0.0;
    final order = AbeniOrder(
      id: _uuid.v4().substring(0, 8).toUpperCase(),
      userId: userId,
      items: lines,
      subtotal: subtotal,
      deliveryFee: fee,
      total: subtotal + fee,
      fulfillmentType: fulfillmentType,
      paymentMethod: paymentMethod,
      deliveryAddress: deliveryAddress,
      phone: phone,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
    );

    if (_useFirebase) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(order.id)
            .set(order.toMap())
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Keep a local copy so the user still sees their order in history.
        _demoOrders.insert(0, order);
      }
    } else {
      _demoOrders.insert(0, order);
    }
    return order;
  }

  Future<List<AbeniOrder>> ordersForUser(String userId) async {
    if (_useFirebase) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .get()
            .timeout(const Duration(seconds: 8));
        final list = snap.docs
            .map((d) => AbeniOrder.fromMap(d.id, d.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        // Merge any locally-cached orders for this user (e.g. ones that
        // could not be written because of permission-denied).
        final local = _demoOrders.where((o) => o.userId == userId);
        for (final o in local) {
          if (!list.any((x) => x.id == o.id)) list.insert(0, o);
        }
        return list;
      } catch (_) {
        return _demoOrders.where((o) => o.userId == userId).toList();
      }
    }
    return _demoOrders.where((o) => o.userId == userId).toList();
  }
}
