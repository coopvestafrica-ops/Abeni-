import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import '../services/firebase_service.dart';
import '../services/sample_catalog.dart';

class ProductRepository {
  ProductRepository();

  bool get _useFirebase => FirebaseService.isInitialized;

  Future<List<Product>> fetchAll() async {
    if (_useFirebase) {
      final snap =
          await FirebaseFirestore.instance.collection('products').get();
      if (snap.docs.isEmpty) {
        return SampleCatalog.products;
      }
      return snap.docs
          .map((d) => Product.fromMap(d.id, d.data()))
          .toList();
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return SampleCatalog.products;
  }

  /// Uploads the sample catalog to Firestore — useful for first-time setup.
  /// No-op in demo mode.
  Future<int> seedSampleProducts() async {
    if (!_useFirebase) return 0;
    final batch = FirebaseFirestore.instance.batch();
    final col = FirebaseFirestore.instance.collection('products');
    for (final p in SampleCatalog.products) {
      batch.set(col.doc(p.id), p.toMap());
    }
    await batch.commit();
    return SampleCatalog.products.length;
  }
}
