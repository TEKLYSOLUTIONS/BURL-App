import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keys for SharedPreferences
const String _themePrefsKey = 'isDarkMode';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(_themePrefsKey) ?? true;
    state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    debugPrint('Theme loaded: $state');
  }

  void toggleTheme(bool isDark) {
    // Optimistic update
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    debugPrint('Optimistic Theme Toggle: $state');
    _saveTheme(isDark);
  }

  Future<void> _saveTheme(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePrefsKey, isDark);
      debugPrint('Theme saved to storage: $isDark');
    } catch (e) {
      debugPrint('Error saving theme: $e');
      // Revert on error if needed, but for now keep UI responsive
    }
  }
}
