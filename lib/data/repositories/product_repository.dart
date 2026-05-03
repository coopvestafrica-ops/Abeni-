import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/firebase_service.dart';
import '../services/sample_catalog.dart';

class ProductRepository {
  ProductRepository();

  bool get _useFirebase => FirebaseService.isInitialized;

  static const int _pageSize = 20;

  /// One-shot fetch (kept for seeding).
  Future<List<Product>> fetchAll() async {
    if (_useFirebase) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('products')
            .get()
            .timeout(const Duration(seconds: 8));
        if (snap.docs.isEmpty) return SampleCatalog.products;
        return snap.docs
            .map((d) => Product.fromMap(d.id, d.data()))
            .toList();
      } catch (e) {
        debugPrint('[ProductRepository] fetchAll error: $e');
        return SampleCatalog.products;
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return SampleCatalog.products;
  }

  /// Real-time stream of all products. Falls back to sample catalog on error.
  ///
  /// Uses a StreamController so Firestore errors (permission-denied, network)
  /// are converted into data events (sample catalog) instead of terminating
  /// the stream — which would leave the StreamProvider stuck in loading forever.
  Stream<List<Product>> watchProducts() {
    if (!_useFirebase) {
      return Stream.value(SampleCatalog.products);
    }

    final controller = StreamController<List<Product>>();

    final subscription = FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .listen(
      (snap) {
        try {
          final products = snap.docs.isEmpty
              ? SampleCatalog.products
              : snap.docs
                  .map((d) => Product.fromMap(d.id, d.data()))
                  .toList();
          controller.add(products);
        } catch (e) {
          debugPrint('[ProductRepository] watchProducts map error: $e');
          controller.add(SampleCatalog.products);
        }
      },
      onError: (Object e) {
        // On permission-denied or network error, fall back to sample catalog
        // so the home/category screens show something rather than spinning.
        debugPrint('[ProductRepository] watchProducts stream error: $e');
        controller.add(SampleCatalog.products);
      },
      onDone: () => controller.close(),
      cancelOnError: false,
    );

    controller.onCancel = () => subscription.cancel();
    return controller.stream;
  }

  /// Cursor-based paginated fetch. Returns (products, lastDoc, hasMore).
  Future<(List<Product>, DocumentSnapshot?, bool)> fetchPage({
    DocumentSnapshot? cursor,
  }) async {
    if (!_useFirebase) {
      return (SampleCatalog.products, null, false);
    }
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('products')
          .orderBy('productName')
          .limit(_pageSize);
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }
      final snap = await query.get().timeout(const Duration(seconds: 8));
      final products =
          snap.docs.map((d) => Product.fromMap(d.id, d.data())).toList();
      final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
      final hasMore = snap.docs.length >= _pageSize;
      return (products, lastDoc, hasMore);
    } catch (e) {
      debugPrint('[ProductRepository] fetchPage error: $e');
      return (SampleCatalog.products, null, false);
    }
  }

  /// Uploads the sample catalog to Firestore — useful for first-time setup.
  Future<int> seedSampleProducts() async {
    if (!_useFirebase) return 0;
    try {
      final batch = FirebaseFirestore.instance.batch();
      final col = FirebaseFirestore.instance.collection('products');
      for (final p in SampleCatalog.products) {
        batch.set(col.doc(p.id), p.toMap());
      }
      await batch.commit();
      return SampleCatalog.products.length;
    } catch (e) {
      debugPrint('[ProductRepository] seedSampleProducts error: $e');
      return 0;
    }
  }
}
