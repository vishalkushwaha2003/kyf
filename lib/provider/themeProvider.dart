import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Theme mode notifier for managing theme state
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  /// Toggle between light and dark theme
  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  /// Set theme to light
  void setLightTheme() {
    state = ThemeMode.light;
  }

  /// Set theme to dark
  void setDarkTheme() {
    state = ThemeMode.dark;
  }

  /// Set theme to system default
  void setSystemTheme() {
    state = ThemeMode.system;
  }

  /// Set theme by mode name string ('light', 'dark', 'system')
  void setThemeMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      case 'system':
      default:
        state = ThemeMode.system;
        break;
    }
  }
}

/// Provider for theme mode management
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});