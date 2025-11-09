import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/diary_theme.dart';
import '../theme/theme_controller.dart';

/// Bottom sheet that lets the user pick one of the available themes.
class ThemeSelectorSheet extends StatelessWidget {
  const ThemeSelectorSheet({
    required this.controller,
    super.key,
  });

  final ThemeController controller;

  void _selectTheme(BuildContext context, DiaryThemeOption option) {
    controller.updateTheme(option);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const options = DiaryThemeOption.values;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 16 + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose your vibe',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...options.map(
              (option) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.previewColor(option),
                  child: Icon(
                    option.icon,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                title: Text(option.displayName),
                subtitle: Text(option.description),
                trailing: controller.currentTheme == option
                    ? Icon(Icons.check_rounded,
                        color: theme.colorScheme.primary)
                    : null,
                onTap: () => _selectTheme(context, option),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
