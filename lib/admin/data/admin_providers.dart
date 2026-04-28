import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user.dart';
import '../../data/models/order.dart';
import '../../data/models/product.dart';
import 'admin_repository.dart';

final adminRepositoryProvider =
    Provider<AdminRepository>((ref) => AdminRepository());

final adminAllOrdersProvider = StreamProvider<List<AbeniOrder>>((ref) {
  return ref.watch(adminRepositoryProvider).watchAllOrders();
});

final adminAllProductsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(adminRepositoryProvider).watchAllProducts();
});

final adminAllUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(adminRepositoryProvider).watchAllUsers();
});

/// Quick filter for the orders dashboard.
final adminOrderStatusFilterProvider =
    StateProvider<OrderStatus?>((_) => null);

final adminOrderSearchProvider = StateProvider<String>((_) => '');

final adminFilteredOrdersProvider =
    Provider<AsyncValue<List<AbeniOrder>>>((ref) {
  final orders = ref.watch(adminAllOrdersProvider);
  final filter = ref.watch(adminOrderStatusFilterProvider);
  final query = ref.watch(adminOrderSearchProvider).trim().toLowerCase();
  return orders.whenData((list) {
    Iterable<AbeniOrder> result = list;
    if (filter != null) {
      result = result.where((o) => o.status == filter);
    }
    if (query.isNotEmpty) {
      result = result.where((o) =>
          o.id.toLowerCase().contains(query) ||
          o.phone.toLowerCase().contains(query) ||
          o.deliveryAddress.toLowerCase().contains(query) ||
          o.items.any((it) =>
              it.productName.toLowerCase().contains(query)));
    }
    return result.toList();
  });
});

/// Snapshot revenue + counts for the dashboard summary cards.
class SalesSummary {
  final int orderCount;
  final double revenue;
  const SalesSummary({required this.orderCount, required this.revenue});
}

final adminTodaySummaryProvider = Provider<AsyncValue<SalesSummary>>((ref) {
  final orders = ref.watch(adminAllOrdersProvider);
  return orders.whenData((list) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final filtered = list.where((o) =>
        o.createdAt.isAfter(start) &&
        o.status != OrderStatus.cancelled);
    return SalesSummary(
      orderCount: filtered.length,
      revenue:
          filtered.fold<double>(0, (sum, o) => sum + o.total),
    );
  });
});

final adminWeekSummaryProvider = Provider<AsyncValue<SalesSummary>>((ref) {
  final orders = ref.watch(adminAllOrdersProvider);
  return orders.whenData((list) {
    final start = DateTime.now().subtract(const Duration(days: 7));
    final filtered = list.where((o) =>
        o.createdAt.isAfter(start) &&
        o.status != OrderStatus.cancelled);
    return SalesSummary(
      orderCount: filtered.length,
      revenue:
          filtered.fold<double>(0, (sum, o) => sum + o.total),
    );
  });
});

final adminMonthSummaryProvider = Provider<AsyncValue<SalesSummary>>((ref) {
  final orders = ref.watch(adminAllOrdersProvider);
  return orders.whenData((list) {
    final start = DateTime.now().subtract(const Duration(days: 30));
    final filtered = list.where((o) =>
        o.createdAt.isAfter(start) &&
        o.status != OrderStatus.cancelled);
    return SalesSummary(
      orderCount: filtered.length,
      revenue:
          filtered.fold<double>(0, (sum, o) => sum + o.total),
    );
  });
});

class TopProduct {
  final String productName;
  final int unitsSold;
  final double revenue;
  const TopProduct({
    required this.productName,
    required this.unitsSold,
    required this.revenue,
  });
}

final adminTopProductsProvider =
    Provider<AsyncValue<List<TopProduct>>>((ref) {
  final orders = ref.watch(adminAllOrdersProvider);
  return orders.whenData((list) {
    final byName = <String, TopProduct>{};
    for (final o in list) {
      if (o.status == OrderStatus.cancelled) continue;
      for (final line in o.items) {
        final cur = byName[line.productName];
        byName[line.productName] = TopProduct(
          productName: line.productName,
          unitsSold: (cur?.unitsSold ?? 0) + line.quantity,
          revenue: (cur?.revenue ?? 0) + line.lineTotal,
        );
      }
    }
    final sorted = byName.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    return sorted.take(10).toList();
  });
});

/// Inventory items that are low or out of stock.
final adminLowStockProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final products = ref.watch(adminAllProductsProvider);
  return products.whenData((list) {
    return list.where((p) {
      // any unit out of stock OR very low stock <= 3
      return p.units.any((u) => u.stock <= 3);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  });
});
