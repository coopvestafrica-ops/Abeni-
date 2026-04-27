import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  /// How long the splash stays on screen before routing, regardless of how
  /// quickly auth resolves. Keeps the storefront photo visible long enough
  /// for the customer to read the name + tagline.
  static const Duration _minDisplay = Duration(seconds: 30);

  bool _routed = false;
  bool _minDisplayElapsed = false;

  @override
  void initState() {
    super.initState();
    Timer(_minDisplay, () {
      if (!mounted) return;
      setState(() => _minDisplayElapsed = true);
    });
  }

  Future<void> _route(bool loggedIn) async {
    if (_routed || !mounted) return;
    _routed = true;
    if (!loggedIn) {
      context.go('/login');
      return;
    }
    final biometricEnabled = await BiometricService.instance.isEnabled();
    if (biometricEnabled) {
      final ok = await BiometricService.instance.authenticate(
        reason: 'Unlock ${AppConstants.appName}',
      );
      if (!ok) {
        await SessionService.instance.setBiometricLocked(true);
        if (!mounted) return;
        _routed = false;
        setState(() {});
        return;
      }
      await SessionService.instance.clearBiometricLock();
    }
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    // Only route once BOTH auth has resolved AND the minimum display time
    // has elapsed. This guarantees the splash is visible for ~30s before
    // we navigate away, while still respecting the persisted session so
    // logged-in users land on Home.
    if (_minDisplayElapsed && auth.hasValue) {
      final loggedIn = auth.value != null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _route(loggedIn));
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background hero image (the store photo the user provided).
          Image.asset(
            'assets/images/splash/abeni_store.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
            ),
          ),
          // Gradient scrim so the text is always readable regardless of the
          // photo content.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.55),
                  AppColors.primaryDark.withOpacity(0.9),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppConstants.appTagline,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.92),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(AppColors.accent),
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        _loadingLabel(auth),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _loadingLabel(AsyncValue<Object?> auth) {
    if (_routed) return 'Unlocking…';
    if (auth.isLoading) return 'Starting up…';
    if (!_minDisplayElapsed) return 'Welcome to Abeni Mart…';
    return 'Ready';
  }
}
