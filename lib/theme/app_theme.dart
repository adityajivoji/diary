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
      case DiaryThemeOption.midnight:
        return _buildMidnightTheme();
      case DiaryThemeOption.nebula:
        return _buildNebulaTheme();
      case DiaryThemeOption.evergreen:
        return _buildEvergreenTheme();
      case DiaryThemeOption.carbonSlate:
        return _buildCarbonSlateTheme();
      case DiaryThemeOption.obsidian:
        return _buildObsidianTheme();
      case DiaryThemeOption.moonlightSparkle:
        return _buildMoonlightSparkleTheme();
      case DiaryThemeOption.bunnyHop:
        return _buildBunnyHopTheme();
      case DiaryThemeOption.kittenPaw:
        return _buildKittenPawTheme();
      case DiaryThemeOption.starlitFairy:
        return _buildStarlitFairyTheme();
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
      case DiaryThemeOption.midnight:
        return const Color(0xFF0F172A);
      case DiaryThemeOption.nebula:
        return const Color(0xFFBC53F5);
      case DiaryThemeOption.evergreen:
        return const Color(0xFF1A4336);
      case DiaryThemeOption.carbonSlate:
        return const Color(0xFF2F3136);
      case DiaryThemeOption.obsidian:
        return const Color(0xFF090909);
      case DiaryThemeOption.moonlightSparkle:
        return const Color(0xFF3A3F94);
      case DiaryThemeOption.bunnyHop:
        return const Color(0xFFFFB7C5);
      case DiaryThemeOption.kittenPaw:
        return const Color(0xFFD9A066);
      case DiaryThemeOption.starlitFairy:
        return const Color(0xFF6A4AEF);
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

  static ThemeData _buildMidnightTheme() {
    const primary = Color(0xFF0F172A);
    const secondary = Color(0xFF38BDF8);
    const background = Color(0xFF020617);
    const card = Color(0xFF111827);
    const onSurface = Colors.white;

    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.ibmPlexSansTextTheme(base.textTheme).apply(
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
      onSecondary: Colors.black,
      onSurface: onSurface,
    );

    return _applyCommonStyles(
      base: base,
      textTheme: textTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: card,
      chipBackgroundColor: const Color(0xFF16213A),
      chipSelectedColor: const Color(0xFF1E2B48),
      fabBackground: secondary,
      fabForeground: Colors.black,
      focusedBorderColor: secondary,
      textButtonColor: secondary,
      filledButtonBackground: secondary,
      filledButtonForeground: Colors.black,
      dialogBackgroundColor: const Color(0xFF0B1222),
    );
  }

  static ThemeData _buildNebulaTheme() {
    const primary = Color(0xFF3B1D60);
    const secondary = Color(0xFFBC53F5);
    const background = Color(0xFF0B0416);
    const card = Color(0xFF1D1030);
    const onSurface = Colors.white;

    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
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
      onSecondary: Colors.black,
      onSurface: onSurface,
    );

    return _applyCommonStyles(
      base: base,
      textTheme: textTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: card,
      chipBackgroundColor: const Color(0xFF291540),
      chipSelectedColor: const Color(0xFF3C1E5F),
      fabBackground: secondary,
      fabForeground: Colors.black,
      focusedBorderColor: secondary,
      textButtonColor: secondary,
      filledButtonBackground: secondary,
      filledButtonForeground: Colors.black,
      dialogBackgroundColor: const Color(0xFF140826),
    );
  }

  static ThemeData _buildEvergreenTheme() {
    const primary = Color(0xFF1A4336);
    const secondary = Color(0xFF34D399);
    const background = Color(0xFF041B16);
    const card = Color(0xFF0F2A23);
    const onSurface = Colors.white;

    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.muktaTextTheme(base.textTheme).apply(
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
      onSecondary: Colors.black,
      onSurface: onSurface,
    );

    return _applyCommonStyles(
      base: base,
      textTheme: textTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: card,
      chipBackgroundColor: const Color(0xFF16362C),
      chipSelectedColor: const Color(0xFF1E4336),
      fabBackground: secondary,
      fabForeground: Colors.black,
      focusedBorderColor: secondary,
      textButtonColor: secondary,
      filledButtonBackground: secondary,
      filledButtonForeground: Colors.black,
      dialogBackgroundColor: const Color(0xFF0B251D),
    );
  }

  static ThemeData _buildCarbonSlateTheme() {
    const primary = Color(0xFF2F3136);
    const secondary = Color(0xFF7C8A96);
    const background = Color(0xFF0F1013);
    const card = Color(0xFF18191D);
    const onSurface = Colors.white;

    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.jetBrainsMonoTextTheme(base.textTheme).apply(
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
      onSecondary: Colors.black,
      onSurface: onSurface,
    );

    return _applyCommonStyles(
      base: base,
      textTheme: textTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: card,
      chipBackgroundColor: const Color(0xFF1F2126),
      chipSelectedColor: const Color(0xFF2A2D33),
      fabBackground: secondary,
      fabForeground: Colors.black,
      focusedBorderColor: secondary,
      textButtonColor: secondary,
      filledButtonBackground: secondary.withValues(alpha: 0.85),
      filledButtonForeground: Colors.black,
      dialogBackgroundColor: const Color(0xFF131417),
    );
  }

  static ThemeData _buildObsidianTheme() {
    const primary = Color(0xFF000000);
    const secondary = Color(0xFF22D3EE);
    const background = Color(0xFF000000);
    const card = Color(0xFF111111);
    const onSurface = Colors.white;

    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
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
      onSecondary: Colors.black,
      onSurface: onSurface,
    );

    return _applyCommonStyles(
      base: base,
      textTheme: textTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: card,
      chipBackgroundColor: const Color(0xFF161616),
      chipSelectedColor: const Color(0xFF1E1E1E),
      fabBackground: secondary,
      fabForeground: Colors.black,
      focusedBorderColor: secondary,
      textButtonColor: onSurface,
      filledButtonBackground: onSurface,
      filledButtonForeground: Colors.black,
      dialogBackgroundColor: const Color(0xFF0C0C0C),
    );
  }

  static ThemeData _buildMoonlightSparkleTheme() {
    const primary = Color(0xFF3A3F94);
    const secondary = Color(0xFF8FD3FF);
    const background = Color(0xFF0C1024);
    const card = Color(0xFF151C33);
    const onSurface = Colors.white;

    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).apply(
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
      onSecondary: Colors.black,
      onSurface: onSurface,
    );

    return _applyCommonStyles(
      base: base,
      textTheme: textTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: card,
      chipBackgroundColor: const Color(0xFF1A2341),
      chipSelectedColor: const Color(0xFF232F55),
      fabBackground: secondary,
      fabForeground: Colors.black,
      focusedBorderColor: secondary,
      textButtonColor: secondary,
      filledButtonBackground: secondary,
      filledButtonForeground: Colors.black,
      dialogBackgroundColor: const Color(0xFF111830),
    );
  }

  static ThemeData _buildBunnyHopTheme() {
    const primary = Color(0xFFFFB7C5);
    const secondary = Color(0xFFA9E4C5);
    const background = Color(0xFFFFF9F4);
    const card = Color(0xFFFFE6F0);
    const onSurface = Color(0xFF624049);

    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.baloo2TextTheme(base.textTheme).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: background,
      onPrimary: onSurface,
      onSecondary: onSurface,
      onSurface: onSurface,
    );

    return _applyCommonStyles(
      base: base,
      textTheme: textTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: card,
      chipBackgroundColor: Colors.white.withValues(alpha: 0.94),
      chipSelectedColor: const Color(0xFFE3F4E6),
      fabBackground: primary,
      fabForeground: onSurface,
      focusedBorderColor: secondary,
      textButtonColor: const Color(0xFF7FC7B9),
      filledButtonBackground: primary,
      filledButtonForeground: onSurface,
      dialogBackgroundColor: Colors.white,
    );
  }

  static ThemeData _buildKittenPawTheme() {
    const primary = Color(0xFFD9A066);
    const secondary = Color(0xFFF2CFC4);
    const background = Color.fromARGB(255, 231, 112, 112);
    const card = Color(0xFFFFE2D1);
    const onSurface = Color(0xFF4A3426);

    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.cabinTextTheme(base.textTheme).apply(
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
      cardColor: card,
      chipBackgroundColor: Colors.white.withValues(alpha: 0.92),
      chipSelectedColor: const Color(0xFFF8DCCC),
      fabBackground: primary,
      fabForeground: Colors.white,
      focusedBorderColor: primary,
      textButtonColor: primary,
      filledButtonBackground: primary,
      filledButtonForeground: Colors.white,
      dialogBackgroundColor: Colors.white,
    );
  }

  static ThemeData _buildStarlitFairyTheme() {
    const primary = Color(0xFF6A4AEF);
    const secondary = Color(0xFFF6A6FF);
    const background = Color(0xFF120930);
    const card = Color(0xFF1F1446);
    const onSurface = Colors.white;

    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.jostTextTheme(base.textTheme).apply(
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
      onSecondary: Colors.black,
      onSurface: onSurface,
    );

    return _applyCommonStyles(
      base: base,
      textTheme: textTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: card,
      chipBackgroundColor: const Color(0xFF241850),
      chipSelectedColor: const Color(0xFF2E2065),
      fabBackground: secondary,
      fabForeground: Colors.black,
      focusedBorderColor: secondary,
      textButtonColor: secondary,
      filledButtonBackground: secondary,
      filledButtonForeground: Colors.black,
      dialogBackgroundColor: const Color(0xFF170F3D),
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
