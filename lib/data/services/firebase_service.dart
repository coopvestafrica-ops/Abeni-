import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Initialises Firebase if real credentials are configured.
/// Returns [true] on success, [false] if we fall back to demo mode.
class FirebaseService {
  FirebaseService._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static bool _hasRealConfig() {
    final opts = DefaultFirebaseOptions.currentPlatform;
    return !opts.apiKey.contains('REPLACE_ME') &&
        !opts.projectId.contains('REPLACE_ME');
  }

  static Future<bool> tryInit() async {
    if (_initialized) return true;
    if (!_hasRealConfig()) {
      debugPrint(
        '[Abeni Mart] Firebase config is placeholder — running in demo mode. '
        'Run `flutterfire configure` to enable real backend.',
      );
      return false;
    }
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      return true;
    } catch (e, st) {
      debugPrint('[Abeni Mart] Firebase init failed: $e\n$st');
      return false;
    }
  }
}
