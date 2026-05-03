import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../core/services/store_config_service.dart';
import '../../data/models/app_user.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/order.dart';
import '../../data/models/product.dart';
import '../../data/models/product_unit.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/product_repository.dart';

// -------------------- Repositories --------------------

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());

final productRepositoryProvider =
    Provider<ProductRepository>((ref) => ProductRepository());

final orderRepositoryProvider =
    Provider<OrderRepository>((ref) => OrderRepository());

// -------------------- Auth --------------------

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).value;
});

// -------------------- Products (real-time stream) --------------------

final productsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchProducts();
});

final productsByCategoryProvider =
    Provider.family<AsyncValue<List<Product>>, String>((ref, categoryId) {
  return ref.watch(productsProvider).whenData(
        (products) =>
            products.where((p) => p.categoryId == categoryId).toList(),
      );
});

final featuredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref.watch(productsProvider).whenData(
        (products) => products.where((p) => p.featured).toList(),
      );
});

// -------------------- Paginated Products --------------------

class PaginatedProductsState {
  final List<Product> products;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  const PaginatedProductsState({
    this.products = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  PaginatedProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) =>
      PaginatedProductsState(
        products: products ?? this.products,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );
}

class PaginatedProductsNotifier
    extends StateNotifier<PaginatedProductsState> {
  final ProductRepository _repo;
  DocumentSnapshot? _lastDoc;

  PaginatedProductsNotifier(this._repo)
      : super(const PaginatedProductsState()) {
    loadFirst();
  }

  Future<void> loadFirst() async {
    state = const PaginatedProductsState(isLoading: true);
    _lastDoc = null;
    await _load(reset: true);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    await _load(reset: false);
  }

  Future<void> _load({required bool reset}) async {
    try {
      final (products, last, hasMore) =
          await _repo.fetchPage(cursor: _lastDoc);
      _lastDoc = last;
      final merged =
          reset ? products : [...state.products, ...products];
      state = PaginatedProductsState(
        products: merged,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final paginatedProductsProvider = StateNotifierProvider<
    PaginatedProductsNotifier, PaginatedProductsState>((ref) {
  return PaginatedProductsNotifier(ref.watch(productRepositoryProvider));
});

// -------------------- Store Config --------------------

final deliveryFeeProvider = StreamProvider<double>((ref) {
  return StoreConfigService.instance.watchDeliveryFee();
});

// -------------------- Cart --------------------

const _cartPrefsKey = 'abeni_cart_v1';

class CartState {
  final List<CartItem> items;
  const CartState({this.items = const []});

  double get subtotal =>
      items.fold<double>(0, (sum, item) => sum + item.lineTotal);

  int get count => items.fold<int>(0, (sum, item) => sum + item.quantity);

  CartState copyWith({List<CartItem>? items}) =>
      CartState(items: items ?? this.items);
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cartPrefsKey);
      if (raw == null) return;
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      final items = list
          .map((e) => _cartItemFromJson(e as Map<String, dynamic>))
          .whereType<CartItem>()
          .toList();
      state = CartState(items: items);
    } catch (e) {
      // Corrupted prefs — start fresh
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = state.items.map(_cartItemToJson).toList();
      await prefs.setString(_cartPrefsKey, jsonEncode(list));
    } catch (_) {}
  }

  static Map<String, dynamic> _cartItemToJson(CartItem item) => {
        'product': {
          'id': item.product.id,
          'name': item.product.name,
          'categoryId': item.product.categoryId,
          'description': item.product.description,
          'imageUrl': item.product.imageUrl,
          'featured': item.product.featured,
          'units': item.product.units
              .map((u) => {
                    'unitName': u.unitName,
                    'price': u.price,
                    'stock': u.stock,
                  })
              .toList(),
        },
        'unitName': item.unit.unitName,
        'quantity': item.quantity,
      };

  static CartItem? _cartItemFromJson(Map<String, dynamic> map) {
    try {
      final pMap = map['product'] as Map<String, dynamic>;
      final units = (pMap['units'] as List<dynamic>)
          .map((u) => ProductUnit(
                unitName: u['unitName'] as String,
                price: (u['price'] as num).toDouble(),
                stock: (u['stock'] as num).toInt(),
              ))
          .toList();
      final product = Product(
        id: pMap['id'] as String,
        name: pMap['name'] as String,
        categoryId: pMap['categoryId'] as String,
        description: pMap['description'] as String,
        imageUrl: pMap['imageUrl'] as String,
        featured: pMap['featured'] as bool? ?? false,
        units: units,
      );
      final unitName = map['unitName'] as String;
      final unit = product.unitByName(unitName);
      if (unit == null) return null;
      return CartItem(
        product: product,
        unit: unit,
        quantity: (map['quantity'] as num).toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  void addItem(Product product, ProductUnit unit, int quantity) {
    final key = '${product.id}::${unit.unitName}';
    final existing = state.items.indexWhere((i) => i.key == key);
    final updated = [...state.items];
    if (existing >= 0) {
      final old = updated[existing];
      updated[existing] = old.copyWith(quantity: old.quantity + quantity);
    } else {
      updated.add(CartItem(product: product, unit: unit, quantity: quantity));
    }
    state = state.copyWith(items: updated);
    _saveToPrefs();
  }

  void updateQuantity(String key, int quantity) {
    final items = [
      for (final item in state.items)
        if (item.key == key)
          item.copyWith(quantity: quantity)
        else
          item,
    ]..removeWhere((i) => i.quantity <= 0);
    state = state.copyWith(items: items);
    _saveToPrefs();
  }

  void removeItem(String key) {
    state = state.copyWith(
      items: state.items.where((i) => i.key != key).toList(),
    );
    _saveToPrefs();
  }

  void clear() {
    state = const CartState();
    _saveToPrefs();
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());

// -------------------- Orders (real-time stream) --------------------

final myOrdersProvider = StreamProvider<List<AbeniOrder>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(orderRepositoryProvider).watchUserOrders(user.id);
});

// -------------------- Cancel Order --------------------

final cancelOrderProvider =
    FutureProvider.family<void, String>((ref, orderId) async {
  await ref.read(orderRepositoryProvider).cancelOrder(orderId);
});

// -------------------- Notification Route --------------------

/// Set to a route path when the user taps a push notification.
/// A listener in main.dart navigates and then resets this to null.
final notificationRouteProvider = StateProvider<String?>((ref) => null);
