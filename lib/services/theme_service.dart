import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
  static const String _kThemeKey = 'app_theme_mode';

  static void setLight() {
    if (themeMode.value != ThemeMode.light) {
      themeMode.value = ThemeMode.light;
      _persist();
    }
  }

  static void setDark() {
    if (themeMode.value != ThemeMode.dark) {
      themeMode.value = ThemeMode.dark;
      _persist();
    }
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kThemeKey);
    if (v == 'dark') themeMode.value = ThemeMode.dark;
    if (v == 'light') themeMode.value = ThemeMode.light;
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, themeMode.value == ThemeMode.dark ? 'dark' : 'light');
  }
}


