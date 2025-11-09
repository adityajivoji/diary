import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'diary_theme.dart';

/// Builds the overall visual styling for the app.
class AppTheme {
  const AppTheme._();

  static ThemeData build(DiaryThemeOption option) {
    switch (option) {
      case DiaryThemeOption.cute:
        return _buildCuteTheme();
      case DiaryThemeOption.chillVibes:
        return _buildChillTheme();
      case DiaryThemeOption.aubergine:
        return _buildAubergineTheme();
      case DiaryThemeOption.nocturne:
        return _buildNocturneTheme();
      case DiaryThemeOption.lark:
        return _buildLarkTheme();
    }
  }

  static Color previewColor(DiaryThemeOption option) {
    switch (option) {
      case DiaryThemeOption.cute:
        return AppColors.peachFuzz;
      case DiaryThemeOption.chillVibes:
        return const Color(0xFF4C8B9E);
      case DiaryThemeOption.aubergine:
        return const Color(0xFF4A154B);
      case DiaryThemeOption.nocturne:
        return const Color(0xFF1F2737);
      case DiaryThemeOption.lark:
        return const Color(0xFFECB22E);
    }
  }

  static ThemeData _buildCuteTheme() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.quicksandTextTheme(base.textTheme).apply(
      bodyColor: AppColors.deepMocha,
      displayColor: AppColors.deepMocha,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.peachFuzz,
      primary: AppColors.peachFuzz,
      secondary: AppColors.mintMist,
      surface: AppColors.creamyWhite,
      onPrimary: AppColors.deepMocha,
      onSecondary: AppColors.deepMocha,
      onSurface: AppColors.deepMocha,
    );

    return _applyCommonStyles(
      base: base,
      textTheme: textTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.creamyWhite,
      cardColor: AppColors.peachFuzz.withValues(alpha: 0.25),
      chipBackgroundColor: Colors.white.withValues(alpha: 0.85),
      chipSelectedColor: AppColors.mintMist,
      fabBackground: AppColors.peachFuzz,
      fabForeground: AppColors.deepMocha,
      focusedBorderColor: AppColors.peachFuzz.withValues(alpha: 0.7),
      textButtonColor: AppColors.rosyBrown,
      filledButtonBackground: AppColors.rosyBrown,
      filledButtonForeground: Colors.white,
      dialogBackgroundColor: Colors.white,
    );
  }

  static ThemeData _buildChillTheme() {
    const primary = Color(0xFF4C8B9E);
    const secondary = Color(0xFF8ED1C2);
    const background = Color(0xFFF0F6F7);
    const onSurface = Color(0xFF1C3640);

    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.montserratTextTheme(base.textTheme).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: background,
      onPrimary: Colors.white,
      onSecondary: onSurface,
      onSurface: onSurface,
    );

    return _applyCommonStyles(
      base: base,
      textTheme: textTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: const Color(0xFFE0F0F2),
      chipBackgroundColor: Colors.white.withValues(alpha: 0.9),
      chipSelectedColor: const Color(0xFFB6E2E0),
      fabBackground: primary,
      fabForeground: Colors.white,
      focusedBorderColor: secondary,
      textButtonColor: primary,
      filledButtonBackground: primary,
      filledButtonForeground: Colors.white,
      dialogBackgroundColor: Colors.white,
    );
  }

  static ThemeData _buildAubergineTheme() {
    const primary = Color(0xFF4A154B);
    const secondary = Color(0xFF36C5F0);
    const background = Color(0xFFF7F1FA);
    const card = Color(0xFFE8DDF3);
    const onSurface = Color(0xFF2E0F30);

    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.workSansTextTheme(base.textTheme).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: background,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: onSurface,
    );

    return _applyCommonStyles(
      base: base,
      textTheme: textTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: card,
      chipBackgroundColor: Colors.white.withValues(alpha: 0.9),
      chipSelectedColor: const Color(0xFFD9B4EC),
      fabBackground: primary,
      fabForeground: Colors.white,
      focusedBorderColor: secondary,
      textButtonColor: secondary,
      filledButtonBackground: primary,
      filledButtonForeground: Colors.white,
      dialogBackgroundColor: Colors.white,
    );
  }

  static ThemeData _buildNocturneTheme() {
    const primary = Color(0xFF1F2737);
    const secondary = Color(0xFF6A6FF5);
    const background = Color(0xFF121926);
    const card = Color(0xFF1B2433);
    const onSurface = Colors.white;

    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.rubikTextTheme(base.textTheme).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      secondary: secondary,
      surface: background,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: onSurface,
    );

    return _applyCommonStyles(
      base: base,
      textTheme: textTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: card,
      chipBackgroundColor: const Color(0xFF1E2635),
      chipSelectedColor: const Color(0xFF2B3750),
      fabBackground: secondary,
      fabForeground: Colors.white,
      focusedBorderColor: secondary,
      textButtonColor: secondary,
      filledButtonBackground: secondary,
      filledButtonForeground: Colors.white,
      dialogBackgroundColor: const Color(0xFF161F2B),
    );
  }

  static ThemeData _buildLarkTheme() {
    const primary = Color(0xFFECB22E);
    const secondary = Color(0xFF2BAC76);
    const background = Color(0xFFFFF7E8);
    const card = Color(0xFFFFE9B4);
    const onSurface = Color(0xFF5C3A00);

    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.nunitoSansTextTheme(base.textTheme).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: background,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: onSurface,
    );

    return _applyCommonStyles(
      base: base,
      textTheme: textTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: card,
      chipBackgroundColor: Colors.white.withValues(alpha: 0.92),
      chipSelectedColor: const Color(0xFFE1F7E4),
      fabBackground: secondary,
      fabForeground: Colors.white,
      focusedBorderColor: secondary,
      textButtonColor: secondary,
      filledButtonBackground: primary,
      filledButtonForeground: onSurface,
      dialogBackgroundColor: Colors.white,
    );
  }

  static ThemeData _applyCommonStyles({
    required ThemeData base,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required Color cardColor,
    required Color chipBackgroundColor,
    required Color chipSelectedColor,
    required Color fabBackground,
    required Color fabForeground,
    required Color focusedBorderColor,
    required Color textButtonColor,
    required Color filledButtonBackground,
    required Color filledButtonForeground,
    required Color dialogBackgroundColor,
  }) {
    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: fabBackground,
        foregroundColor: fabForeground,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
      ),
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: chipBackgroundColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: focusedBorderColor,
            width: 2,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: chipBackgroundColor,
        selectedColor: chipSelectedColor,
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dialogBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textButtonColor,
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: filledButtonBackground,
          foregroundColor: filledButtonForeground,
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }
}
