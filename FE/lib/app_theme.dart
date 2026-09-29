import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6750A4);
  static const Color surface = Color(0xFFF7F2FA);
  static const Color outlineVariant = Color(0xFFCAC4D0);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
      ),
    );
  }
}