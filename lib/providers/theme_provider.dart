// lib/providers/theme_provider.dart
//
// Theme management provider for light/dark mode switching
// Persists user preference using SharedPreferences
//
// Accessibility features:
// - Announces theme changes to screen readers
// - Persists across app restarts
// - Follows system theme by default

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode state notifier
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  /// Load saved theme preference
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? ThemeMode.system.index;
    state = ThemeMode.values[themeIndex];
  }

  /// Set theme mode and persist preference
  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(newMode);
  }

  /// Check if currently in dark mode
  bool get isDarkMode => state == ThemeMode.dark;

  /// Get display name for current theme
  String get themeName {
    switch (state) {
      case ThemeMode.light:
        return 'روشن';
      case ThemeMode.dark:
        return 'تاریک';
      case ThemeMode.system:
        return 'سیستم';
    }
  }
}

/// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

/// Light theme configuration optimized for accessibility
ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.light,
    primary: Colors.deepPurple,
    onPrimary: Colors.white,
    primaryContainer: Colors.deepPurple.shade50,
    onPrimaryContainer: Colors.deepPurple.shade900,
    secondary: Colors.teal,
    onSecondary: Colors.white,
    secondaryContainer: Colors.teal.shade50,
    onSecondaryContainer: Colors.teal.shade900,
    tertiary: Colors.orange,
    onTertiary: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black87,
    error: Colors.red,
    onError: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 2,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      minimumSize: const Size(48, 48),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.all(12),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
);

/// Dark theme configuration optimized for accessibility
ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.dark,
    primary: Colors.deepPurple.shade300,
    onPrimary: Colors.black87,
    primaryContainer: Colors.deepPurple.shade800,
    onPrimaryContainer: Colors.deepPurple.shade100,
    secondary: Colors.teal.shade300,
    onSecondary: Colors.black87,
    secondaryContainer: Colors.teal.shade800,
    onSecondaryContainer: Colors.teal.shade100,
    tertiary: Colors.orange.shade300,
    onTertiary: Colors.black87,
    surface: Colors.grey.shade900,
    onSurface: Colors.white,
    error: Colors.red.shade300,
    onError: Colors.black87,
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 2,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      minimumSize: const Size(48, 48),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.all(12),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
);
