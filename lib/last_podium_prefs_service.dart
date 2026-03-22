import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// How many recent completed races to show with a podium card on Circuits home (1–3).
@immutable
class LastPodiumPrefs {
  const LastPodiumPrefs({this.raceCount = 3});

  /// 1, 2, or 3 recent races.
  final int raceCount;

  static const defaults = LastPodiumPrefs();

  static int clampRaceCount(int v) {
    if (v < 1) return 1;
    if (v > 3) return 3;
    return v;
  }

  LastPodiumPrefs copyWith({int? raceCount}) {
    return LastPodiumPrefs(raceCount: raceCount ?? this.raceCount);
  }
}

class LastPodiumPrefsService {
  LastPodiumPrefsService._();
  static final LastPodiumPrefsService instance = LastPodiumPrefsService._();

  Future<LastPodiumPrefs> loadFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return LastPodiumPrefs.defaults;
    }

    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('last_podium_places')
          .eq('id', user.id)
          .maybeSingle();

      final data = res as Map<String, dynamic>?;
      if (data == null) {
        return LastPodiumPrefs.defaults;
      }

      final raw = data['last_podium_places'];
      final n = (raw is num) ? raw.toInt() : 3;
      return LastPodiumPrefs(raceCount: LastPodiumPrefs.clampRaceCount(n));
    } catch (e) {
      debugPrint('[LastPodiumPrefs] loadFromSupabase failed: $e');
      return LastPodiumPrefs.defaults;
    }
  }

  Future<void> saveToSupabase(LastPodiumPrefs prefs) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('[LastPodiumPrefs] saveToSupabase: no user');
      return;
    }

    try {
      await Supabase.instance.client.from('profiles').upsert(
        {
          'id': user.id,
          'last_podium_places':
              LastPodiumPrefs.clampRaceCount(prefs.raceCount),
        },
        onConflict: 'id',
      );
    } catch (e) {
      debugPrint('[LastPodiumPrefs] saveToSupabase failed: $e');
    }
  }
}

class LastPodiumPrefsNotifier extends ChangeNotifier {
  LastPodiumPrefsNotifier() {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      load();
    });
    Future.microtask(load);
  }

  late final StreamSubscription<AuthState> _authSub;

  LastPodiumPrefs _value = LastPodiumPrefs.defaults;
  LastPodiumPrefs get value => _value;

  Future<void> load() async {
    final next = await LastPodiumPrefsService.instance.loadFromSupabase();
    if (_value.raceCount != next.raceCount) {
      _value = next;
      notifyListeners();
    }
  }

  Future<void> update(LastPodiumPrefs next) async {
    _value = LastPodiumPrefs(
      raceCount: LastPodiumPrefs.clampRaceCount(next.raceCount),
    );
    notifyListeners();
    await LastPodiumPrefsService.instance.saveToSupabase(_value);
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}
