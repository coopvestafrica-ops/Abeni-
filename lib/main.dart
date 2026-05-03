import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'data/services/firebase_service.dart';
import 'presentation/providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.tryInit();
  // ignore: unawaited_futures
  NotificationService.instance.init();
  runApp(const ProviderScope(child: AbeniMartApp()));
}

class AbeniMartApp extends ConsumerStatefulWidget {
  const AbeniMartApp({super.key});

  @override
  ConsumerState<AbeniMartApp> createState() => _AbeniMartAppState();
}

class _AbeniMartAppState extends ConsumerState<AbeniMartApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationNavigation();
  }

  void _setupNotificationNavigation() {
    // Handle cold-start tap (app was launched by a notification).
    NotificationService.instance.handleInitialMessage();

    // Listen for all tap events and navigate via the router.
    NotificationService.instance.onNotificationTap.listen((route) {
      final router = ref.read(appRouterProvider);
      // Only navigate if the user is logged in.
      final user = ref.read(currentUserProvider);
      if (user != null) {
        router.push(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
