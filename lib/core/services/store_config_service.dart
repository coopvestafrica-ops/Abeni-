import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/services/firebase_service.dart';

/// Fetches live store configuration from Firestore.
///
/// Firestore schema (optional — all fields have sensible defaults):
///   /store_config/main
///     deliveryFee: 1500        (number, Naira)
///     minOrderForFreeDelivery: 0  (number, 0 = never free)
///
/// Create this document from the Firebase console or admin panel.
/// If the document does not exist, defaults are used.
class StoreConfigService {
  StoreConfigService._();
  static final StoreConfigService instance = StoreConfigService._();

  static const double defaultDeliveryFee = 1500.0;

  /// Returns a live stream of the delivery fee.
  /// In demo mode it emits the default value once.
  Stream<double> watchDeliveryFee() {
    if (!FirebaseService.isInitialized) {
      return Stream.value(defaultDeliveryFee);
    }
    return FirebaseFirestore.instance
        .collection('store_config')
        .doc('main')
        .snapshots()
        .map((snap) {
      if (!snap.exists) return defaultDeliveryFee;
      final fee = snap.data()?['deliveryFee'];
      return (fee as num?)?.toDouble() ?? defaultDeliveryFee;
    }).handleError((Object e) {
      debugPrint('[StoreConfigService] watchDeliveryFee error: $e');
      return defaultDeliveryFee;
    });
  }

  /// One-shot fetch of the delivery fee.
  Future<double> fetchDeliveryFee() async {
    if (!FirebaseService.isInitialized) return defaultDeliveryFee;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('store_config')
          .doc('main')
          .get()
          .timeout(const Duration(seconds: 5));
      if (!snap.exists) return defaultDeliveryFee;
      final fee = snap.data()?['deliveryFee'];
      return (fee as num?)?.toDouble() ?? defaultDeliveryFee;
    } catch (e) {
      debugPrint('[StoreConfigService] fetchDeliveryFee error: $e');
      return defaultDeliveryFee;
    }
  }
}
