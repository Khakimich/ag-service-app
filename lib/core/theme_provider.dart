import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/i18n.dart'; // AG_I18N1

class ThemeProvider extends ChangeNotifier {
  static const String _storageKey = 'ag_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  String get modeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return tr('Светлая');
      case ThemeMode.dark:
        return tr('Тёмная');
      case ThemeMode.system:
        return tr('Системная');
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_storageKey);

    switch (value) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_storageKey, 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString(_storageKey, 'dark');
        break;
      case ThemeMode.system:
        await prefs.setString(_storageKey, 'system');
        break;
    }
  }
}
