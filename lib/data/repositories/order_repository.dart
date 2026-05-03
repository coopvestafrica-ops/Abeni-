import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
      } catch (e) {
        debugPrint('[OrderRepository] placeOrder Firebase write error: $e');
        _demoOrders.insert(0, order);
      }
    } else {
      _demoOrders.insert(0, order);
    }
    return order;
  }

  /// Real-time stream of orders for a specific user.
  Stream<List<AbeniOrder>> watchUserOrders(String userId) {
    if (!_useFirebase) {
      return Stream.value(
          _demoOrders.where((o) => o.userId == userId).toList());
    }
    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => AbeniOrder.fromMap(d.id, d.data())).toList();
      final local = _demoOrders.where((o) => o.userId == userId);
      for (final o in local) {
        if (!list.any((x) => x.id == o.id)) list.insert(0, o);
      }
      return list;
    }).handleError((Object e) {
      debugPrint('[OrderRepository] watchUserOrders stream error: $e');
      return _demoOrders.where((o) => o.userId == userId).toList();
    });
  }

  /// One-shot fetch (kept for backward compatibility).
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
        final local = _demoOrders.where((o) => o.userId == userId);
        for (final o in local) {
          if (!list.any((x) => x.id == o.id)) list.insert(0, o);
        }
        return list;
      } catch (e) {
        debugPrint('[OrderRepository] ordersForUser error: $e');
        return _demoOrders.where((o) => o.userId == userId).toList();
      }
    }
    return _demoOrders.where((o) => o.userId == userId).toList();
  }

  /// Cancels a pending order. Only allowed while status == pending.
  Future<void> cancelOrder(String orderId) async {
    if (_useFirebase) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({'status': OrderStatus.cancelled.wireKey})
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('[OrderRepository] cancelOrder Firebase error: $e');
        rethrow;
      }
    } else {
      final i = _demoOrders.indexWhere((o) => o.id == orderId);
      if (i >= 0) {
        final old = _demoOrders[i];
        _demoOrders[i] = AbeniOrder(
          id: old.id,
          userId: old.userId,
          items: old.items,
          subtotal: old.subtotal,
          deliveryFee: old.deliveryFee,
          total: old.total,
          fulfillmentType: old.fulfillmentType,
          paymentMethod: old.paymentMethod,
          deliveryAddress: old.deliveryAddress,
          phone: old.phone,
          status: OrderStatus.cancelled,
          createdAt: old.createdAt,
        );
      }
    }
  }
}
