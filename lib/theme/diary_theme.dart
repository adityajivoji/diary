import 'package:flutter/material.dart';

/// Available visual styles for the diary.
enum DiaryThemeOption {
  cute,
  chillVibes,
  aubergine,
  nocturne,
  lark,
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
    }
  }
}
