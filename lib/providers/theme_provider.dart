import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _currentTheme = 'System';

  ThemeProvider(String savedTheme) {
    _applyTheme(savedTheme, notify: false);
  }

  ThemeMode get themeMode => _themeMode;
  String get currentTheme => _currentTheme;

  Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);

    _applyTheme(theme);
  }

  void _applyTheme(String theme, {bool notify = true}) {
    _currentTheme = theme;

    switch (theme) {
      case 'Dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'Light':
        _themeMode = ThemeMode.light;
        break;
      default:
        _themeMode = ThemeMode.system;
    }

    if (notify) notifyListeners();
  }
}