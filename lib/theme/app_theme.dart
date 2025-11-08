import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Builds the overall visual styling for the app.
class AppTheme {
  const AppTheme._();

  static ThemeData build() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.quicksandTextTheme(base.textTheme).apply(
      bodyColor: AppColors.deepMocha,
      displayColor: AppColors.deepMocha,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.peachFuzz,
      primary: AppColors.peachFuzz,
      secondary: AppColors.mintMist,
      background: AppColors.creamyWhite,
      onPrimary: AppColors.deepMocha,
      onSecondary: AppColors.deepMocha,
      onBackground: AppColors.deepMocha,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.creamyWhite,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.creamyWhite,
        foregroundColor: AppColors.deepMocha,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.peachFuzz,
        foregroundColor: AppColors.deepMocha,
      ),
      cardTheme: CardTheme(
        color: AppColors.peachFuzz.withOpacity(0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
      ),
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.peachFuzz.withOpacity(0.7),
            width: 2,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white.withOpacity(0.85),
        selectedColor: AppColors.mintMist,
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
