import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Home-screen AI Strategist visibility (synced to Supabase `profiles` when logged in).
@immutable
class AiStrategistPrefs {
  const AiStrategistPrefs({
    this.cardDisabled = false,
    this.hideTeambattle = false,
    this.hideCoachCorner = false,
    this.hideTeamVibe = false,
  });

  /// Hide the entire AI Strategist card on Circuits home.
  final bool cardDisabled;

  /// Hide only the Teammate Battle block (card may still show).
  final bool hideTeambattle;

  /// Hide Coach's Corner.
  final bool hideCoachCorner;

  /// Hide Team Vibe / sentiment block.
  final bool hideTeamVibe;

  static const defaults = AiStrategistPrefs();

  AiStrategistPrefs copyWith({
    bool? cardDisabled,
    bool? hideTeambattle,
    bool? hideCoachCorner,
    bool? hideTeamVibe,
  }) {
    return AiStrategistPrefs(
      cardDisabled: cardDisabled ?? this.cardDisabled,
      hideTeambattle: hideTeambattle ?? this.hideTeambattle,
      hideCoachCorner: hideCoachCorner ?? this.hideCoachCorner,
      hideTeamVibe: hideTeamVibe ?? this.hideTeamVibe,
    );
  }
}

class AiStrategistPrefsService {
  AiStrategistPrefsService._();
  static final AiStrategistPrefsService instance = AiStrategistPrefsService._();

  Future<AiStrategistPrefs> loadFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return AiStrategistPrefs.defaults;
    }

    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select(
            'ai_strategist_disabled, ai_strategist_hide_teambattle, '
            'ai_strategist_hide_coach_corner, ai_strategist_hide_team_vibe',
          )
          .eq('id', user.id)
          .maybeSingle();

      final data = res as Map<String, dynamic>?;
      if (data == null) {
        return AiStrategistPrefs.defaults;
      }

      bool b(dynamic v) => v == true;

      return AiStrategistPrefs(
        cardDisabled: b(data['ai_strategist_disabled']),
        hideTeambattle: b(data['ai_strategist_hide_teambattle']),
        hideCoachCorner: b(data['ai_strategist_hide_coach_corner']),
        hideTeamVibe: b(data['ai_strategist_hide_team_vibe']),
      );
    } catch (e) {
      debugPrint('[AiStrategistPrefs] loadFromSupabase failed: $e');
      return AiStrategistPrefs.defaults;
    }
  }

  /// Upserts only AI Strategist columns (does not touch favorites/theme).
  Future<void> saveToSupabase(AiStrategistPrefs prefs) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('[AiStrategistPrefs] saveToSupabase: no user');
      return;
    }

    try {
      await Supabase.instance.client.from('profiles').upsert(
        {
          'id': user.id,
          'ai_strategist_disabled': prefs.cardDisabled,
          'ai_strategist_hide_teambattle': prefs.hideTeambattle,
          'ai_strategist_hide_coach_corner': prefs.hideCoachCorner,
          'ai_strategist_hide_team_vibe': prefs.hideTeamVibe,
        },
        onConflict: 'id',
      );
    } on PostgrestException catch (e) {
      debugPrint('[AiStrategistPrefs] saveToSupabase failed: ${e.message}');
    } catch (e) {
      debugPrint('[AiStrategistPrefs] saveToSupabase failed: $e');
    }
  }
}

class AiStrategistPrefsNotifier extends ChangeNotifier {
  AiStrategistPrefsNotifier() {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      load();
    });
    Future.microtask(load);
  }

  late final StreamSubscription<AuthState> _authSub;

  AiStrategistPrefs _value = AiStrategistPrefs.defaults;
  AiStrategistPrefs get value => _value;

  Future<void> load() async {
    final next = await AiStrategistPrefsService.instance.loadFromSupabase();
    if (_value.cardDisabled != next.cardDisabled ||
        _value.hideTeambattle != next.hideTeambattle ||
        _value.hideCoachCorner != next.hideCoachCorner ||
        _value.hideTeamVibe != next.hideTeamVibe) {
      _value = next;
      notifyListeners();
    }
  }

  Future<void> update(AiStrategistPrefs next) async {
    _value = next;
    notifyListeners();
    await AiStrategistPrefsService.instance.saveToSupabase(next);
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}
