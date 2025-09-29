import 'package:flutter/material.dart';

class ThemeService {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

  static void setLight() {
    if (themeMode.value != ThemeMode.light) {
      themeMode.value = ThemeMode.light;
    }
  }

  static void setDark() {
    if (themeMode.value != ThemeMode.dark) {
      themeMode.value = ThemeMode.dark;
    }
  }
}


