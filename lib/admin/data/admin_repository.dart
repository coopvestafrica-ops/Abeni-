import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/app_user.dart';
import '../../data/models/order.dart';
import '../../data/models/product.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/sample_catalog.dart';

/// Admin-side aggregate repository.
///
/// Reads from / writes to the same Firestore collections as the customer
/// app:
///   - `users`             — customer + admin profiles
///   - `orders`            — every customer order
///   - `products`          — catalog
///   - `broadcasts`        — store-wide messages
///   - `customer_messages` — per-customer direct messages from the admin
///
/// When Firebase isn't initialised (demo mode) the repository falls back
/// to the in-memory sample data so the admin app's UI is still navigable.
class AdminRepository {
  AdminRepository();

  bool get _useFirebase => FirebaseService.isInitialized;

  // --------------------------------------------------------------- orders ---

  /// Live list of every order, newest first.
  Stream<List<AbeniOrder>> watchAllOrders() {
    if (!_useFirebase) {
      return Stream.value(_demoOrders());
    }
    return FirebaseFirestore.instance
        .collection('orders')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => AbeniOrder.fromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Update an order's status. Fires a notification record so the customer
  /// receives a push via Cloud Functions on the `customer_messages` collection.
  Future<void> updateOrderStatus({
    required AbeniOrder order,
    required OrderStatus newStatus,
    String? note,
  }) async {
    if (!_useFirebase) return;
    final batch = FirebaseFirestore.instance.batch();
    final orderRef =
        FirebaseFirestore.instance.collection('orders').doc(order.id);
    batch.update(orderRef, {
      'status': newStatus.wireKey,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
      if (note != null && note.isNotEmpty) 'lastNote': note,
    });
    final notifRef = FirebaseFirestore.instance
        .collection('customer_messages')
        .doc();
    batch.set(notifRef, {
      'userId': order.userId,
      'orderId': order.id,
      'type': 'order_status',
      'status': newStatus.wireKey,
      'title': _statusTitle(newStatus),
      'body': _statusBody(order.id, newStatus, note: note),
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
    await batch.commit();
  }

  /// Append an internal note to an order. Visible only to admin/staff.
  Future<void> addOrderNote({
    required String orderId,
    required String authorName,
    required String note,
  }) async {
    if (!_useFirebase) return;
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .collection('notes')
        .add({
      'authorName': authorName,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark a bank-transfer order as paid (admin manually verified the
  /// transfer in Opay). Customer is notified.
  Future<void> markPaymentReceived(AbeniOrder order) async {
    if (!_useFirebase) return;
    final batch = FirebaseFirestore.instance.batch();
    final orderRef =
        FirebaseFirestore.instance.collection('orders').doc(order.id);
    batch.update(orderRef, {
      'paymentReceived': true,
      'paymentReceivedAt': FieldValue.serverTimestamp(),
    });
    final notifRef = FirebaseFirestore.instance
        .collection('customer_messages')
        .doc();
    batch.set(notifRef, {
      'userId': order.userId,
      'orderId': order.id,
      'type': 'payment_confirmed',
      'title': 'Payment confirmed',
      'body':
          'We\'ve received your payment for order #${order.id}. Thank you!',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
    await batch.commit();
  }

  /// Permanently delete a single order document.
  Future<void> deleteOrder(String orderId) async {
    if (!_useFirebase) return;
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .delete();
  }

  /// Delete all orders with status [delivered] or [cancelled].
  /// Returns the number of orders deleted.
  Future<int> clearCompletedOrders() async {
    if (!_useFirebase) return 0;
    final snap = await FirebaseFirestore.instance
        .collection('orders')
        .where('status', whereIn: [
          OrderStatus.delivered.wireKey,
          OrderStatus.cancelled.wireKey,
        ])
        .get();
    if (snap.docs.isEmpty) return 0;
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return snap.docs.length;
  }

  // ------------------------------------------------------------- products ---

  Stream<List<Product>> watchAllProducts() {
    if (!_useFirebase) {
      return Stream.value(SampleCatalog.products);
    }
    return FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return SampleCatalog.products;
      return snap.docs.map((d) => Product.fromMap(d.id, d.data())).toList();
    });
  }

  Future<void> upsertProduct(Product product) async {
    if (!_useFirebase) return;
    await FirebaseFirestore.instance
        .collection('products')
        .doc(product.id)
        .set(product.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteProduct(String productId) async {
    if (!_useFirebase) return;
    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .delete();
  }

  // -------------------------------------------------------------- users ---

  Stream<List<AppUser>> watchAllUsers() {
    if (!_useFirebase) return Stream.value(const []);
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppUser.fromMap({...d.data(), 'id': d.id}))
            .toList()
          ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase())));
  }

  Future<void> updateUserRole(String userId, UserRole role) async {
    if (!_useFirebase) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set({'role': role.wireKey}, SetOptions(merge: true));
  }

  // --------------------------------------------------------- broadcasts ---

  Future<void> sendBroadcast({
    required String authorName,
    required String title,
    required String body,
  }) async {
    if (!_useFirebase) return;
    await FirebaseFirestore.instance.collection('broadcasts').add({
      'title': title,
      'body': body,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Send a direct message to a single customer.
  Future<void> sendDirectMessage({
    required String userId,
    required String title,
    required String body,
  }) async {
    if (!_useFirebase) return;
    await FirebaseFirestore.instance.collection('customer_messages').add({
      'userId': userId,
      'type': 'direct',
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  // ----------------------------------------------------------- helpers ---

  List<AbeniOrder> _demoOrders() => const [];

  String _statusTitle(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 'Order received';
      case OrderStatus.processing:
        return 'Order is being prepared';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.delivered:
        return 'Order delivered';
      case OrderStatus.cancelled:
        return 'Order cancelled';
    }
  }

  String _statusBody(String orderId, OrderStatus s, {String? note}) {
    final base = () {
      switch (s) {
        case OrderStatus.pending:
          return 'Order #$orderId is now pending.';
        case OrderStatus.processing:
          return 'We are preparing order #$orderId for you.';
        case OrderStatus.outForDelivery:
          return 'Order #$orderId is on its way.';
        case OrderStatus.delivered:
          return 'Order #$orderId has been delivered. Enjoy!';
        case OrderStatus.cancelled:
          return 'Order #$orderId was cancelled.';
      }
    }();
    if (note == null || note.isEmpty) return base;
    return '$base\nNote: $note';
  }
}
