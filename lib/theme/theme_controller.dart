import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'app_theme.dart';
import 'diary_theme.dart';

/// Coordinates the selected theme and persists the choice.
class ThemeController extends ChangeNotifier {
  ThemeController._(this._settingsBox, this._currentTheme);

  static const String _settingsBoxName = 'settings_box';
  static const String _themeKey = 'selected_theme';

  final Box _settingsBox;
  DiaryThemeOption _currentTheme;

  /// Creates a controller seeded with the persisted theme (defaults to cute).
  static Future<ThemeController> load() async {
    final box = await Hive.openBox(_settingsBoxName);
    final stored = box.get(_themeKey) as String?;
    final initialTheme = DiaryThemeOption.values.firstWhere(
      (option) => option.name == stored,
      orElse: () => DiaryThemeOption.cute,
    );
    return ThemeController._(box, initialTheme);
  }

  DiaryThemeOption get currentTheme => _currentTheme;

  ThemeData get themeData => AppTheme.build(_currentTheme);

  Future<void> updateTheme(DiaryThemeOption newTheme) async {
    if (newTheme == _currentTheme) {
      return;
    }
    _currentTheme = newTheme;
    notifyListeners();
    await _settingsBox.put(_themeKey, newTheme.name);
  }
}

/// Provides the [ThemeController] down the widget tree.
class ThemeControllerProvider extends InheritedNotifier<ThemeController> {
  const ThemeControllerProvider({
    required ThemeController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ThemeControllerProvider>();
    assert(provider != null, 'ThemeControllerProvider not found in context');
    return provider!.notifier!;
  }
}
