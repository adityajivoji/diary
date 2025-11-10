import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';
import 'theme_selector_sheet.dart';

/// Reusable app bar action that opens the theme selector bottom sheet.
class ThemeSelectorAction extends StatelessWidget {
  const ThemeSelectorAction({super.key});

  void _openThemeSelector(BuildContext context) {
    final controller = ThemeControllerProvider.of(context);
    final dialogTheme = Theme.of(context).dialogTheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: dialogTheme.backgroundColor,
      shape: dialogTheme.shape,
      builder: (_) => ThemeSelectorSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Choose theme',
      icon: const Icon(Icons.palette_rounded),
      onPressed: () => _openThemeSelector(context),
    );
  }
}
