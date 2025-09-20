import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the application theme and persists user preferences
class ThemeProvider extends ChangeNotifier {
  // Keys for storing theme preference in SharedPreferences
  static const String _themePreferenceKey = 'theme_preference';

  // Default theme mode
  ThemeMode _themeMode = ThemeMode.system;

  // Constructor - loads saved preference if available
  ThemeProvider() {
    _loadThemePreference();
  }

  // Getter for current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Set the theme mode and save preference
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();
    
    // Save the preference
    await _saveThemePreference();
  }

  /// Load saved theme preference
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeString = prefs.getString(_themePreferenceKey);
      
      if (savedThemeString != null) {
        // Convert string back to ThemeMode enum
        _themeMode = _themeModeFromString(savedThemeString);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  /// Save current theme preference
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Convert ThemeMode enum to string for storage
      await prefs.setString(_themePreferenceKey, _themeModeToString(_themeMode));
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  /// Convert ThemeMode enum to string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Convert string to ThemeMode enum
  ThemeMode _themeModeFromString(String modeString) {
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Check if current theme is dark
  /// Note: This doesn't account for system preference, just the explicit setting
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Get human readable name for current theme mode
  String get themeModeDisplayName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}