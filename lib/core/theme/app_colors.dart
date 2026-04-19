import 'package:flutter/material.dart';

/// Abeni Mart brand palette.
/// Inspired by warm Nigerian colors: deep forest green (fertile farmland),
/// gold (harvest / prosperity), warm terracotta and cream.
class AppColors {
  AppColors._();

  // Primary — deep green (earth / produce)
  static const Color primary = Color(0xFF0E7A3F);
  static const Color primaryDark = Color(0xFF075C2E);
  static const Color primaryLight = Color(0xFF2DA668);

  // Accent — warm gold / amber (harvest)
  static const Color accent = Color(0xFFF5B301);
  static const Color accentDark = Color(0xFFCC9500);

  // Supporting — terracotta / orange
  static const Color terracotta = Color(0xFFE07A3C);

  // Neutrals
  static const Color background = Color(0xFFFFFBF4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1B2321);
  static const Color textSecondary = Color(0xFF5C6B66);
  static const Color textMuted = Color(0xFF9AA7A2);

  static const Color divider = Color(0xFFE6E9E7);
  static const Color error = Color(0xFFD64545);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFEF8A17);
  static const Color info = Color(0xFF1976D2);

  // Status colors for orders
  static const Color statusPending = Color(0xFFEF8A17);
  static const Color statusProcessing = Color(0xFF1976D2);
  static const Color statusDelivered = Color(0xFF2E7D32);
  static const Color statusCancelled = Color(0xFFD64545);
}
