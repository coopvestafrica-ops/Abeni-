import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/order.dart';
import '../../data/models/product.dart';
import '../../presentation/providers/providers.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/cart/cart_screen.dart';
import '../../presentation/screens/checkout/checkout_screen.dart';
import '../../presentation/screens/checkout/order_confirmation_screen.dart';
import '../../presentation/screens/home/main_shell.dart';
import '../../presentation/screens/orders/order_history_screen.dart';
import '../../presentation/screens/orders/order_tracking_screen.dart';
import '../../presentation/screens/products/category_screen.dart';
import '../../presentation/screens/products/product_details_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final loggedIn = authState.value != null;
      final loc = state.uri.path;
      final isAuthScreen = loc == '/login' || loc == '/register';
      final isSplash = loc == '/';
      if (isSplash) return null;
      if (!loggedIn && !isAuthScreen) return '/login';
      if (loggedIn && isAuthScreen) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const MainShell(),
      ),
      GoRoute(
        path: '/category/:id',
        builder: (_, state) => CategoryScreen(
          categoryId: state.pathParameters['id']!,
          categoryName: state.uri.queryParameters['name'] ?? '',
        ),
      ),
      GoRoute(
        path: '/product',
        builder: (_, state) =>
            ProductDetailsScreen(product: state.extra as Product),
      ),
      GoRoute(
        path: '/cart',
        builder: (_, __) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (_, __) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-confirmation',
        builder: (_, state) =>
            OrderConfirmationScreen(order: state.extra as AbeniOrder),
      ),
      GoRoute(
        path: '/orders',
        builder: (_, __) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/order-tracking/:id',
        builder: (_, state) => OrderTrackingScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
    ],
  );
});
