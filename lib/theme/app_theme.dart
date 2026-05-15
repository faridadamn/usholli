import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand colors ──────────────────────────────────────
  static const Color primary       = Color(0xFF1A6E4A);
  static const Color primaryLight  = Color(0xFF2A9E6A);
  static const Color primaryDark   = Color(0xFF0F4D34);
  static const Color accent        = Color(0xFFF5A623);
  static const Color surface       = Color(0xFFF8F5F0);
  static const Color cardBg        = Color(0xFFFFFFFF);
  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider       = Color(0xFFE8E0D6);

  // ── Prayer time colors ────────────────────────────────
  static const Color subuh   = Color(0xFF6366F1);
  static const Color syuruq  = Color(0xFFF59E0B);
  static const Color dzuhur  = Color(0xFF10B981);
  static const Color ashar   = Color(0xFF3B82F6);
  static const Color maghrib = Color(0xFFEF4444);
  static const Color isya    = Color(0xFF8B5CF6);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      surface: surface,
    ),
    scaffoldBackgroundColor: surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: divider, width: 0.5),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: -0.3),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary, height: 1.6),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary, height: 1.5),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary, letterSpacing: 0.3),
    ),
  );
}
