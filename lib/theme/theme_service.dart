import 'package:shared_preferences/shared_preferences.dart';

import 'f1_team_schemes.dart';

/// Persists theme preferences (scheme index and brightness) using SharedPreferences.
final class ThemeService {
  ThemeService._();

  static const String _keySchemeIndex = 'theme_scheme_index';
  static const String _keyIsDark = 'theme_is_dark';

  /// Singleton instance.
  static final ThemeService instance = ThemeService._();

  /// Loads persisted theme state.
  /// Returns a record with [schemeIndex] (0–11) and [isDark] (true = dark, false = light).
  Future<({int schemeIndex, bool isDark})> load() async {
    final prefs = await SharedPreferences.getInstance();
    final schemeIndex = prefs.getInt(_keySchemeIndex) ?? F1TeamSchemes.defaultIndex;
    final isDark = prefs.getBool(_keyIsDark) ?? true;

    return (
      schemeIndex: schemeIndex.clamp(0, F1TeamSchemes.count - 1),
      isDark: isDark,
    );
  }

  /// Saves the theme scheme index (0–11).
  Future<void> saveSchemeIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySchemeIndex, index.clamp(0, F1TeamSchemes.count - 1));
  }

  /// Saves the brightness (true = dark, false = light).
  Future<void> saveIsDark(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsDark, isDark);
  }

  /// Saves both scheme index and brightness.
  Future<void> save(int schemeIndex, bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySchemeIndex, schemeIndex.clamp(0, F1TeamSchemes.count - 1));
    await prefs.setBool(_keyIsDark, isDark);
  }
}
