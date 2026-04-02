import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SharedPredictionsLoadResult {
  const SharedPredictionsLoadResult({
    required this.rows,
    this.backendError,
    this.fromLocalDraft = false,
  });

  final List<Map<String, dynamic>> rows;
  final String? backendError;
  final bool fromLocalDraft;
}

class SimulatorSyncService {
  SimulatorSyncService._();
  static final SimulatorSyncService instance = SimulatorSyncService._();

  static const int _seasonYear = 2026;

  /// [SharedPredictionsLoadResult.backendError] sentinel when the network stalls (web / RPC hang).
  static const String backendErrorTimedOut = 'SIMULATOR_SYNC_TIMEOUT';

  static const Duration _networkTimeout = Duration(seconds: 20);

  static const String _kDraftKeyV1 = 'championship_simulator_draft_v1';
  static const String _kDraftKeyV2 = 'championship_simulator_draft_v2';

  SupabaseClient get _client => Supabase.instance.client;

  DateTime? _parseTimestamptz(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v.toUtc();
    if (v is String) return DateTime.tryParse(v)?.toUtc();
    return null;
  }

  Future<DateTime?> fetchServerUtc() async {
    try {
      final v = await _client.rpc('server_utc_now');
      return _parseTimestamptz(v);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[SimulatorSync] server_utc_now: $e\n$st');
      }
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> readLocalSimulatorDraftRows() async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(_kDraftKeyV2);
    if (raw == null || raw.isEmpty) {
      raw = prefs.getString(_kDraftKeyV1);
    }
    if (raw == null || raw.isEmpty) return [];
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final preds = map['predictions'] as Map<String, dynamic>?;
      if (preds == null) return [];
      final out = <Map<String, dynamic>>[];
      for (final e in preds.entries) {
        final v = e.value;
        if (v is Map) {
          out.add({
            'circuit_id': e.key,
            'payload': Map<String, dynamic>.from(v),
          });
        } else if (v is List) {
          final list = v.map((x) => x.toString()).toList();
          if (list.length >= 3) {
            out.add({
              'circuit_id': e.key,
              'payload': <String, dynamic>{
                'podium': list.take(3).toList(),
              },
            });
          }
        }
      }
      return out;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[SimulatorSync] readLocalSimulatorDraftRows: $e\n$st');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> pullPredictions() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    try {
      final res = await _client
          .from('user_predictions')
          .select('circuit_id, payload')
          .eq('user_id', user.id)
          .eq('season_year', _seasonYear)
          .timeout(_networkTimeout);
      final list = res as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on TimeoutException catch (e, st) {
      if (kDebugMode) {
        debugPrint('[SimulatorSync] pullPredictions timeout: $e\n$st');
      }
      return [];
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[SimulatorSync] pullPredictions: $e\n$st');
      }
      return [];
    }
  }

  static String normalizeShareHandle(String raw) {
    var s = raw.trim();
    if (s.startsWith('@')) s = s.substring(1);
    return s.trim().toLowerCase();
  }

  static bool _shareHandleMatches(User user, String requestedUsername) {
    final r = normalizeShareHandle(requestedUsername);
    if (r.isEmpty) return false;
    final m = user.userMetadata;
    final candidates = <String?>[
      m?['user_name'],
      m?['preferred_username'],
      m?['full_name'],
      m?['name'],
      m?['username'],
      m?['nickname'],
    ];
    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) {
        if (normalizeShareHandle(c) == r) return true;
      }
    }
    final e = user.email;
    if (e != null && e.contains('@')) {
      if (e.split('@').first.toLowerCase() == r) return true;
    }
    return false;
  }

  Future<SharedPredictionsLoadResult> pullPredictionsByUsername(
    String username,
  ) async {
    final u = username.trim();
    if (u.isEmpty) return const SharedPredictionsLoadResult(rows: []);

    String? rpcFailure;
    try {
      final res = await _client
          .rpc(
            'get_shared_predictions',
            params: {'p_username': normalizeShareHandle(u)},
          )
          .timeout(_networkTimeout);
      if (res != null) {
        final list = res as List;
        final rows =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (rows.isNotEmpty) {
          return SharedPredictionsLoadResult(rows: rows);
        }
      }
    } on TimeoutException catch (e, st) {
      if (kDebugMode) {
        debugPrint('[SimulatorSync] get_shared_predictions timeout: $e\n$st');
      }
      rpcFailure = backendErrorTimedOut;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[SimulatorSync] get_shared_predictions: $e\n$st');
      }
      rpcFailure = e.toString();
    }

    final user = _client.auth.currentUser;
    if (user != null && _shareHandleMatches(user, u)) {
      final own = await pullPredictions();
      if (own.isNotEmpty) {
        return SharedPredictionsLoadResult(rows: own);
      }
      final local = await readLocalSimulatorDraftRows();
      if (local.isNotEmpty) {
        return SharedPredictionsLoadResult(
          rows: local,
          fromLocalDraft: true,
        );
      }
    }

    if (rpcFailure != null) {
      return SharedPredictionsLoadResult(rows: [], backendError: rpcFailure);
    }
    return const SharedPredictionsLoadResult(rows: []);
  }

  Future<String?> upsertAllPayloads(Map<String, Map<String, dynamic>> payloads) async {
    final user = _client.auth.currentUser;
    if (user == null) return 'not_signed_in';
    if (payloads.isEmpty) return null;
    try {
      final rows = payloads.entries
          .map(
            (e) => <String, dynamic>{
              'user_id': user.id,
              'circuit_id': e.key,
              'season_year': _seasonYear,
              'payload': e.value,
            },
          )
          .toList();
      await _client.from('user_predictions').upsert(
            rows,
            onConflict: 'user_id,circuit_id,season_year',
          );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> upsertUserHubScores(List<Map<String, dynamic>> rows) async {
    final user = _client.auth.currentUser;
    if (user == null) return 'not_signed_in';
    if (rows.isEmpty) return null;
    try {
      await _client.from('user_scores').upsert(
            rows,
            onConflict: 'user_id,circuit_id,season_year',
          );
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
