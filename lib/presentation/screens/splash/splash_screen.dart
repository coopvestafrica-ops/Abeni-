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

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _routed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    // A tiny minimum duration so the splash doesn't flash away if auth
    // resolves instantly.
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() {});
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    // Only route once auth has actually resolved (hasValue means the stream
    // has emitted at least one event — it's null if signed out, non-null if
    // signed in). This avoids the splash kicking logged-in users to /login
    // before Firebase has emitted its cached session.
    if (auth.hasValue && _controller.isCompleted == false) {
      // let animation finish first
    }
    if (auth.hasValue) {
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
                  ScaleTransition(
                    scale: _scale,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/splash/app_logo_centered.png',
                          width: 84,
                          height: 84,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
    if (auth.isLoading) return 'Starting up…';
    if (_routed) return 'Unlocking…';
    return 'Ready';
  }
}
