import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  late ThemeMode _themeMode;

  ThemeProvider([String? savedMode]) {
    if (savedMode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == savedMode,
        orElse: () => ThemeMode.system,
      );
    } else {
      _themeMode = ThemeMode.system;
    }
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_themeKey, _themeMode.toString());
    });
  }
}
