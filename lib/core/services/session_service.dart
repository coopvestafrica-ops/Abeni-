import 'package:shared_preferences/shared_preferences.dart';

/// Tiny wrapper around [SharedPreferences] for persisting app session flags.
///
/// Firebase Auth already persists its user session natively on Android and
/// iOS, so we do not store credentials here — this service only tracks
/// UI-level state such as "biometric unlock required this launch".
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const _biometricLockKey = 'abeni_biometric_locked';

  /// Marks the app as requiring a biometric unlock before showing content.
  /// Set to false after a successful biometric check for the current launch.
  Future<void> setBiometricLocked(bool locked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricLockKey, locked);
  }

  Future<bool> isBiometricLocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricLockKey) ?? false;
  }

  Future<void> clearBiometricLock() => setBiometricLocked(false);
}
