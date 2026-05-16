import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's theme mode and persists the user's preference
/// across sessions using SharedPreferences.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _currentTheme = 'System';

  ThemeProvider(String savedTheme) {
    _applyTheme(savedTheme);
  }

  ThemeMode get themeMode => _themeMode;
  String get currentTheme => _currentTheme;

  /// Persists and applies a new theme. Call this from your settings screen.
  Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
    _applyTheme(theme);
    notifyListeners();
  }

  void _applyTheme(String theme) {
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
  }
}