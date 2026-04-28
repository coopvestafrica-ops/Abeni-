import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/order.dart';
import '../data/models/product.dart';
import '../presentation/providers/providers.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_shell.dart';
import 'screens/admin_splash_screen.dart';
import 'screens/customers/customer_detail_screen.dart';
import 'screens/orders/order_detail_screen.dart';
import 'screens/products/product_edit_screen.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final user = auth.value;
      final loc = state.uri.path;
      final isAuth = loc == '/login';
      final isSplash = loc == '/';
      if (isSplash) return null;
      if (user == null) return isAuth ? null : '/login';
      // Logged in but not admin/staff — kick back to login.
      if (!user.isAdminOrStaff) return '/login';
      if (isAuth) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const AdminSplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const AdminShell(initialTab: 0),
      ),
      GoRoute(
        path: '/orders',
        builder: (_, __) => const AdminShell(initialTab: 1),
      ),
      GoRoute(
        path: '/products',
        builder: (_, __) => const AdminShell(initialTab: 2),
      ),
      GoRoute(
        path: '/customers',
        builder: (_, __) => const AdminShell(initialTab: 3),
      ),
      GoRoute(
        path: '/more',
        builder: (_, __) => const AdminShell(initialTab: 4),
      ),
      GoRoute(
        path: '/order-detail',
        builder: (_, state) =>
            OrderDetailScreen(order: state.extra as AbeniOrder),
      ),
      GoRoute(
        path: '/product-edit',
        builder: (_, state) =>
            ProductEditScreen(existing: state.extra as Product?),
      ),
      GoRoute(
        path: '/customer-detail',
        builder: (_, state) =>
            CustomerDetailScreen(userId: state.extra as String),
      ),
    ],
  );
});
