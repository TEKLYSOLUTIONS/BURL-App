import 'package:flutter/material.dart';

class AppPalette {
  // Brand Colors (Material 3 Seed Colors)
  static const Color navyPrimary = Color(0xFF0F2A44); // Deep Navy Blue
  static const Color orangeAccent = Color(0xFFF97316); // Vibrant Orange
  static const Color offWhite = Color(0xFFF8FAFC); // Background

  // Tonal Variants
  static const Color navyLight = Color(0xFF1E3A5F);
  static const Color navyDark = Color(0xFF0A1D30);
  static const Color orangeLight = Color(0xFFFDBA74);
  static const Color orangeDark = Color(0xFFC2410C);

  // Surface Colors
  static const Color backgroundLight = offWhite;
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0B1E33);
  static const Color surfaceDark = Color(0xFF0F2A44);
  static const Color elevatedDark = Color(0xFF163B5C);
  static Color surfaceGlassDark = Colors.white.withValues(
    alpha: 0.12,
  ); // White with ~12% opacity
  static const Color surfaceGlassLight = Colors.white;

  // Material Design 3 Roles
  static const Color primary = navyPrimary;
  static const Color onPrimary = Colors.white;
  static const Color secondary = orangeAccent;
  static const Color onSecondary = Colors.white;
  static const Color tertiary = navyLight;
  static const Color onTertiary = Colors.white;
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Colors.white;
  static const Color outline = Color(0xFF79747E);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textDisabled = Color(0xFF94A3B8);

  // Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFBA1A1A);

  // Legacy/Compatibility Aliases
  static const Color navyBlue = navyPrimary;
  static const Color tealAccent = orangeAccent; // Deprecated: Use orangeAccent
  static const Color white = Colors.white;
  static const Color textDark = textPrimaryLight;
  static const Color textMedium = textSecondaryLight;
  static const Color textLight = textDisabled;
  static const Color surface = surfaceLight;
  static const Color background = backgroundLight;
  static const Color divider = Color(0xFFE2E8F0);
  static const Color primaryBlue = navyPrimary;
}
