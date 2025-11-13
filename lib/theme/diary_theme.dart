import 'package:flutter/material.dart';

/// Available visual styles for the diary.
enum DiaryThemeOption {
  cute,
  chillVibes,
  aubergine,
  nocturne,
  lark,
  midnight,
  nebula,
  evergreen,
  carbonSlate,
  obsidian,
  moonlightSparkle,
  bunnyHop,
  kittenPaw,
  starlitFairy,
}

extension DiaryThemeOptionX on DiaryThemeOption {
  String get displayName {
    switch (this) {
      case DiaryThemeOption.cute:
        return 'Cute';
      case DiaryThemeOption.chillVibes:
        return 'Chill vibes';
      case DiaryThemeOption.aubergine:
        return 'Aubergine';
      case DiaryThemeOption.nocturne:
        return 'Nocturne';
      case DiaryThemeOption.lark:
        return 'Lark';
      case DiaryThemeOption.midnight:
        return 'Midnight';
      case DiaryThemeOption.nebula:
        return 'Nebula';
      case DiaryThemeOption.evergreen:
        return 'Evergreen';
      case DiaryThemeOption.carbonSlate:
        return 'Carbon Slate';
      case DiaryThemeOption.obsidian:
        return 'Obsidian';
      case DiaryThemeOption.moonlightSparkle:
        return 'Moonlight Sparkle';
      case DiaryThemeOption.bunnyHop:
        return 'Bunny Hop';
      case DiaryThemeOption.kittenPaw:
        return 'Kitten Paw';
      case DiaryThemeOption.starlitFairy:
        return 'Starlit Fairy';
    }
  }

  String get description {
    switch (this) {
      case DiaryThemeOption.cute:
        return 'Soft pastels with playful typography.';
      case DiaryThemeOption.chillVibes:
        return 'Calming blues for relaxed journaling.';
      case DiaryThemeOption.aubergine:
        return 'Slack classic purples with bold accents.';
      case DiaryThemeOption.nocturne:
        return 'Moody dark mode with electric highlights.';
      case DiaryThemeOption.lark:
        return 'Warm sunlit tones with fresh greens.';
      case DiaryThemeOption.midnight:
        return 'Deep blues with crisp neon accents.';
      case DiaryThemeOption.nebula:
        return 'Galactic purples layered with vibrant magentas.';
      case DiaryThemeOption.evergreen:
        return 'Forest night greens with calm teal highlights.';
      case DiaryThemeOption.carbonSlate:
        return 'Matte charcoal layers with muted steel accents.';
      case DiaryThemeOption.obsidian:
        return 'Pure black canvas with sharp white contrast.';
      case DiaryThemeOption.moonlightSparkle:
        return 'Dreamy night sky with shimmering highlights.';
      case DiaryThemeOption.bunnyHop:
        return 'Playful pastels inspired by cheerful bunny energy.';
      case DiaryThemeOption.kittenPaw:
        return 'Cozy textures wrapped in warm, comforting colors.';
      case DiaryThemeOption.starlitFairy:
        return 'Magical lights with enchanting pastel tones.';
    }
  }

  IconData get icon {
    switch (this) {
      case DiaryThemeOption.cute:
        return Icons.favorite_rounded;
      case DiaryThemeOption.chillVibes:
        return Icons.self_improvement_rounded;
      case DiaryThemeOption.aubergine:
        return Icons.auto_awesome_rounded;
      case DiaryThemeOption.nocturne:
        return Icons.nights_stay_rounded;
      case DiaryThemeOption.lark:
        return Icons.wb_sunny_rounded;
      case DiaryThemeOption.midnight:
        return Icons.bedtime_rounded;
      case DiaryThemeOption.nebula:
        return Icons.auto_awesome_mosaic_rounded;
      case DiaryThemeOption.evergreen:
        return Icons.park_rounded;
      case DiaryThemeOption.carbonSlate:
        return Icons.layers_rounded;
      case DiaryThemeOption.obsidian:
        return Icons.brightness_3_rounded;
      case DiaryThemeOption.moonlightSparkle:
        return Icons.nightlight_rounded;
      case DiaryThemeOption.bunnyHop:
        return Icons.pets_rounded;
      case DiaryThemeOption.kittenPaw:
        return Icons.front_hand_rounded;
      case DiaryThemeOption.starlitFairy:
        return Icons.auto_fix_high_rounded;
    }
  }
}
