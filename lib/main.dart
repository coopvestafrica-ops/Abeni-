import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'data/services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.tryInit();
  // Fire-and-forget: FCM setup shouldn't block first paint.
  // If Firebase isn't initialised this is a no-op.
  // ignore: unawaited_futures
  NotificationService.instance.init();
  runApp(const ProviderScope(child: AbeniMartApp()));
}

class AbeniMartApp extends ConsumerWidget {
  const AbeniMartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
