import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/order.dart';
import '../data/admin_providers.dart';
import 'customers/customers_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'more/more_screen.dart';
import 'orders/orders_screen.dart';
import 'products/products_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  late int _index = widget.initialTab;

  static const _screens = <Widget>[
    DashboardScreen(),
    OrdersScreen(),
    ProductsScreen(),
    CustomersScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminAllOrdersProvider);
    final pendingCount = ordersAsync.maybeWhen(
      data: (orders) => orders
          .where((o) =>
              o.status == OrderStatus.pending ||
              o.status == OrderStatus.processing)
          .length,
      orElse: () => 0,
    );

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: _BadgedIcon(
              icon: Icons.receipt_long_outlined,
              count: pendingCount,
            ),
            activeIcon: _BadgedIcon(
              icon: Icons.receipt_long,
              count: pendingCount,
              active: true,
            ),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

/// Icon with an animated badge showing a count. Hidden when count is zero.
class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({
    required this.icon,
    required this.count,
    this.active = false,
  });

  final IconData icon;
  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon);
    if (count <= 0) return iconWidget;

    return Badge.count(
      count: count,
      backgroundColor: AppColors.error,
      textColor: Colors.white,
      textStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
      child: iconWidget,
    );
  }
}
