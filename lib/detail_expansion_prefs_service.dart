import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Top-level keys in [detail_expansion_prefs] JSON (per screen).
abstract final class DetailExpansionCat {
  static const circuit = 'circuit';
  static const driver = 'driver';
  static const team = 'team';
}

/// Stable section ids inside each category (never use translated titles).
abstract final class DetailExpansionSection {
  static const circuitWeather = 'weather_forecast';
  static const circuitInfo = 'circuit_info';
  static const circuitLapSpeed = 'lap_speed';
  static const circuitRisks = 'risks_incidents';
  static const circuitTyres = 'tyres_strategy';
  static const circuitCharacteristics = 'characteristics';

  static const driverHistory = 'driver_history';
  static const driverRecentForm = 'recent_form';
  static const driverPreviousTeams = 'previous_teams';
  static const driverFacts = 'driver_facts';
  static const driverPersonal = 'personal_info';
  static const driverGeneral = 'general';
  static const driverCareer = 'career_stats';
  static const driverExperience = 'experience';
  static const driverSponsors = 'personal_sponsors';

  static const teamPerformance = 'performance_history';
  static const teamFacts = 'team_facts';
  static const teamGeneral = 'general';
  static const teamChampionships = 'championships';
  static const teamRaceStats = 'race_stats';
  static const teamPitstop = 'pitstop_leadership';
  static const teamDrivers = 'drivers';
  static const teamEngine = 'engine_supplier';
  static const teamSponsors = 'sponsors';
}

@immutable
class DetailExpansionPrefs {
  const DetailExpansionPrefs(this.byCategory);

  /// category -> sectionId -> expanded
  final Map<String, Map<String, bool>> byCategory;

  static const DetailExpansionPrefs empty = DetailExpansionPrefs({});

  bool? expanded(String category, String sectionId) =>
      byCategory[category]?[sectionId];

  /// [fallback] when not logged in or key missing.
  bool initiallyExpanded(String category, String sectionId, bool fallback) {
    return expanded(category, sectionId) ?? fallback;
  }

  DetailExpansionPrefs copyWithSet(
    String category,
    String sectionId,
    bool value,
  ) {
    final inner = Map<String, bool>.from(byCategory[category] ?? {});
    inner[sectionId] = value;
    final outer = Map<String, Map<String, bool>>.from(byCategory);
    outer[category] = inner;
    return DetailExpansionPrefs(outer);
  }

  Map<String, dynamic> toJson() {
    return byCategory.map(
      (k, v) => MapEntry(k, Map<String, dynamic>.from(v)),
    );
  }

  static DetailExpansionPrefs fromDynamic(dynamic raw) {
    if (raw == null || raw is! Map) {
      return DetailExpansionPrefs.empty;
    }
    final out = <String, Map<String, bool>>{};
    for (final e in raw.entries) {
      final key = e.key?.toString();
      final innerRaw = e.value;
      if (key == null || innerRaw is! Map) continue;
      final inner = <String, bool>{};
      for (final ie in innerRaw.entries) {
        final ik = ie.key?.toString();
        final iv = ie.value;
        if (ik != null && iv is bool) {
          inner[ik] = iv;
        }
      }
      out[key] = inner;
    }
    return DetailExpansionPrefs(out);
  }
}

class DetailExpansionPrefsService {
  DetailExpansionPrefsService._();
  static final DetailExpansionPrefsService instance =
      DetailExpansionPrefsService._();

  Future<DetailExpansionPrefs> loadFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return DetailExpansionPrefs.empty;
    }

    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('detail_expansion_prefs')
          .eq('id', user.id)
          .maybeSingle();

      final data = res as Map<String, dynamic>?;
      if (data == null) {
        return DetailExpansionPrefs.empty;
      }

      return DetailExpansionPrefs.fromDynamic(data['detail_expansion_prefs']);
    } catch (e) {
      debugPrint('[DetailExpansionPrefs] loadFromSupabase failed: $e');
      return DetailExpansionPrefs.empty;
    }
  }

  Future<void> saveToSupabase(DetailExpansionPrefs prefs) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      await Supabase.instance.client.from('profiles').upsert(
        {
          'id': user.id,
          'detail_expansion_prefs': prefs.toJson(),
        },
        onConflict: 'id',
      );
    } catch (e) {
      debugPrint('[DetailExpansionPrefs] saveToSupabase failed: $e');
    }
  }
}

class DetailExpansionPrefsNotifier extends ChangeNotifier {
  DetailExpansionPrefsNotifier() {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      load();
    });
    Future.microtask(load);
  }

  late final StreamSubscription<AuthState> _authSub;

  DetailExpansionPrefs _value = DetailExpansionPrefs.empty;
  int _loadedRevision = 0;

  DetailExpansionPrefs get value => _value;

  /// Bumps when prefs finish loading (remount detail section lists with saved state).
  int get loadedRevision => _loadedRevision;

  bool initiallyExpanded(String category, String sectionId, bool fallback) {
    return _value.initiallyExpanded(category, sectionId, fallback);
  }

  Future<void> load() async {
    final next = await DetailExpansionPrefsService.instance.loadFromSupabase();
    _value = next;
    _loadedRevision++;
    notifyListeners();
  }

  Future<void> setExpanded(
    String category,
    String sectionId,
    bool expanded,
  ) async {
    if (Supabase.instance.client.auth.currentUser == null) {
      return;
    }
    _value = _value.copyWithSet(category, sectionId, expanded);
    await DetailExpansionPrefsService.instance.saveToSupabase(_value);
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}
