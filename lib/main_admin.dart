import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin/admin_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/firebase_service.dart';

/// Entry point for the **Abeni Admin** companion app.
///
/// This builds a separate Android/iOS package (`*.admin` flavor) that
/// shares the same data layer (Firebase / Firestore) as the customer app
/// but exposes order-management, product-management, customer support
/// and store-wide broadcast capabilities to admin/staff users only.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.tryInit();
  runApp(const ProviderScope(child: AbeniAdminApp()));
}

class AbeniAdminApp extends ConsumerWidget {
  const AbeniAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);
    return MaterialApp.router(
      title: 'Abeni Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
