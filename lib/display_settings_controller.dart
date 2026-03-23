import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'detail_expansion_prefs_service.dart';
import 'display_settings.dart';

class DisplaySettingsService {
  DisplaySettingsService._();
  static final DisplaySettingsService instance = DisplaySettingsService._();

  Future<DisplaySettings> loadFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return DisplaySettings.defaults;
    }

    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('display_settings')
          .eq('id', user.id)
          .maybeSingle();

      final data = res as Map<String, dynamic>?;
      if (data == null) {
        return DisplaySettings.defaults;
      }

      return DisplaySettings.fromJson(data['display_settings']);
    } catch (e) {
      debugPrint('[DisplaySettings] loadFromSupabase failed: $e');
      return DisplaySettings.defaults;
    }
  }

  Future<void> saveToSupabase(DisplaySettings settings) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('[DisplaySettings] saveToSupabase: no user');
      return;
    }

    try {
      await Supabase.instance.client.from('profiles').upsert(
        {
          'id': user.id,
          'display_settings': settings.toJson(),
        },
        onConflict: 'id',
      );
    } catch (e) {
      debugPrint('[DisplaySettings] saveToSupabase failed: $e');
    }
  }
}

/// Holds [DisplaySettings] and reads expansion state from [DetailExpansionPrefsNotifier].
///
/// **Expansion:** [isExpanded] uses the nested `detail_expansion_prefs` model
/// (`category` + `sectionId`). Section ids are not unique across categories
/// (e.g. `general`), so always pass both — same as [DetailExpansionPrefs.expanded].
///
/// **Select / rebuilds:** Prefer granular selectors:
/// ```dart
/// context.select<DisplaySettingsController, bool>((c) => c.compact);
/// context.select<DisplaySettingsController, UiMode>((c) => c.uiMode);
/// ```
/// Using [settings] works too: `(c) => c.settings.compact` — equality on bool
/// still avoids rebuilds when unchanged.
class DisplaySettingsController extends ChangeNotifier {
  DisplaySettingsController(this._detailExpansion) {
    _detailExpansion.addListener(_onDetailExpansionChanged);
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      load();
    });
    Future.microtask(load);
  }

  final DetailExpansionPrefsNotifier _detailExpansion;
  late final StreamSubscription<AuthState> _authSub;

  DisplaySettings _settings = DisplaySettings.defaults;
  DisplaySettings get settings => _settings;

  /// True while [updateSettings] is awaiting Supabase (or finishing save).
  bool _persistingDisplaySettings = false;
  bool get isPersistingDisplaySettings => _persistingDisplaySettings;

  /// Convenience for `context.select` without going through [settings].
  bool get compact => _settings.compact;
  bool get motionReduced => _settings.motionReduced;
  UiMode get uiMode => _settings.uiMode;

  void _onDetailExpansionChanged() {
    notifyListeners();
  }

  /// [UiMode.simple]: always collapsed overlay (does not mutate saved prefs).
  /// [UiMode.standard]: saved value, or `false` if missing.
  bool isExpanded(String category, String sectionId) {
    if (_settings.uiMode == UiMode.simple) {
      return false;
    }
    return _detailExpansion.value.expanded(category, sectionId) ?? false;
  }

  Future<void> load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _settings = DisplaySettings.defaults;
      notifyListeners();
      return;
    }

    final next = await DisplaySettingsService.instance.loadFromSupabase();
    if (_settings != next) {
      _settings = next;
      notifyListeners();
    }
  }

  /// Updates local state, notifies listeners, then persists `display_settings` only.
  Future<void> updateSettings(DisplaySettings newSettings) async {
    _persistingDisplaySettings = true;
    if (_settings != newSettings) {
      _settings = newSettings;
    }
    notifyListeners();
    try {
      await DisplaySettingsService.instance.saveToSupabase(_settings);
    } finally {
      _persistingDisplaySettings = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _detailExpansion.removeListener(_onDetailExpansionChanged);
    _authSub.cancel();
    super.dispose();
  }
}
