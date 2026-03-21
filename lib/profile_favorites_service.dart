import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase/supabase.dart';

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
      final res = await Supabase.instance.client
          .from('profiles')
          .select('favorite_team, favorite_driver, favorite_circuit')
          .eq('id', user.id)
          .maybeSingle();

      final data = res as Map<String, dynamic>?;
      if (data == null) return const ProfileFavorites();

      return ProfileFavorites(
        favoriteTeam: data['favorite_team'] as String?,
        favoriteDriver: data['favorite_driver'] as String?,
        favoriteCircuit: data['favorite_circuit'] as String?,
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
  });

  final String? favoriteTeam;
  final String? favoriteDriver;
  final String? favoriteCircuit;
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
    if (_value.favoriteTeam != fav.favoriteTeam ||
        _value.favoriteDriver != fav.favoriteDriver ||
        _value.favoriteCircuit != fav.favoriteCircuit) {
      _value = fav;
      notifyListeners();
    }
  }

  void update(ProfileFavorites next) {
    _value = next;
    notifyListeners();
  }
}
