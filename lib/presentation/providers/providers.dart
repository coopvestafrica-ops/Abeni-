import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// -------------------- Products --------------------

final productsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(productRepositoryProvider).fetchAll();
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

// -------------------- Cart --------------------

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
  CartNotifier() : super(const CartState());

  void addItem(Product product, ProductUnit unit, int quantity) {
    final key = '${product.id}::${unit.unitName}';
    final existing =
        state.items.indexWhere((i) => i.key == key);
    final updated = [...state.items];
    if (existing >= 0) {
      final old = updated[existing];
      updated[existing] = old.copyWith(quantity: old.quantity + quantity);
    } else {
      updated.add(CartItem(
        product: product,
        unit: unit,
        quantity: quantity,
      ));
    }
    state = state.copyWith(items: updated);
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
  }

  void removeItem(String key) {
    state = state.copyWith(
      items: state.items.where((i) => i.key != key).toList(),
    );
  }

  void clear() {
    state = const CartState();
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());

// -------------------- Orders --------------------

final myOrdersProvider = FutureProvider<List<AbeniOrder>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(orderRepositoryProvider).ordersForUser(user.id);
});
