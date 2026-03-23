import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

List<int> _parseFavoriteDriverNumbers(dynamic raw) {
  if (raw is! List) return const [];
  final out = <int>[];
  for (final e in raw) {
    if (e is int && e > 0) {
      out.add(e);
    } else if (e is num && e > 0) {
      out.add(e.toInt());
    } else {
      final p = int.tryParse(e?.toString() ?? '');
      if (p != null && p > 0) out.add(p);
    }
  }
  return out;
}

List<String> _parseFavoriteTeamKeys(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((e) => e?.toString().trim() ?? '')
      .where((s) => s.isNotEmpty)
      .toList();
}

/// Loads and saves profile favorites (team, driver, circuit) to Supabase.
class ProfileFavoritesService {
  ProfileFavoritesService._();
  static final ProfileFavoritesService instance = ProfileFavoritesService._();

  /// Loads team names from teams_standings_2026.json (standings[].team).
  Future<List<String>> loadTeamNames() async {
    try {
      final json = await rootBundle.loadString('data/results/teams/teams_standings_2026.json');
      final map = jsonDecode(json) as Map<String, dynamic>;
      final standings = map['standings'] as List<dynamic>? ?? [];
      return standings
          .map((e) => (e as Map<String, dynamic>)['team'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[ProfileFavorites] loadTeamNames failed: $e');
      return [];
    }
  }

  /// Loads driver names from drivers_standings_2026.json (standings[].driver).
  Future<List<String>> loadDriverNames() async {
    try {
      final json = await rootBundle.loadString('data/results/drivers/drivers_standings_2026.json');
      final map = jsonDecode(json) as Map<String, dynamic>;
      final standings = map['standings'] as List<dynamic>? ?? [];
      return standings
          .map((e) => (e as Map<String, dynamic>)['driver'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[ProfileFavorites] loadDriverNames failed: $e');
      return [];
    }
  }

  /// Loads favorites from Supabase profile. Returns null values if not found.
  Future<ProfileFavorites> loadFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const ProfileFavorites();

    try {
      Map<String, dynamic>? data;
      try {
        final res = await Supabase.instance.client
            .from('profiles')
            .select(
              'favorite_team, favorite_driver, favorite_circuit, favorite_drivers, favorite_teams',
            )
            .eq('id', user.id)
            .maybeSingle();
        data = res as Map<String, dynamic>?;
      } catch (_) {
        final res = await Supabase.instance.client
            .from('profiles')
            .select('favorite_team, favorite_driver, favorite_circuit')
            .eq('id', user.id)
            .maybeSingle();
        data = res as Map<String, dynamic>?;
      }
      if (data == null) return const ProfileFavorites();

      final driverNums = _parseFavoriteDriverNumbers(data['favorite_drivers']);
      final teamKeys = _parseFavoriteTeamKeys(data['favorite_teams']);
      final singleTeam = data['favorite_team'] as String?;
      final singleDriver = data['favorite_driver'] as String?;

      return ProfileFavorites(
        favoriteTeam: singleTeam,
        favoriteDriver: singleDriver,
        favoriteCircuit: data['favorite_circuit'] as String?,
        favoriteDriverNumbers: driverNums,
        favoriteTeamKeys: teamKeys.isNotEmpty
            ? teamKeys
            : (singleTeam != null && singleTeam.isNotEmpty ? [singleTeam] : []),
      );
    } catch (e) {
      debugPrint('[ProfileFavorites] loadFromSupabase failed: $e');
      return const ProfileFavorites();
    }
  }

  /// Saves favorites to Supabase profiles. Uses upsert with onConflict: 'id'.
  /// Pass the full [ProfileFavorites] to avoid overwriting other columns.
  Future<void> saveToSupabase(ProfileFavorites favorites) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('[ProfileFavorites] saveToSupabase: No user logged in.');
      return;
    }

    try {
      await Supabase.instance.client.from('profiles').upsert(
        {
          'id': user.id,
          'favorite_team': favorites.favoriteTeam,
          'favorite_driver': favorites.favoriteDriver,
          'favorite_circuit': favorites.favoriteCircuit,
        },
        onConflict: 'id',
      );
    } on PostgrestException catch (e) {
      debugPrint('[ProfileFavorites] saveToSupabase failed: ${e.message}');
    } catch (e) {
      debugPrint('[ProfileFavorites] saveToSupabase failed: $e');
    }
  }
}

class ProfileFavorites {
  const ProfileFavorites({
    this.favoriteTeam,
    this.favoriteDriver,
    this.favoriteCircuit,
    this.favoriteDriverNumbers = const [],
    this.favoriteTeamKeys = const [],
  });

  final String? favoriteTeam;
  final String? favoriteDriver;
  final String? favoriteCircuit;

  /// From `profiles.favorite_drivers` (driver numbers).
  final List<int> favoriteDriverNumbers;

  /// Team names or keys from `profiles.favorite_teams` (or [favoriteTeam]).
  final List<String> favoriteTeamKeys;

  @override
  bool operator ==(Object other) {
    return other is ProfileFavorites &&
        other.favoriteTeam == favoriteTeam &&
        other.favoriteDriver == favoriteDriver &&
        other.favoriteCircuit == favoriteCircuit &&
        listEquals(other.favoriteDriverNumbers, favoriteDriverNumbers) &&
        listEquals(other.favoriteTeamKeys, favoriteTeamKeys);
  }

  @override
  int get hashCode => Object.hash(
        favoriteTeam,
        favoriteDriver,
        favoriteCircuit,
        Object.hashAll(favoriteDriverNumbers),
        Object.hashAll(favoriteTeamKeys),
      );
}

/// Shared state for favorites. CircuitsView and ProfileScreen both use this.
/// Call [load] after login; [update] when user saves in Profile.
class ProfileFavoritesNotifier extends ChangeNotifier {
  ProfileFavoritesNotifier() {
    Future.microtask(() => load());
  }

  ProfileFavorites _value = const ProfileFavorites();
  ProfileFavorites get value => _value;

  Future<void> load() async {
    final fav = await ProfileFavoritesService.instance.loadFromSupabase();
    if (_value != fav) {
      _value = fav;
      notifyListeners();
    }
  }

  void update(ProfileFavorites next) {
    _value = next;
    notifyListeners();
  }
}
