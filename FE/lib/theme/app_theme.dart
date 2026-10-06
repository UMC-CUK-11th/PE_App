import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.violet,
          surface: AppColors.warmWhite,
        ).copyWith(
          primary: AppColors.violet,
          onPrimary: AppColors.white,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          onSurface: AppColors.black,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          outline: AppColors.gray,
          outlineVariant: AppColors.outlineVariant,
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      colorScheme: colorScheme,
      textTheme: const TextTheme(
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
      ),
      scaffoldBackgroundColor: AppColors.warmWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.warmWhite,
        foregroundColor: AppColors.black,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.warmWhite,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: 0,
        backgroundColor: AppColors.warmWhite,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.softViolet,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.onPrimaryContainer
                : AppColors.onSurfaceVariant,
            fontSize: 12,
            height: 16 / 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
    );
  }
}
