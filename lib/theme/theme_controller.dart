import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'f1_team_schemes.dart';
import 'f1_theme_tokens.dart';
import 'theme_service.dart';

/// Team index → heading font (Google Fonts). Body font is always Inter.
const List<String> _headingFonts = [
  'Kanit',            // 0 Red Bull
  'Playfair Display', // 1 Ferrari
  'Inter',            // 2 Mercedes
  'Orbitron',         // 3 McLaren
  'Libre Baskerville',// 4 Aston Martin
  'Titillium Web',    // 5 Alpine
  'Titillium Web',    // 6 Williams
  'Montserrat',       // 7 Haas
  'Kanit',            // 8 RB
  'Syncopate',        // 9 Audi
  'Montserrat',       // 10 Cadillac
  'Titillium Web',    // 11 FIA
];

/// Teams that get letterSpacing 1.2 for headings (technical look): Orbitron, Syncopate.
const _letterSpacingTeams = {3, 9};

/// Maps ThemeMode to Supabase profile string.
String _themeModeToSupabase(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

/// Parses Supabase string to ThemeMode.
ThemeMode _themeModeFromSupabase(String? value) {
  switch (value?.toLowerCase()) {
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    default:
      return ThemeMode.light;
  }
}

/// Manages theme state: scheme index (0–11) and brightness (light/dark).
/// Persists via [ThemeService] locally and syncs to Supabase `profiles` when logged in.
class ThemeController extends ChangeNotifier {
  ThemeController({
    int initialSchemeIndex = F1TeamSchemes.defaultIndex,
    ThemeMode initialThemeMode = ThemeMode.dark,
  })  : _schemeIndex = initialSchemeIndex.clamp(0, F1TeamSchemes.count - 1),
        _themeMode = initialThemeMode {
    _isDark = _themeMode == ThemeMode.dark;
  }

  int _schemeIndex;
  ThemeMode _themeMode;
  late bool _isDark;

  int get schemeIndex => _schemeIndex;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _isDark;

  /// Current brand string for Supabase (e.g. 'mclaren', 'ferrari', 'red_bull').
  String get brandTheme => F1TeamSchemes.brandFromIndex(_schemeIndex);

  /// Resolves [ThemeMode.system] to either light or dark based on platform.
  bool get resolvedIsDark {
    if (_themeMode == ThemeMode.light) return false;
    if (_themeMode == ThemeMode.dark) return true;
    return _isDark;
  }

  /// Current light [ThemeData] for the selected scheme.
  ThemeData get lightTheme => _buildTheme(brightness: Brightness.light);

  /// Current dark [ThemeData] for the selected scheme.
  ThemeData get darkTheme => _buildTheme(brightness: Brightness.dark);

  ThemeData _buildTheme({required Brightness brightness}) {
    final scheme = F1TeamSchemes.schemeAt(_schemeIndex);
    final colors = brightness == Brightness.light ? scheme.light : scheme.dark;
    final subThemes = FlexSubThemesData(
      defaultRadius: 12.0,
      elevatedButtonRadius: 12.0,
      outlinedButtonRadius: 12.0,
      inputDecoratorRadius: 12.0,
      cardRadius: 22.0,
      dialogRadius: 20.0,
      bottomSheetRadius: 24.0,
      snackBarRadius: 16.0,
    );

    ThemeData base = brightness == Brightness.light
        ? FlexThemeData.light(colors: colors, subThemesData: subThemes)
        : FlexThemeData.dark(colors: colors, subThemesData: subThemes);

    final tokens = F1ThemeTokens.fromColorScheme(base.colorScheme);
    final textTheme = _buildTeamTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: tokens.scaffoldTint,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: [tokens],
    );
  }

  /// Builds team-specific TextTheme: display/headline/title use team font;
  /// body uses Inter. Orbitron & Syncopate get letterSpacing 1.2.
  TextTheme _buildTeamTextTheme(TextTheme base) {
    final i = _schemeIndex.clamp(0, F1TeamSchemes.count - 1);
    final headingFont = _headingFonts[i];
    final spacing = _letterSpacingTeams.contains(i) ? 1.2 : null;

    TextStyle heading(TextStyle? s) {
      if (s == null) return const TextStyle();
      return GoogleFonts.getFont(headingFont, textStyle: s).copyWith(
        letterSpacing: spacing ?? s.letterSpacing,
      );
    }

    final bodyTheme = GoogleFonts.interTextTheme(base);
    return bodyTheme.copyWith(
      displayLarge: heading(base.displayLarge),
      displayMedium: heading(base.displayMedium),
      displaySmall: heading(base.displaySmall),
      headlineLarge: heading(base.headlineLarge),
      headlineMedium: heading(base.headlineMedium),
      headlineSmall: heading(base.headlineSmall),
      titleLarge: heading(base.titleLarge),
      titleMedium: heading(base.titleMedium),
      titleSmall: heading(base.titleSmall),
    );
  }

  /// Optimistic update: sets brand theme instantly, then syncs to Supabase in background.
  void setBrandTheme(String newBrand) {
    final index = F1TeamSchemes.indexFromBrand(newBrand);
    if (_schemeIndex == index) return;

    // 1. Update local state immediately (optimistic)
    _schemeIndex = index;
    notifyListeners();

    // 2. Persist locally
    ThemeService.instance.saveSchemeIndex(_schemeIndex);

    // 3. Sync to Supabase in background (do not block UI)
    _syncBrandToSupabase();
  }

  /// Saves [themeName] (brand_theme) to Supabase profiles using upsert.
  ///
  /// **Upsert logic**: Includes `id` so Supabase knows whether to UPDATE (existing
  /// row) or INSERT (new row). Use [onConflict: 'id'] to prevent duplicate rows.
  ///
  /// Call when user selects a theme, e.g. `saveThemeToSupabase('mclaren')`.
  /// No-op if not logged in (prints warning). Errors are logged to console for
  /// debugging RLS/permission issues.
  Future<void> saveThemeToSupabase(String themeName) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('[ThemeController] saveThemeToSupabase: No user logged in. Skipping upsert.');
      return;
    }

    try {
      await Supabase.instance.client.from('profiles').upsert(
        {'id': user.id, 'brand_theme': themeName},
        onConflict: 'id',
      );
    } on PostgrestException catch (e) {
      debugPrint('[ThemeController] Supabase upsert failed (Postgrest): ${e.message}');
      debugPrint('  code: ${e.code}, details: ${e.details}');
      debugPrint('  → Check RLS policies on profiles table.');
    } catch (e) {
      debugPrint('[ThemeController] Supabase upsert failed: $e');
    }
  }

  /// Upserts brand_theme to Supabase profiles. No-op if not logged in.
  Future<void> _syncBrandToSupabase() async {
    await saveThemeToSupabase(brandTheme);
  }

  /// Upserts full theme (brand + mode) to Supabase profiles. No-op if not logged in.
  Future<void> _syncThemeToSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('[ThemeController] _syncThemeToSupabase: No user logged in. Skipping upsert.');
      return;
    }

    try {
      await Supabase.instance.client.from('profiles').upsert(
        {
          'id': user.id,
          'brand_theme': brandTheme,
          'theme_mode': _themeModeToSupabase(_themeMode),
        },
        onConflict: 'id',
      );
    } on PostgrestException catch (e) {
      debugPrint('[ThemeController] Supabase upsert failed (Postgrest): ${e.message}');
      debugPrint('  code: ${e.code}, details: ${e.details}');
      debugPrint('  → Check RLS policies on profiles table.');
    } catch (e) {
      debugPrint('[ThemeController] Supabase upsert failed: $e');
    }
  }

  /// Loads theme from Supabase profile if user is logged in. Call before first frame.
  Future<void> initFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('brand_theme, theme_mode')
          .eq('id', user.id)
          .maybeSingle();

      final data = res as Map<String, dynamic>?;
      if (data == null) return;

      final brand = data['brand_theme'] as String?;
      final modeStr = data['theme_mode'] as String?;

      if (brand != null && brand.isNotEmpty) {
        final index = F1TeamSchemes.indexFromBrand(brand);
        if (_schemeIndex != index) {
          _schemeIndex = index;
          await ThemeService.instance.saveSchemeIndex(_schemeIndex);
          notifyListeners();
        }
      }

      if (modeStr != null && modeStr.isNotEmpty) {
        final mode = _themeModeFromSupabase(modeStr);
        if (_themeMode != mode) {
          _themeMode = mode;
          _isDark = mode == ThemeMode.dark;
          await ThemeService.instance.saveIsDark(_isDark);
          notifyListeners();
        }
      }
    } catch (_) {
      // Fall back to local stored theme
    }
  }

  /// Updates the scheme index (0–11), persists, and notifies listeners.
  Future<void> setSchemeIndex(int index) async {
    final clamped = index.clamp(0, F1TeamSchemes.count - 1);
    if (_schemeIndex == clamped) return;
    _schemeIndex = clamped;
    await ThemeService.instance.saveSchemeIndex(_schemeIndex);
    notifyListeners();
    _syncBrandToSupabase();
  }

  /// Sets theme mode (light/dark/system), persists, and notifies listeners.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _isDark = mode == ThemeMode.dark;
    await ThemeService.instance.saveIsDark(_isDark);
    notifyListeners();
    _syncThemeToSupabase();
  }

  /// Toggles between light and dark. If [ThemeMode.system], switches to dark.
  Future<void> toggleBrightness() async {
    final nextDark = !resolvedIsDark;
    _themeMode = nextDark ? ThemeMode.dark : ThemeMode.light;
    _isDark = nextDark;
    await ThemeService.instance.saveIsDark(_isDark);
    notifyListeners();
    _syncThemeToSupabase();
  }
}
