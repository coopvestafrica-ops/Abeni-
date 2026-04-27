import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps [LocalAuthentication] and persists the user's biometric preference.
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  static const _prefsKey = 'abeni_biometric_enabled';

  final LocalAuthentication _auth = LocalAuthentication();

  /// Whether the device has biometric / PIN / passcode capability that we
  /// can use.
  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      return canCheck || supported;
    } on PlatformException {
      return false;
    }
  }

  Future<List<BiometricType>> availableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return const [];
    }
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }

  /// Prompt the user to authenticate. Falls back to device PIN / passcode
  /// when biometrics aren't enrolled (`biometricOnly: false`).
  Future<bool> authenticate({
    String reason = 'Unlock Abeni Mart',
  }) async {
    if (kIsWeb) return true;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Sign in to Abeni Mart',
            cancelButton: 'Cancel',
            biometricHint: '',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancel',
            lockOut: 'Please enable biometrics in Settings',
          ),
        ],
      );
    } on PlatformException catch (e) {
      debugPrint('[Biometric] error: ${e.code} ${e.message}');
      return false;
    }
  }
}
