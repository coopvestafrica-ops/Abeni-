import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin/admin_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'data/services/firebase_service.dart';
import 'presentation/providers/providers.dart';

/// Entry point for the **Abeni Admin** companion app.
///
/// This builds a separate Android/iOS package (`*.admin` flavor) that
/// shares the same data layer (Firebase / Firestore) as the customer app
/// but exposes order-management, product-management, customer support
/// and store-wide broadcast capabilities to admin/staff users only.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.tryInit();

  // Register the background handler BEFORE runApp — Firebase Messaging
  // requires this to happen in main() before the app widget tree is built.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Await init so notification channels are created with sound BEFORE
  // the app starts receiving any FCM messages.
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: AbeniAdminApp()));
}

class AbeniAdminApp extends ConsumerStatefulWidget {
  const AbeniAdminApp({super.key});

  @override
  ConsumerState<AbeniAdminApp> createState() => _AbeniAdminAppState();
}

class _AbeniAdminAppState extends ConsumerState<AbeniAdminApp> {
  String? _registeredAdminId;

  @override
  void initState() {
    super.initState();
    _setupNotificationNavigation();
  }

  void _setupNotificationNavigation() {
    // Handle cold-start tap (app was launched by a notification).
    NotificationService.instance.handleInitialMessage();

    // Listen for all tap events and navigate via the admin router.
    NotificationService.instance.onNotificationTap.listen((route) {
      final router = ref.read(adminRouterProvider);
      final user = ref.read(currentUserProvider);
      if (user != null && user.isAdminOrStaff) {
        router.push(route);
      }
    });
  }

  /// Keep FCM topic registration in sync with the logged-in admin user.
  void _syncAdminFcm(String? userId) {
    if (userId == _registeredAdminId) return;

    // Unregister previous admin if any.
    if (_registeredAdminId != null) {
      NotificationService.instance.unregisterForAdmin(_registeredAdminId!);
    }

    _registeredAdminId = userId;

    if (userId != null) {
      NotificationService.instance.registerForAdmin(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(adminRouterProvider);

    // Watch auth state and keep FCM registration up to date.
    final user = ref.watch(currentUserProvider);
    if (user != null && user.isAdminOrStaff) {
      _syncAdminFcm(user.id);
    } else {
      _syncAdminFcm(null);
    }

    return MaterialApp.router(
      title: 'Abeni Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
