import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Calendar display options (Supabase `profiles`, logged-in only).
@immutable
class CalendarPrefs {
  const CalendarPrefs({this.hideCancelledRaces = false});

  /// When true, Bahrain & Saudi (placeholder “cancelled” GPs) are hidden from the list.
  final bool hideCancelledRaces;

  static const defaults = CalendarPrefs();

  CalendarPrefs copyWith({bool? hideCancelledRaces}) {
    return CalendarPrefs(
      hideCancelledRaces: hideCancelledRaces ?? this.hideCancelledRaces,
    );
  }
}

class CalendarPrefsService {
  CalendarPrefsService._();
  static final CalendarPrefsService instance = CalendarPrefsService._();

  Future<CalendarPrefs> loadFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return CalendarPrefs.defaults;
    }

    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('hide_cancelled_calendar_races')
          .eq('id', user.id)
          .maybeSingle();

      final data = res as Map<String, dynamic>?;
      if (data == null) {
        return CalendarPrefs.defaults;
      }

      return CalendarPrefs(
        hideCancelledRaces: data['hide_cancelled_calendar_races'] == true,
      );
    } catch (e) {
      debugPrint('[CalendarPrefs] loadFromSupabase failed: $e');
      return CalendarPrefs.defaults;
    }
  }

  Future<void> saveToSupabase(CalendarPrefs prefs) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('[CalendarPrefs] saveToSupabase: no user');
      return;
    }

    try {
      await Supabase.instance.client.from('profiles').upsert(
        {
          'id': user.id,
          'hide_cancelled_calendar_races': prefs.hideCancelledRaces,
        },
        onConflict: 'id',
      );
    } catch (e) {
      debugPrint('[CalendarPrefs] saveToSupabase failed: $e');
    }
  }
}

class CalendarPrefsNotifier extends ChangeNotifier {
  CalendarPrefsNotifier() {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      load();
    });
    Future.microtask(load);
  }

  late final StreamSubscription<AuthState> _authSub;

  CalendarPrefs _value = CalendarPrefs.defaults;
  CalendarPrefs get value => _value;

  Future<void> load() async {
    final next = await CalendarPrefsService.instance.loadFromSupabase();
    if (_value.hideCancelledRaces != next.hideCancelledRaces) {
      _value = next;
      notifyListeners();
    }
  }

  Future<void> update(CalendarPrefs next) async {
    _value = next;
    notifyListeners();
    await CalendarPrefsService.instance.saveToSupabase(next);
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}
