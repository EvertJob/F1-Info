import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:f1/display_settings_controller.dart';
import 'package:f1/l10n/app_localizations.dart';
import 'package:f1/utils/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'theme/f1_team_schemes.dart';
import 'widgets/live_timing_data_table.dart';

/// Sector status from F1 API: 2064 = Overall Best (purple), 2048 = Personal Best (green), else = slower (yellow).
enum SectorStatus { purple, green, yellow }

/// Timing accents (light circuit-style UI).
const Color _kF1Purple = Color(0xFF5C2D91); // Deep purple — prominent on light bg
const Color _kF1Green = Color(0xFF0D9488); // Desaturated teal — personal best

/// Clean light live timing (circuit overview aesthetic).
const Color _kLiveDashboardBg = Color(0xFFF1F2F5);
const Color _kLivePrimaryText = Color(0xFF1A1D21);
const Color _kLiveSecondaryText = Color(0xFF6B7280);
const Color _kLiveCardSurface = Color(0xFFFFFFFF);
const Color _kLiveTimingPurple = Color(0xFF5C2D91);
const Color _kLiveCardBorder = Color(0xFFE5E7EB);

/// Soft elevation for cards on off-white page.
const List<BoxShadow> _kLiveCardShadow = [
  BoxShadow(color: Color(0x1F000000), blurRadius: 4, offset: Offset(0, 2)),
];

Color _liveTeamStripColor(Color team) =>
    Color.lerp(team, _kLiveCardSurface, 0.38) ?? team;

/// Silverstone 2024 race lap count (denominator for "LAP X/52").
const int _kDefaultRaceTotalLaps = 52;

/// Viewport width at which live timing uses ambient desktop layout (no vertical body scroll).
const int _kDesktopTimingBreakpoint = 960;

/// Card visual height + vertical gap between cards (ListView-style spacing).
const double _kLeaderCardHeight = 132.0;
const double _kLeaderCardGap = 12.0;
const double _kLeaderCardStride = _kLeaderCardHeight + _kLeaderCardGap;

/// Heuristic gap (s) added to [GapToLeader] for in-pit rejoin shadow row.
const double _kPitRejoinEstimateSeconds = 25.0;

/// Shorten sector time for badge (e.g. "29.302" -> "29.3").
String? _shortSectorTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final normalized = raw.replaceAll(',', '.');
  final d = double.tryParse(normalized);
  if (d != null) return d.toStringAsFixed(1);
  return raw.length > 5 ? raw.substring(0, 5) : raw;
}

/// F1 sector index for progress: API may send 0–2 or 1–3.
int _normalizeSectorIndexForProgress(dynamic raw) {
  if (raw == null) return 0;
  final v = raw is int ? raw : int.tryParse(raw.toString());
  if (v == null) return 0;
  if (v >= 1 && v <= 3) return v - 1;
  return v.clamp(0, 2);
}

/// F1 `NumberOfLaps` as int, [num], `{Value: n}`, or string — not raw `Map.toString()`.
int? _parseNumberOfLapsField(dynamic nl) {
  if (nl == null) return null;
  if (nl is int) return nl;
  if (nl is num) return nl.toInt();
  if (nl is Map) {
    final inner = nl['Value'] ?? nl['value'];
    if (inner != null) return _parseNumberOfLapsField(inner);
    return null;
  }
  return int.tryParse(nl.toString());
}

/// Like [_parseNumberOfLapsField] but defaults to [fallback] (e.g. 0).
int _parseNumberOfLapsFieldOr(dynamic nl, int fallback) =>
    _parseNumberOfLapsField(nl) ?? fallback;

/// Mini-segments shown per sector column (F1 often 8–10 per sector).
const int _kMiniSectorDisplayMin = 6;
const int _kMiniSectorDisplayMax = 10;

/// Ordered segment entries from F1 `Segments` map (keys "0","1",…).
List<Map<String, dynamic>> _orderedSegmentMaps(dynamic segmentsRaw) {
  if (segmentsRaw is! Map) return [];
  final m = <String, dynamic>{};
  for (final e in segmentsRaw.entries) {
    m[e.key.toString()] = e.value;
  }
  final keys = m.keys.map((k) => int.tryParse(k) ?? -1).where((k) => k >= 0).toList()..sort();
  final out = <Map<String, dynamic>>[];
  for (final k in keys) {
    final v = m[k.toString()];
    if (v is Map) {
      out.add(Map<String, dynamic>.from(v.map((k2, v2) => MapEntry(k2.toString(), v2))));
    }
  }
  return out;
}

Map<String, dynamic>? _sectorSubMap(Map<dynamic, dynamic>? sectors, int sectorIdx) {
  if (sectors == null) return null;
  final a = sectors['$sectorIdx'];
  final b = sectors[sectorIdx.toString()];
  final v = a ?? b;
  if (v is Map) {
    return Map<String, dynamic>.from(v.map((k2, v2) => MapEntry(k2.toString(), v2)));
  }
  return null;
}

MiniSectorTier _miniTierFromSegmentEntry(Map<String, dynamic> seg) {
  final stRaw = seg['Status'];
  final st = stRaw is int ? stRaw : int.tryParse(stRaw?.toString() ?? '');
  final ob = seg['OverallFastest'] == true || seg['overallFastest'] == true;
  final pb = seg['PersonalFastest'] == true || seg['personalFastest'] == true;
  if (ob || st == 2064 || st == 2048 || st == 204) return MiniSectorTier.overallBest;
  if (pb || st == 2044 || st == 201) return MiniSectorTier.personalBest;
  if (st != null && st != 0) return MiniSectorTier.neutral;
  // Split time present while Status still 0 → micro-sector already passed timing loop
  final val = seg['Value'] ?? seg['value'] ?? seg['Time'] ?? seg['time'];
  if (val != null && val.toString().trim().isNotEmpty) return MiniSectorTier.neutral;
  return MiniSectorTier.off;
}

int _inferLastFilledMiniIndex(List<Map<String, dynamic>> entries) {
  var last = -1;
  for (var i = 0; i < entries.length; i++) {
    if (_miniTierFromSegmentEntry(entries[i]) != MiniSectorTier.off) last = i;
  }
  return last;
}

/// True when the timing loop reports this micro-sector as finished (not merely a split placeholder).
bool _segmentCompletedForProgress(Map<String, dynamic> seg) {
  final stRaw = seg['Status'];
  final st = stRaw is int ? stRaw : int.tryParse(stRaw?.toString() ?? '');
  if (seg['OverallFastest'] == true || seg['overallFastest'] == true) return true;
  if (seg['PersonalFastest'] == true || seg['personalFastest'] == true) return true;
  if (st != null && st != 0) return true;
  return false;
}

int _inferLastCompletedMiniIndex(List<Map<String, dynamic>> entries) {
  var last = -1;
  for (var i = 0; i < entries.length; i++) {
    if (_segmentCompletedForProgress(entries[i])) last = i;
  }
  return last;
}

/// Solid tier only when [seg] is feed-confirmed complete (ignores split [Value] placeholders).
MiniSectorTier _miniTierFromCompletedSegment(Map<String, dynamic> seg) {
  if (!_segmentCompletedForProgress(seg)) return MiniSectorTier.off;
  final stRaw = seg['Status'];
  final st = stRaw is int ? stRaw : int.tryParse(stRaw?.toString() ?? '');
  final ob = seg['OverallFastest'] == true || seg['overallFastest'] == true;
  final pb = seg['PersonalFastest'] == true || seg['personalFastest'] == true;
  if (ob || st == 2064 || st == 2048 || st == 204) return MiniSectorTier.overallBest;
  if (pb || st == 2044 || st == 201) return MiniSectorTier.personalBest;
  return MiniSectorTier.neutral;
}

/// Ghost-safe wrapper: if the resolved tier is [overallBest] but this driver
/// is not the registered owner in [purpleOwners], downgrade to [personalBest].
MiniSectorTier _ghostSafeTier(
  Map<String, dynamic> seg,
  int sectorIdx,
  int segIdx,
  int? driverNum,
  Map<String, int>? purpleOwners,
) {
  final tier = _miniTierFromCompletedSegment(seg);
  if (tier != MiniSectorTier.overallBest) return tier;
  if (purpleOwners == null || driverNum == null) return tier;
  final owner = purpleOwners['${sectorIdx}_$segIdx'];
  if (owner != null && owner != driverNum) return MiniSectorTier.personalBest;
  return tier;
}

/// Deep-merge incoming `Sectors` map so one sector's partial `Segments` update does not drop other micro keys.
void mergeF1SectorsPayloadInto(Map<String, dynamic> mergedSectors, Map<String, dynamic> incomingSectors) {
  for (final s in incomingSectors.entries) {
    final sectorIdx = int.tryParse(s.key);
    if (sectorIdx == null || sectorIdx < 0 || sectorIdx > 2) continue;
    final key = s.key.toString();
    final incVal = s.value;
    if (incVal is! Map) {
      mergedSectors[key] = incVal;
      continue;
    }
    final incMap = Map<String, dynamic>.from(
      (incVal as Map).map((k, v) => MapEntry(k.toString(), v)),
    );
    final existing = mergedSectors[key];
    if (existing is Map) {
      final ex = Map<String, dynamic>.from(
        (existing as Map).map((k, v) => MapEntry(k.toString(), v)),
      );
      final incSegs = incMap['Segments'];
      if (incSegs is Map) {
        final exSegs = Map<String, dynamic>.from(
          (ex['Segments'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? {},
        );
        for (final e in (incSegs as Map).entries) {
          exSegs[e.key.toString()] = e.value;
        }
        ex['Segments'] = exSegs;
      }
      for (final e in incMap.entries) {
        if (e.key == 'Segments' && incSegs is Map) continue;
        if (e.value != null) ex[e.key] = e.value;
      }
      mergedSectors[key] = ex;
    } else {
      mergedSectors[key] = Map<String, dynamic>.from(incMap);
    }
  }
}

/// Real-time mini column from merged `Sectors[n].Segments`: solid fill only on completion; glow on next block from hub timestamps.
/// [purpleOwners] is the global purple owner map; if a segment is overallBest
/// but this driver is not the owner, it is rendered as personalBest (ghost prevention).
List<MiniSectorBlockVM> buildMiniSectorBlockColumn(
  String driverId,
  Map<String, dynamic> data,
  int sectorIdx,
  Map<String, double> segmentCompleteHubMs, {
  Map<String, int>? purpleOwners,
  int? driverNum,
}) {
  if (_liveDriverIsRetired(data)) {
    return List<MiniSectorBlockVM>.generate(
      _kMiniSectorDisplayMin,
      (_) => const MiniSectorBlockVM(fill: MiniSectorTier.off),
    );
  }
  final feedSec = inferCurrentSectorForDisplay(data);
  if (sectorIdx > feedSec) {
    return List<MiniSectorBlockVM>.generate(
      _kMiniSectorDisplayMin,
      (_) => const MiniSectorBlockVM(fill: MiniSectorTier.off),
    );
  }

  final secRoot = _sectorsRootFromData(data);
  final sub = _sectorSubMap(secRoot, sectorIdx);
  final entries = _orderedSegmentMaps(sub?['Segments']);
  final nSeg = entries.isEmpty
      ? _kMiniSectorDisplayMin
      : entries.length.clamp(_kMiniSectorDisplayMin, _kMiniSectorDisplayMax);

  final hubNow = data['_timingHubTsMs'] is double ? data['_timingHubTsMs'] as double : null;

  var lastCompleted = -1;
  for (var i = 0; i < entries.length; i++) {
    if (_segmentCompletedForProgress(entries[i])) lastCompleted = i;
  }

  final totalFeed = entries.length;

  /// Hub-based glow for the display slot that contains feed mini [nextFeed].
  double glowForSlotContainingFeedIndex(int displayIdx, int nextFeed) {
    if (sectorIdx != feedSec || totalFeed <= 0) return 0;
    final start = (displayIdx * totalFeed / nSeg).floor().clamp(0, totalFeed);
    final end = ((displayIdx + 1) * totalFeed / nSeg).ceil().clamp(0, totalFeed);
    if (nextFeed < start || nextFeed >= end) return 0;
    if (nextFeed < entries.length && _segmentCompletedForProgress(entries[nextFeed])) return 0;
    if (hubNow == null) return 0.18;
    final tPrev =
        lastCompleted >= 0 ? segmentCompleteHubMs['${driverId}_${sectorIdx}_$lastCompleted'] : null;
    final tPrev2 =
        lastCompleted >= 1 ? segmentCompleteHubMs['${driverId}_${sectorIdx}_${lastCompleted - 1}'] : null;
    var estMs = 1200.0;
    if (tPrev != null && tPrev2 != null) {
      estMs = (tPrev - tPrev2).abs().clamp(400, 8000);
    }
    if (tPrev == null) return 0.2;
    final raw = (hubNow - tPrev) / estMs;
    return raw.clamp(0.0, 0.42);
  }

  final out = <MiniSectorBlockVM>[];

  // Sectors already passed: show confirmed minis only (no glow).
  if (sectorIdx < feedSec) {
    for (var i = 0; i < nSeg; i++) {
      if (i < entries.length && _segmentCompletedForProgress(entries[i])) {
        out.add(MiniSectorBlockVM(
          fill: _ghostSafeTier(entries[i], sectorIdx, i, driverNum, purpleOwners),
          glow: 0,
        ));
      } else {
        out.add(const MiniSectorBlockVM(fill: MiniSectorTier.off, glow: 0));
      }
    }
    return out;
  }

  // Current sector: map each display column to a slice of feed minis so completion
  // fraction ≈ colored fraction (confirmed segments only; glow on active slice).
  final nextFeed = lastCompleted + 1;
  for (var i = 0; i < nSeg; i++) {
    if (totalFeed == 0) {
      out.add(MiniSectorBlockVM(
        fill: MiniSectorTier.off,
        glow: sectorIdx == feedSec ? glowForSlotContainingFeedIndex(i, nextFeed) : 0,
      ));
      continue;
    }
    final start = (i * totalFeed / nSeg).floor().clamp(0, totalFeed);
    final end = ((i + 1) * totalFeed / nSeg).ceil().clamp(0, totalFeed);
    var fill = MiniSectorTier.off;
    for (var j = start; j < end && j < entries.length; j++) {
      if (_segmentCompletedForProgress(entries[j])) {
        fill = _ghostSafeTier(entries[j], sectorIdx, j, driverNum, purpleOwners);
        break;
      }
    }
    final g = fill == MiniSectorTier.off ? glowForSlotContainingFeedIndex(i, nextFeed) : 0.0;
    out.add(MiniSectorBlockVM(fill: fill, glow: g));
  }
  return out;
}

/// Trailing car cannot show more filled mini-blocks than the driver directly ahead (avoids visual "overtake" glitches).
List<MiniSectorBlockVM> capMiniSectorColumnToAhead(
  List<MiniSectorBlockVM> self,
  List<MiniSectorBlockVM> ahead,
) {
  final aheadFilled = ahead.where((b) => b.fill != MiniSectorTier.off).length;
  final out = List<MiniSectorBlockVM>.from(self);
  final nonOffIdx = <int>[];
  for (var i = 0; i < out.length; i++) {
    if (out[i].fill != MiniSectorTier.off) nonOffIdx.add(i);
  }
  while (nonOffIdx.length > aheadFilled) {
    final ix = nonOffIdx.removeLast();
    out[ix] = const MiniSectorBlockVM(fill: MiniSectorTier.off, glow: 0);
  }
  return out;
}

Map<dynamic, dynamic>? _sectorsRootFromData(Map<String, dynamic> data) {
  final sectorsRaw = data['Sectors'];
  if (sectorsRaw is! Map) return null;
  return Map<dynamic, dynamic>.from(sectorsRaw.map((k, v) => MapEntry(k, v)));
}

/// When the feed omits [CurrentSectorIndex], defaulting to 0 made S2/S3 always "future" (empty).
/// Infer from (a) highest sector with segment activity and (b) fully completed earlier sectors.
int inferCurrentSectorForDisplay(Map<String, dynamic> data) {
  final explicit = data['ProgressCurrentSector'] ?? data['CurrentSectorIndex'];
  if (explicit != null) return _normalizeSectorIndexForProgress(explicit);

  final secRoot = _sectorsRootFromData(data);
  if (secRoot == null) return 0;

  var bestS = 0;
  var bestMetric = -1;
  for (var s = 0; s < 3; s++) {
    final sub = _sectorSubMap(secRoot, s);
    final entries = _orderedSegmentMaps(sub?['Segments']);
    final last = _inferLastFilledMiniIndex(entries);
    if (last >= 0) {
      final metric = s * 1000 + last;
      if (metric > bestMetric) {
        bestMetric = metric;
        bestS = s;
      }
    }
  }

  var completedThrough = -1;
  for (var s = 0; s < 3; s++) {
    final sub = _sectorSubMap(secRoot, s);
    final entries = _orderedSegmentMaps(sub?['Segments']);
    if (entries.isEmpty) break;
    // Avoid treating a partial S1 (only a few micros in JSON) as "lap left sector"
    if (entries.length < _kMiniSectorDisplayMin) break;
    var allDone = true;
    for (var i = 0; i < entries.length; i++) {
      if (_miniTierFromSegmentEntry(entries[i]) == MiniSectorTier.off) {
        allDone = false;
        break;
      }
    }
    if (!allDone) break;
    completedThrough = s;
  }
  final minCur = (completedThrough + 1).clamp(0, 2);
  if (bestMetric < 0) return minCur;
  final m = bestS > minCur ? bestS : minCur;
  return m.clamp(0, 2);
}

/// Current sector for **progress score** (API first, then inference).
/// Matches TimingData: `ProgressCurrentSector` / `CurrentSectorIndex` when present.
int _currentSectorForProgressScore(Map<String, dynamic> d) {
  final explicit = d['ProgressCurrentSector'] ?? d['CurrentSectorIndex'];
  if (explicit != null) return _normalizeSectorIndexForProgress(explicit);
  return inferCurrentSectorForDisplay(d);
}

/// Furthest micro index in [sector] for sorting: **feed-confirmed completion only**
/// (no [ProgressCurrentSegment] boost) to avoid packet-order “ghost” overtakes.
int _lastCompletedSegmentIndexInSector(Map<String, dynamic> d, int sectorIdx) {
  if (_liveDriverIsRetired(d)) return 0;
  final secRoot = _sectorsRootFromData(d);
  final sub = _sectorSubMap(secRoot, sectorIdx);
  final entries = _orderedSegmentMaps(sub?['Segments']);
  return _inferLastCompletedMiniIndex(entries).clamp(0, 99);
}

/// Leaderboard progress: `(LapsCompleted * 1000) + (CurrentSector * 100) + LastCompletedSegment)`.
/// Highest score = P1. Uses [_currentSectorForProgressScore] and completed minis in that sector only.
int _progressScore(Map<String, dynamic> d) {
  if (_liveDriverIsRetired(d)) return -1;
  final laps = _parseNumberOfLapsFieldOr(d['NumberOfLaps'], 0);
  final secNorm = _currentSectorForProgressScore(d);
  final segIdx = _lastCompletedSegmentIndexInSector(d, secNorm);
  var s = (laps.clamp(0, 999) * 1000) + (secNorm.clamp(0, 2) * 100) + segIdx;
  // Same lap/sector: on track slightly ahead of in pit for ordering.
  if (d['InPit'] == true) s -= 50;
  return s;
}

/// Latest stint object from `TimingData → Lines → [driverId] → Stints` (List **or** Map).
Map<String, dynamic>? _latestStintEntryFromStintsRaw(dynamic stints) {
  if (stints == null) return null;
  if (stints is List && stints.isNotEmpty) {
    final last = stints.last;
    if (last is Map) return Map<String, dynamic>.from(last.map((k, v) => MapEntry(k.toString(), v)));
    return null;
  }
  if (stints is Map && stints.isNotEmpty) {
    final keys = stints.keys.map((k) => int.tryParse(k.toString()) ?? -1).where((k) => k >= 0).toList()..sort();
    if (keys.isEmpty) return null;
    final kLast = keys.last;
    final v = stints[kLast.toString()] ?? stints[kLast];
    if (v is Map) return Map<String, dynamic>.from(v.map((k2, v2) => MapEntry(k2.toString(), v2)));
  }
  return null;
}

/// Strict S/M/H/I from F1 compound strings only (no single-char guess). Unknown → null (UI shows `?`).
String? _normalizeTyreCompoundLetter(dynamic compoundRaw) {
  if (compoundRaw == null) return null;
  final rawStr = compoundRaw is Map
      ? (compoundRaw['Value'] ?? compoundRaw['value'])?.toString()
      : compoundRaw.toString();
  if (rawStr == null) return null;
  final cstr = rawStr.toUpperCase().trim();
  if (cstr.isEmpty) return null;
  if (cstr.startsWith('SOFT') || cstr == 'S') return 'S';
  if (cstr.startsWith('MEDIUM') || cstr == 'M') return 'M';
  if (cstr.startsWith('HARD') || cstr == 'H') return 'H';
  if (cstr.startsWith('INTERMEDIATE') || cstr.contains('INTER') || cstr == 'I') return 'I';
  return null;
}

String? _tyreCompoundLetterFromStorage(dynamic raw) {
  final s = raw?.toString();
  if (s == null || s.isEmpty) return null;
  if (s == 'S' || s == 'M' || s == 'H' || s == 'I') return s;
  return null;
}

/// Index of the **current** stint (last entry): list → length−1; map → max numeric key.
int? _stintIndexFromStintsRaw(dynamic stints) {
  if (stints == null) return null;
  if (stints is List) {
    if (stints.isEmpty) return null;
    return stints.length - 1;
  }
  if (stints is Map && stints.isNotEmpty) {
    final keys = stints.keys.map((k) => int.tryParse(k.toString()) ?? -1).where((k) => k >= 0).toList()..sort();
    if (keys.isEmpty) return null;
    return keys.last;
  }
  return null;
}

/// True when [stints] has a last stint with a normalizable compound (used to avoid wiping grid tyres).
bool _stintsProvideMeaningfulCompound(dynamic stints) {
  final latest = _latestStintEntryFromStintsRaw(stints);
  if (latest == null) return false;
  return _normalizeTyreCompoundLetter(
        latest['Compound'] ?? latest['TyreCompound'] ?? latest['compound'],
      ) !=
      null;
}

dynamic _cloneJsonForStorage(dynamic v) {
  if (v is Map) {
    return Map<String, dynamic>.from(
      v.map((k, val) => MapEntry(k.toString(), _cloneJsonForStorage(val))),
    );
  }
  if (v is List) {
    return v.map(_cloneJsonForStorage).toList();
  }
  return v;
}

/// Hub tail matches official Silverstone TimingAppData grid-stint packet (13:57:10.085Z — any ms in that second).
bool _hubTimestampIsTimingAppDataGridAnchor(DateTime? utc) {
  if (utc == null) return false;
  final u = utc.toUtc();
  return u.hour == 13 && u.minute == 57 && u.second == 10;
}

bool _timingLinesPayloadHasStintsKey(Map<String, dynamic> lines) {
  for (final v in lines.values) {
    if (v is! Map) continue;
    final m = v as Map;
    if (m.containsKey('Stints') && m['Stints'] != null) return true;
  }
  return false;
}

void _applyStintTyreFieldsToTarget(Map<String, dynamic> stintMap, Map<String, dynamic> target) {
  final letter = _normalizeTyreCompoundLetter(
    stintMap['Compound'] ?? stintMap['TyreCompound'] ?? stintMap['compound'],
  );
  if (letter != null) {
    target['TyreCompound'] = letter;
  } else {
    target.remove('TyreCompound');
  }
}

/// Lap index when the **current** stint began (0 = start of session / grid). Used with [calculateTyreAge].
int? parseStintStartLapFromStint(Map<String, dynamic> stintMap) {
  dynamic raw = stintMap['StartLap'] ??
      stintMap['LapStart'] ??
      stintMap['StintStartLap'] ??
      stintMap['StartLapNumber'] ??
      stintMap['LapNumber'] ??
      stintMap['Lap'];
  if (raw is Map) raw = raw['Value'] ?? raw['value'];
  if (raw == null) return null;
  return raw is int ? raw : int.tryParse(raw.toString());
}

/// Tyre age in laps on current compound: `max(0, currentSessionLap - stintStartLap)`.
/// With [stintStartLap] 0 and [currentLap] 16 → 16 (no pit).
int calculateTyreAge(int stintStartLap, int currentSessionLap) {
  final a = currentSessionLap - stintStartLap;
  return a < 0 ? 0 : a;
}

/// Decode gzip+Base64 (or raw JSON) timing payload → map with `Lines`, etc. (grid-state / TimingData).
Map<String, dynamic>? decodeTimingDataFromBase64String(String raw) {
  final s = _normalizeMalformedBase64Padding(raw);
  if (s.isEmpty) return null;
  try {
    final bytes = base64Decode(s);
    List<int> decoded;
    try {
      decoded = GZipDecoder().decodeBytes(bytes);
    } catch (_) {
      decoded = bytes;
    }
    final obj = jsonDecode(utf8.decode(decoded));
    if (obj is Map<String, dynamic>) return obj;
    if (obj is Map) {
      return Map<String, dynamic>.from(
        obj.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
  } catch (_) {}
  return null;
}

/// Session clock from TimingData / TimingStats root (anchor for debounced resort).
double? _sessionTimeMsFromTimingPayload(Map<String, dynamic> payloadMap) {
  dynamic st = payloadMap['SessionTime'] ?? payloadMap['sessionTime'] ?? payloadMap['Clock'];
  if (st is Map) st = st['Value'] ?? st['value'];
  if (st == null) return null;
  final s = st.toString().trim();
  if (s.isEmpty) return null;
  try {
    final parts = s.split(':');
    if (parts.length == 3) {
      final h = int.parse(parts[0].trim());
      final m = int.parse(parts[1].trim());
      final sec = double.parse(parts[2].replaceAll(',', '.'));
      return ((h * 3600 + m * 60) + sec) * 1000.0;
    }
    if (parts.length == 2) {
      final m = int.parse(parts[0].trim());
      final sec = double.parse(parts[1].replaceAll(',', '.'));
      return ((m * 60) + sec) * 1000.0;
    }
    final plain = double.tryParse(s.replaceAll(',', '.'));
    if (plain != null) return plain * 1000.0;
  } catch (_) {}
  return null;
}

/// Smaller = closer to leader (pit rejoin estimate only).
double _gapToLeaderSortOrdinal(Map<String, dynamic> d) {
  if (_liveDriverIsRetired(d)) return 999999.0;
  final raw = (d['GapToLeader'] ?? '').toString().trim();
  if (raw.isEmpty || raw == '–' || raw == '-') return 999998.0;
  final u = raw.toUpperCase();
  if (u.contains('OUT') || u.contains('STOPPED') || u.contains('RETIRED') || u.contains('DNF')) {
    return 999999.0;
  }
  if (u.contains('LAP') && !RegExp(r'\d+\.\d').hasMatch(raw)) {
    return 888888.0;
  }
  final cleaned = raw.replaceFirst(RegExp(r'^\+'), '').trim();
  final v = double.tryParse(cleaned);
  if (v != null) return v;
  return 999998.0;
}

/// True if driver is out / stopped / retired (from flags or gap text).
bool _liveDriverIsRetired(Map<String, dynamic> data) {
  if (data['Stopped'] == true || data['Retired'] == true) return true;
  final g = (data['GapToLeader'] ?? '').toString().toUpperCase().trim();
  if (g.contains('OUT') || g == 'STOPPED' || g.contains('RETIRED') || g.contains('DNF')) {
    return true;
  }
  return false;
}

/// Speed trap km/h from merged Speeds.ST.Value.
String? _speedTrapKmhFromData(Map<String, dynamic> data) {
  final speeds = data['Speeds'];
  if (speeds is! Map) return null;
  final st = speeds['ST'];
  if (st is! Map) return null;
  final v = st['Value'] ?? st['value'];
  final s = v?.toString().trim();
  if (s == null || s.isEmpty) return null;
  return s;
}

/// Production URL for the F1 Live Timing proxy (Silverstone replay).
const String kLiveTimingProxyBase = String.fromEnvironment(
  'LIVE_TIMING_PROXY',
  defaultValue: 'https://f1-live-timing-proxy.89wph6ymgg.workers.dev',
);

/// Fix copy-paste base64 where `=` padding leaves length not multiple of 4.
String _normalizeMalformedBase64Padding(String raw) {
  var s = raw.trim().replaceAll(RegExp(r'\s'), '');
  if (s.length % 4 == 0) return s;
  s = s.replaceAll('=', '');
  while (s.length % 4 != 0) {
    s += '=';
  }
  return s;
}

/// Silverstone 2024 driver number -> name mapping (for Position.z fallback).
const Map<int, String> _silverstone2024Drivers = {
  1: 'Max Verstappen',
  2: 'Logan Sargeant',
  3: 'Daniel Ricciardo',
  4: 'Lando Norris',
  10: 'Pierre Gasly',
  11: 'Sergio Pérez',
  14: 'Fernando Alonso',
  16: 'Charles Leclerc',
  18: 'Lance Stroll',
  20: 'Kevin Magnussen',
  22: 'Yuki Tsunoda',
  23: 'Alexander Albon',
  24: 'Zhou Guanyu',
  27: 'Nico Hülkenberg',
  31: 'Esteban Ocon',
  44: 'Lewis Hamilton',
  55: 'Carlos Sainz',
  63: 'George Russell',
  77: 'Valtteri Bottas',
  81: 'Oscar Piastri',
};

/// Silverstone 2024 team names by driver number.
const Map<int, String> _silverstone2024Teams = {
  1: 'Red Bull Racing',
  2: 'Williams',
  3: 'RB',
  4: 'McLaren',
  10: 'Alpine',
  11: 'Red Bull Racing',
  14: 'Aston Martin',
  16: 'Ferrari',
  18: 'Aston Martin',
  20: 'Haas',
  22: 'RB',
  23: 'Williams',
  24: 'Kick Sauber',
  27: 'Haas',
  31: 'Alpine',
  44: 'Mercedes',
  55: 'Ferrari',
  63: 'Mercedes',
  77: 'Kick Sauber',
  81: 'McLaren',
};

/// 2024 British GP starting grid P1→P20 (racing numbers). Used at T-zero if [Position] missing.
const List<String> _kSilverstone2024RaceGridOrder = [
  '63', '44', '4', '1', '81', '55', '14', '18', '10', '27',
  '23', '3', '22', '77', '24', '31', '11', '20', '2', '16',
];

/// Grid / timing [Position] for sort tie-break when [_progressScore] is equal (e.g. lap 0).
int _gridPositionOrdinal(Map<String, dynamic> d) {
  final p = d['Position'];
  if (p is int) return p;
  final pv = int.tryParse(p?.toString() ?? '');
  if (pv != null) return pv;
  final n = d['number'];
  final numStr = n is int ? '$n' : n?.toString();
  if (numStr != null && numStr.isNotEmpty) {
    final idx = _kSilverstone2024RaceGridOrder.indexOf(numStr);
    if (idx >= 0) return idx + 1;
  }
  return 999;
}

/// Walk RaceControl JSON (Messages map/list or nested) for RACE STARTED + GREEN.
bool _scanRaceControlForGreenStart(dynamic node, void Function(DateTime? utc) onMatch) {
  if (node is Map) {
    final msg = node['Message'] ?? node['message'];
    final flag = node['Flag'] ?? node['flag'];
    if (msg != null && flag != null) {
      final m = msg.toString().toUpperCase();
      final f = flag.toString().toUpperCase();
      if (m.contains('RACE STARTED') && f.contains('GREEN')) {
        DateTime? t;
        final utcRaw = node['Utc'] ?? node['UTC'] ?? node['MessageTime'] ?? node['messageTime'];
        if (utcRaw != null) t = DateTime.tryParse(utcRaw.toString());
        onMatch(t);
        return true;
      }
    }
    for (final v in node.values) {
      if (_scanRaceControlForGreenStart(v, onMatch)) return true;
    }
  } else if (node is List) {
    for (final v in node) {
      if (_scanRaceControlForGreenStart(v, onMatch)) return true;
    }
  }
  return false;
}

/// Monospaced INT/GAP text (leader lap time or `+0.000` interval) — avoids digit jump.
Widget _buildIntervalWidget(
  String text, {
  double fontSize = 10,
  FontWeight fontWeight = FontWeight.w600,
  Color color = _kF1Purple,
  TextAlign textAlign = TextAlign.start,
}) {
  return Text(
    text,
    textAlign: textAlign,
    style: GoogleFonts.robotoMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    ),
  );
}

/// Parses [GapToLeader] to seconds when numeric (`+2.414`); null for LAP/OUT/unset.
double? _gapToLeaderSecondsFromDriver(Map<String, dynamic> d) {
  dynamic raw = d['GapToLeader'];
  if (raw is Map) raw = raw['Value'] ?? raw['value'];
  if (raw == null) return null;
  var s = raw.toString().trim();
  if (s.isEmpty || s == '–' || s == '-') return null;
  final u = s.toUpperCase();
  if (u.contains('OUT') || u.contains('STOPPED') || u.contains('RETIRED') || u.contains('DNF')) {
    return null;
  }
  if (u.contains('LAP') && !RegExp(r'\d+\.\d').hasMatch(s)) return null;
  s = s.replaceFirst(RegExp(r'^[+\-]'), '').trim();
  return double.tryParse(s);
}

String _formatPositiveIntervalTriple(double seconds) =>
    '+${seconds.abs().toStringAsFixed(3)}';

/// Forces a numeric timing string to `+X.XXX`; keeps LAP-style text from [_formatGap].
String _intervalStringForcePositive(String raw) {
  final t = raw.trim();
  if (t.isEmpty || t == '–') return '–';
  final u = t.toUpperCase();
  if (u.contains('LAP') || RegExp(r'\d+L\b').hasMatch(u)) return _formatGap(t);
  final cleaned = t.replaceFirst(RegExp(r'^[+\-]'), '').trim();
  final v = double.tryParse(cleaned);
  if (v != null) return _formatPositiveIntervalTriple(v);
  return t;
}

/// INT/GAP for P2–P20: `|(GapToLeader_X - GapToLeader_above)|`, always `+` prefix.
String _intervalFromSortedPositionFormatted(
  Map<String, dynamic> driver,
  Map<String, dynamic> driverImmediatelyAbove,
) {
  if (_liveDriverIsRetired(driver)) {
    return driver['Stopped'] == true ? 'STOP' : 'OUT';
  }
  final cur = _gapToLeaderSecondsFromDriver(driver);
  final above = _gapToLeaderSecondsFromDriver(driverImmediatelyAbove);
  if (cur != null || above != null) {
    final c = cur ?? 0.0;
    final a = above ?? 0.0;
    return _formatPositiveIntervalTriple(c - a);
  }
  dynamic iv = driver['IntervalToPrimary'];
  if (iv is Map) iv = iv['Value'] ?? iv['value'];
  if (iv != null && iv.toString().trim().isNotEmpty) {
    return _intervalStringForcePositive(iv.toString());
  }
  dynamic g = driver['GapToLeader'];
  if (g is Map) g = g['Value'] ?? g['value'];
  if (g != null && g.toString().trim().isNotEmpty) {
    return _intervalStringForcePositive(g.toString());
  }
  return '–';
}

/// Formats gap string: "LAP"/"1L"/"2L" -> "+1 Lap", "+2 Laps", etc.
String _formatGap(String gap) {
  if (gap.isEmpty || gap == '–') return gap;
  final upper = gap.toUpperCase();
  if (upper.contains('LAP') || RegExp(r'\d+L').hasMatch(gap)) {
    final match = RegExp(r'(\d+)').firstMatch(gap);
    final n = match != null ? int.tryParse(match.group(1)!) ?? 1 : 1;
    return '+$n ${n == 1 ? 'Lap' : 'Laps'}';
  }
  return gap;
}

/// Formats gap/interval strings to three decimals (top-level for sort/timing helpers).
String _formatGapThreeDecimalsTop(String raw) {
  if (raw.isEmpty || raw == '–') return raw;
  if (raw.toUpperCase().contains('LAP')) return _formatGap(raw);
  final trimmed = raw.trim();
  final neg = trimmed.startsWith('-');
  final clean = trimmed.replaceFirst('+', '').replaceFirst('-', '').trim();
  final d = double.tryParse(clean);
  if (d != null) {
    final sign = neg ? '-' : '+';
    return '$sign${d.abs().toStringAsFixed(3)}';
  }
  return raw;
}

/// Silverstone 2024 driver ID (string) -> name for display.
const Map<String, String> _driverNames = {
  '1': 'Max Verstappen',
  '2': 'Logan Sargeant',
  '3': 'Daniel Ricciardo',
  '4': 'Lando Norris',
  '10': 'Pierre Gasly',
  '11': 'Sergio Pérez',
  '14': 'Fernando Alonso',
  '16': 'Charles Leclerc',
  '18': 'Lance Stroll',
  '20': 'Kevin Magnussen',
  '22': 'Yuki Tsunoda',
  '23': 'Alexander Albon',
  '24': 'Zhou Guanyu',
  '27': 'Nico Hülkenberg',
  '31': 'Esteban Ocon',
  '44': 'Lewis Hamilton',
  '55': 'Carlos Sainz',
  '63': 'George Russell',
  '77': 'Valtteri Bottas',
  '81': 'Oscar Piastri',
};

/// F1 3-letter driver codes (Silverstone 2024 grid).
const Map<int, String> _driverAbbrev = {
  1: 'VER',
  2: 'SAR',
  3: 'RIC',
  4: 'NOR',
  10: 'GAS',
  11: 'PER',
  14: 'ALO',
  16: 'LEC',
  18: 'STR',
  20: 'MAG',
  22: 'TSU',
  23: 'ALB',
  24: 'ZHO',
  27: 'HUL',
  31: 'OCO',
  44: 'HAM',
  55: 'SAI',
  63: 'RUS',
  77: 'BOT',
  81: 'PIA',
};

/// Protected Live Timing page. Requires auth; redirects to login if not logged in.
class LiveTimingPage extends StatefulWidget {
  const LiveTimingPage({
    super.key,
    this.initialReplayFrame,
    this.resumeSessionLabelFromRoute,
  });

  /// When set (>0), WebSocket connects with `start_offset` at this frame (resume).
  final int? initialReplayFrame;

  /// Optional label from deep link (`?session=`) for display / saved progress.
  final String? resumeSessionLabelFromRoute;

  @override
  State<LiveTimingPage> createState() => _LiveTimingPageState();
}

class _LiveTimingPageState extends State<LiveTimingPage>
    with TickerProviderStateMixin {
  DisplaySettingsController? _displaySettingsCtrl;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _useTestData = true; // Silverstone replay by default
  /// Driver ID -> { position, lastLapTime, gapToLeader, team, ... }
  Map<String, dynamic> _driverStorage = {};
  List<String> _sortedDriverIds = [];
  List<LiveDriverEntry> _leaderboard = [];
  double _replaySpeed = 1.0;
  DateTime? _sessionStartTime; // When first frame received (wall clock)
  DateTime? _firstDataTimestamp; // First data timestamp from frames
  DateTime? _latestDataTimestamp; // Latest data timestamp (for time display)
  double? _sessionFirstTsMs; // First timestamp in ms (for slider range)
  double? _sessionLastTsMs; // Last timestamp in ms (for slider range)
  /// Total race laps for leader line "LAP n/N" (default Silverstone GP).
  int _raceTotalLaps = _kDefaultRaceTotalLaps;
  /// Sector status: driverNumber -> {sectorIndex: SectorStatus}
  /// 2064 = purple (overall best), 2048 = green (personal best), else = yellow (slower)
  Map<int, Map<int, SectorStatus>> _sectorHighlights = {};
  /// Fastest lap time string for session (e.g. "1:29.834") for purple last-lap styling.
  String? _fastestLapTime;
  /// Previous sorted list index per driver (for overtake arrows).
  Map<String, int> _previousListIndexByDriverId = {};
  /// 1 = moved up (better), -1 = down, 0 = unchanged / first frame.
  Map<String, int> _positionTrendByDriverId = {};
  /// WebSocket frames received (for worker `start_offset` on speed reconnect).
  int _replayFrameCount = 0;
  /// Session-best sector holders (purple) → 3-letter code per sector index.
  Map<int, String> _sectorBestCodes = {0: '', 1: '', 2: ''};
  /// Global Purple Validator: "sectorIdx_segIdx" → driver number who holds
  /// overall-best (purple) for that specific micro-sector segment.
  Map<String, int> _purpleSegmentOwner = {};
  /// Absolute Session Best: "sectorIdx_segIdx" → fastest duration (seconds)
  /// recorded for that segment across the entire session.
  Map<String, double> _purpleSegmentBestSec = {};
  /// F1 HUB desktop rail: 0 home, 1 live timing (this page).
  int _hubNavIndex = 1;
  late AnimationController _livePulseController;
  /// One-shot slide-up for leaderboard after removing teammate strip (600ms).
  late AnimationController _leaderboardEntranceAnim;

  /// Last hub message timestamp (ms) for segment glow interpolation (live.txt / SignalR trailing ISO string).
  double? _lastTimingHubTsMs;
  /// `"${driverId}_${sectorIdx}_${segIndex}"` → hub ms when that micro was last seen completed (lap reset clears driver keys).
  final Map<String, double> _microSegmentCompleteHubMs = {};

  /// Debounced leaderboard resort so staggered per-driver TimingData lines merge before re-sort.
  Timer? _resortDebounceTimer;
  static const int _kResortDebounceMs = 500;
  /// Last [SessionTime] from payload root (ms), when present (for future clock-bucket sync).
  // ignore: unused_field
  double? _lastSortSessionAnchorMs;

  /// Until RaceControl `RACE STARTED` + GREEN: accumulate TimingData but no leaderboard resort.
  bool _raceTimingLiveActive = false;
  /// Official GREEN instant from RaceControl [Utc] (or hub time). Pre-buffer = 15s before this.
  DateTime? _scheduledRaceGreenUtc;
  /// True during [greenUtc - 15s, greenUtc): grid-locked leaderboard + STARTING GRID.
  bool _racePreStartBufferActive = false;
  /// Official race start (RaceControl UTC or hub time fallback).
  // ignore: unused_field
  DateTime? _raceStartedUtc;

  /// After the first TimingData frame that includes any `Lines[..].Stints`, grid tyre labels use INITIAL LOAD.
  bool _initialStintsTimingDataConsumed = false;

  /// One-shot: [TimingAppData] at ~13:57:10Z seeded [Stints] + `GRID INITIALIZED`.
  bool _timingAppDataGridSeeded = false;

  /// Grid positions captured at initialization (driverId → grid position int).
  /// Used to compute gain/loss: `_gridPositions[id]! - currentPosition`.
  final Map<String, int> _gridPositions = {};

  /// FIA track status code: 1=Green, 2=Yellow, 4=SC, 5=Red, 6=VSC Deployed, 7=VSC Ending.
  int _trackStatusCode = 1;
  /// Human-readable label derived from [_trackStatusCode].
  String _trackStatusMessage = '';

  /// Per-driver pit-entry UTC timestamp (set when InPit transitions true). For live PIT timer.
  final Map<String, DateTime> _pitEntryTimestamps = {};

  /// Per-driver out-lap flag: true for the first lap after exiting pit.
  final Map<String, bool> _outLapFlags = {};

  /// Track limit warnings count per driver number (from RaceControlMessages).
  final Map<int, int> _trackLimitsByDriver = {};

  /// Per-driver gap trend: +1 gap growing (slower), -1 gap shrinking (faster), 0 stable.
  final Map<String, int> _gapTrendByDriver = {};
  /// Previous gap values for trend computation (raw numeric).
  final Map<String, double> _previousGapValues = {};

  /// Session / weather from `SessionInfo` & `WeatherData` frames.
  String _sessionTypeLabel = '';
  String _sessionPartLabel = '';
  double? _airTempC;
  double? _trackTempC;
  bool _rainActive = false;

  @override
  void initState() {
    super.initState();
    final start = widget.initialReplayFrame;
    if (start != null && start > 0) {
      _replayFrameCount = start;
    }
    _livePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _leaderboardEntranceAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _displaySettingsCtrl = context.read<DisplaySettingsController>();
    _checkAuthAndConnect();
  }

  @override
  void deactivate() {
    _persistLiveProgressToProfile();
    super.deactivate();
  }

  void _persistLiveProgressToProfile() {
    final ctrl = _displaySettingsCtrl;
    if (ctrl == null) return;
    if (Supabase.instance.client.auth.currentUser == null) return;
    if (_replayFrameCount <= 0) return;
    var label = '${_sessionTypeLabel} ${_sessionPartLabel}'.trim();
    if (label.isEmpty) {
      label = widget.resumeSessionLabelFromRoute?.trim() ?? '';
    }
    if (label.isEmpty) label = 'Live timing';
    unawaited(
      ctrl.updateSettings(
        ctrl.settings.copyWith(
          liveTimingLastFrame: _replayFrameCount,
          liveTimingLastTimestampIso:
              DateTime.now().toUtc().toIso8601String(),
          liveTimingSessionLabel: label,
        ),
      ),
    );
  }

  Future<void> _checkAuthAndConnect() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }
    _connect(resetReplayOffset: _replayFrameCount <= 0);
  }

  String _wsUrl() {
    final base = kLiveTimingProxyBase;
    final scheme = base.startsWith('https') ? 'wss' : 'ws';
    final host = base
        .replaceFirst('https://', '')
        .replaceFirst('http://', '');
    final params = <String>[];
    if (_useTestData) params.add('test=true');
    params.add('speed=$_replaySpeed');
    if (_replayFrameCount > 0) {
      params.add('start_offset=$_replayFrameCount');
    }
    return '$scheme://$host?${params.join('&')}';
  }

  void _connect({bool resetReplayOffset = true}) {
    _disconnect();
    if (resetReplayOffset) {
      setState(() {
        _replayFrameCount = 0;
        _sessionStartTime = null;
        _firstDataTimestamp = null;
        _latestDataTimestamp = null;
        _sessionFirstTsMs = null;
        _sessionLastTsMs = null;
        _previousListIndexByDriverId = {};
        _positionTrendByDriverId = {};
        _driverStorage = {};
        _sortedDriverIds = [];
        _leaderboard = [];
        _sectorHighlights = {};
        _purpleSegmentOwner = {};
        _purpleSegmentBestSec = {};
        _fastestLapTime = null;
        _raceTimingLiveActive = false;
        _raceStartedUtc = null;
        _scheduledRaceGreenUtc = null;
        _racePreStartBufferActive = false;
        _initialStintsTimingDataConsumed = false;
        _timingAppDataGridSeeded = false;
        _gridPositions.clear();
        _trackStatusCode = 1;
        _trackStatusMessage = '';
        _pitEntryTimestamps.clear();
        _outLapFlags.clear();
        _trackLimitsByDriver.clear();
        _gapTrendByDriver.clear();
        _previousGapValues.clear();
      });
      _leaderboardEntranceAnim.forward(from: 0);
    }
    try {
      final channel = WebSocketChannel.connect(Uri.parse(_wsUrl()));
      _channel = channel;
      _subscription = channel.stream.listen(
        _onMessage,
        onError: (e) => _handleError(e.toString()),
        onDone: () => _handleError('Connection closed'),
      );
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _disconnect() {
    _resortDebounceTimer?.cancel();
    _resortDebounceTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void _onMessage(dynamic data) {
    if (!mounted) return;
    try {
      final raw = data is String ? data : utf8.decode(data);
      _processMessage(raw);
    } catch (_) {}
  }

  /// Processes raw WebSocket payload. Format-agnostic: handles Type A (wrapped) and Type B (direct).
  void _processMessage(dynamic rawData) {
    if (!mounted) return;
    final raw = rawData is String ? rawData : utf8.decode(rawData as List<int>);

    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return;

      final mVal = map['M'];
      final args = map['A'] as List<dynamic>?;

      // Heartbeat: {"M":"Hello from Cloudflare"} or similar – no processable payload
      if (mVal is String && (args == null || args.isEmpty)) {
        return;
      }

      // Type A (Wrapped): json['M'] is a List – standard SignalR batch
      // {"M": [{"H":"Streaming","M":"ReceiveMessage","A":["TimingData",{...},"2024-07-07T13:24:02.223Z"]}]}
      if (mVal is List) {
        for (final hub in mVal) {
          if (hub is! Map) continue;
          final hubArgs = hub['A'] as List<dynamic>?;
          if (hubArgs == null || hubArgs.length < 2) continue;
          _captureHubTimestamp(hubArgs);
          _dispatchByType(hubArgs[0]?.toString(), hubArgs[1]);
        }
        _replayFrameCount++;
        if (mounted) setState(() {});
        return;
      }

      // Type B (Direct): json['M'] == "feed" – GitHub live.txt format
      // {"H":"Streaming","M":"feed","A":["TimingData",{...},"2024-07-07T13:24:02.223Z"]}
      if ((mVal == 'feed' || mVal == 'Feed') && args != null && args.length >= 2) {
        _captureHubTimestamp(args);
        _dispatchByType(args[0]?.toString(), args[1]);
        _replayFrameCount++;
        if (mounted) setState(() {});
        return;
      }

      // Fallback: root-level A with type + payload (some variants)
      if (args != null && args.length >= 2) {
        _captureHubTimestamp(args);
        _dispatchByType(args[0]?.toString(), args[1]);
        _replayFrameCount++;
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  void _captureHubTimestamp(List<dynamic>? hubArgs) {
    if (hubArgs == null || hubArgs.length < 3) return;
    final tsStr = hubArgs[hubArgs.length - 1]?.toString();
    if (tsStr == null || tsStr.isEmpty) return;
    final dataTs = DateTime.tryParse(tsStr);
    if (dataTs == null) return;
    final dataTsMs = dataTs.millisecondsSinceEpoch.toDouble();
    _lastTimingHubTsMs = dataTsMs;
    _sessionFirstTsMs ??= dataTsMs;
    _sessionLastTsMs = dataTsMs;
    _firstDataTimestamp ??= dataTs;
    _latestDataTimestamp = dataTs;
    _sessionStartTime ??= DateTime.now();
  }

  void _clearMicroSegmentHubMsForDriver(String driverId) {
    for (final k in _microSegmentCompleteHubMs.keys.toList()) {
      if (k.startsWith('${driverId}_')) _microSegmentCompleteHubMs.remove(k);
    }
  }

  void _syncMicroSegmentCompletionTimestamps(String driverId, Map<String, dynamic> driverData) {
    final hub = _lastTimingHubTsMs;
    if (hub == null) return;
    driverData['_timingHubTsMs'] = hub;
    final secRoot = _sectorsRootFromData(driverData);
    if (secRoot == null) return;
    for (var s = 0; s < 3; s++) {
      final entries = _orderedSegmentMaps(_sectorSubMap(secRoot, s)?['Segments']);
      for (var i = 0; i < entries.length; i++) {
        if (_segmentCompletedForProgress(entries[i])) {
          _microSegmentCompleteHubMs['${driverId}_${s}_$i'] = hub;
        }
      }
    }
  }

  /// Keys that must never be overwritten with empty/null values once established.
  static const Set<String> _kProtectedKeys = {
    'TyreCompound',
    'TyreAge',
    '_StintStartLap',
    'TyreNew',
    'TyreDataSource',
    '_GridPos',
  };

  /// Zero-loss deep merge: recursively merge [source] into [target].
  /// - `null` source values are ignored.
  /// - [_kProtectedKeys]: source empty/null never overwrites an existing non-null target value.
  /// - `Sectors`: per-sector `Segments` are deep-merged (not replaced).
  /// - `Stints`: empty maps/lists/non-meaningful compounds never wipe existing usable data.
  static void _robustDeepMerge(Map<String, dynamic> target, Map<String, dynamic> source) {
    for (final e in source.entries) {
      final key = e.key;
      final srcVal = e.value;
      if (srcVal == null) continue;
      final tgtVal = target[key];

      if (_kProtectedKeys.contains(key)) {
        if (tgtVal != null) {
          final sStr = srcVal.toString().trim();
          if (sStr.isEmpty || sStr == 'null') continue;
        }
        target[key] = srcVal;
        continue;
      }

      if (key == 'Sectors' && srcVal is Map) {
        final merged = Map<String, dynamic>.from(
          (tgtVal is Map ? tgtVal : <dynamic, dynamic>{}).map((k, v) => MapEntry(k.toString(), v)),
        );
        mergeF1SectorsPayloadInto(
          merged,
          Map<String, dynamic>.from((srcVal as Map).map((k, v) => MapEntry(k.toString(), v))),
        );
        target[key] = merged;
        continue;
      }

      if (key == 'Stints') {
        final tgtUsable = _stintsProvideMeaningfulCompound(tgtVal);
        final srcUsable = _stintsProvideMeaningfulCompound(srcVal);
        if (!srcUsable && tgtUsable) continue;
        if (srcVal is Map && (srcVal as Map).isEmpty && tgtVal != null) continue;
        if (srcVal is Map && tgtVal is Map) {
          final merged = Map<String, dynamic>.from(
            (tgtVal as Map).map((k, v) => MapEntry(k.toString(), v)),
          );
          for (final se in (srcVal as Map).entries) {
            merged[se.key.toString()] = se.value;
          }
          target[key] = merged;
          continue;
        }
        if (srcVal is List) {
          if ((srcVal as List).isEmpty && tgtVal != null) continue;
          target[key] = srcVal;
          continue;
        }
      }

      if (srcVal is Map && tgtVal is Map) {
        final tgtMap = Map<String, dynamic>.from(tgtVal);
        _robustDeepMerge(tgtMap, Map<String, dynamic>.from(srcVal));
        target[key] = tgtMap;
      } else {
        target[key] = srcVal;
      }
    }
  }

  /// Alias retained for the two places that need raw (non-protected) merge semantics.
  static void _deepMerge(Map<String, dynamic> target, Map<String, dynamic> source) =>
      _robustDeepMerge(target, source);

  void _dispatchByType(String? dataType, dynamic payload) {
    switch (dataType) {
      case 'TimingData':
        _handleTimingUpdate(payload);
        break;
      case 'TimingAppData':
        debugPrint('[TYRE-TRACE] _dispatchByType: TimingAppData dispatched');
        _handleTimingAppData(payload);
        break;
      case 'Position.z':
        _handlePositionZ(payload);
        break;
      case 'Heartbeat':
        if (mounted) setState(() {});
        break;
      case 'TimingStats':
        _handleTimingStats(payload);
        break;
      case 'WeatherData':
        _handleWeatherData(payload);
        break;
      case 'SessionInfo':
        _handleSessionInfo(payload);
        break;
      case 'RaceControl':
      case 'raceControl':
        _handleRaceControl(payload);
        break;
      case 'TrackStatus':
      case 'trackStatus':
        _handleTrackStatus(payload);
        break;
      default:
        break;
    }
  }

  /// Official grid tyre source: processes TimingAppData additively until
  /// enough drivers have meaningful compounds (≥14). Multiple frames are
  /// merged safely — non-empty stints are never overwritten by empty ones.
  void _handleTimingAppData(dynamic payload) {
    debugPrint('[TYRE-TRACE] _handleTimingAppData called — seeded=$_timingAppDataGridSeeded, payload is Map=${payload is Map}');
    if (payload is! Map) return;
    if (_timingAppDataGridSeeded) {
      debugPrint('[TYRE-TRACE] Grid already fully seeded — skipping TimingAppData');
      return;
    }
    final payloadMap = Map<String, dynamic>.from(payload as Map);
    final hasLines = payloadMap['Lines'] is Map && (payloadMap['Lines'] as Map).isNotEmpty;
    if (!hasLines) {
      debugPrint('[TYRE-TRACE] TimingAppData has no Lines — skipping');
      return;
    }
    debugPrint('[TYRE-TRACE] TimingAppData received (${(payloadMap["Lines"] as Map).length} drivers) @ ${_latestDataTimestamp?.toUtc()}');
    _initializeGridFromAppData(payloadMap);
  }

  /// Parses TimingAppData `Lines` → [_driverStorage]: starting stints + `New` flag, grid positions, tyre source tag.
  /// Processes ALL drivers in the payload — even those without stints get name/team/position.
  void _initializeGridFromAppData(Map<String, dynamic> root) {
    final linesRaw = root['Lines'] ?? root['lines'];
    final lines = linesRaw is Map
        ? Map<String, dynamic>.from(
            (linesRaw as Map).map((k, v) => MapEntry(k.toString(), v)),
          )
        : null;
    if (lines == null || lines.isEmpty) return;

    for (final e in lines.entries) {
      final driverId = e.key.toString();
      if (int.tryParse(driverId) == null) continue;
      final line = e.value;
      if (line is! Map) continue;
      final lineMap = Map<String, dynamic>.from(
        line.map((k, v) => MapEntry(k.toString(), v)),
      );

      final existing = Map<String, dynamic>.from(_driverStorage[driverId] as Map? ?? {});
      final num = int.tryParse(driverId);
      if (num != null) {
        existing['number'] = num;
        existing['name'] = _driverNames[driverId] ?? existing['name']?.toString() ?? 'Driver $driverId';
        existing['team'] = _silverstone2024Teams[num] ?? existing['team']?.toString() ?? '';
      }

      // --- Capture GridPos for gain/loss ---
      final posRaw = lineMap['Position'] ?? lineMap['GridPos'] ?? lineMap['GridPosition'];
      if (posRaw != null) {
        final pv = posRaw is int ? posRaw : int.tryParse(posRaw.toString());
        if (pv != null) {
          existing['Position'] = pv;
          existing['_GridPos'] = pv;
          _gridPositions[driverId] = pv;
        }
      }

      // --- Stints: only store if non-empty (an earlier TimingAppData may have empty [] placeholders) ---
      final stints = lineMap['Stints'];
      if (stints != null) {
        final isEmpty = (stints is List && stints.isEmpty) || (stints is Map && (stints as Map).isEmpty);
        if (!isEmpty) {
          existing['Stints'] = _cloneJsonForStorage(stints);
        }
      }

      final latestStint = _latestStintEntryFromStintsRaw(existing['Stints']);
      if (latestStint != null) {
        final isNew = latestStint['New'] ?? latestStint['new'];
        if (isNew is bool) {
          existing['TyreNew'] = isNew;
        } else if (isNew != null) {
          existing['TyreNew'] = isNew.toString().toLowerCase() == 'true';
        }
      }

      _syncTyreFromMergedDriverStints(existing);
      if (_stintsProvideMeaningfulCompound(existing['Stints'])) {
        existing['TyreDataSource'] = 'GRID INITIALIZED';
      } else {
        existing['TyreDataSource'] ??= 'UNKNOWN';
      }

      existing['NumberOfLaps'] ??= 0;
      _driverStorage[driverId] = existing;
    }

    _bootstrapFullGridSilverstone2024();

    // Count how many drivers across ALL storage now have meaningful compounds.
    // Only mark grid as seeded when ≥14 drivers have real tyre data,
    // so partial early frames don't block later complete ones.
    int seededDriverCount = 0;
    for (final entry in _driverStorage.values) {
      if (entry is Map && _stintsProvideMeaningfulCompound(entry['Stints'])) {
        seededDriverCount++;
      }
    }
    _timingAppDataGridSeeded = seededDriverCount >= 14;

    final _trus = _driverStorage['63']?['TyreCompound']?.toString();
    final _tper = _driverStorage['11']?['TyreCompound']?.toString();
    debugPrint('[TYRE-TRACE] After _initializeGridFromAppData: 63=$_trus, 11=$_tper, '
        'seededCount=$seededDriverCount, seeded=$_timingAppDataGridSeeded, storage=${_driverStorage.length} drivers');
    if (_trus != 'M' || _tper != 'H') {
      debugPrint('[TYRE-TRACE]   63 Stints: ${_driverStorage['63']?['Stints']}');
      debugPrint('[TYRE-TRACE]   11 Stints: ${_driverStorage['11']?['Stints']}');
    }

    _rebuildSortedOrderAndTrends();
    if (mounted) setState(() {});
  }

  double? _readNumericWeatherField(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    if (raw is Map) {
      final v = raw['Value'] ?? raw['value'];
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '');
    }
    return double.tryParse(raw.toString());
  }

  void _handleWeatherData(dynamic payload) {
    if (payload is! Map) return;
    final m = Map<String, dynamic>.from(payload as Map);
    final air = _readNumericWeatherField(m['AirTemp'] ?? m['airTemp']);
    final track = _readNumericWeatherField(m['TrackTemp'] ?? m['trackTemp']);
    final rain = m['Rainfall'] ?? m['Rain'] ?? m['IsRaining'] ?? m['rainfall'];
    final raining = rain == true ||
        rain == 1 ||
        (rain is String && (rain == '1' || rain.toLowerCase() == 'true'));
    if (mounted) {
      setState(() {
        if (air != null) _airTempC = air;
        if (track != null) _trackTempC = track;
        _rainActive = raining;
      });
    }
  }

  /// TrackStatus → Status: 1=Green, 2=Yellow, 4=SC, 5=Red, 6=VSC Deployed, 7=VSC Ending.
  void _handleTrackStatus(dynamic payload) {
    if (payload is! Map) return;
    final m = payload as Map;
    final raw = m['Status'] ?? m['status'];
    if (raw == null) return;
    final code = raw is int ? raw : int.tryParse(raw.toString());
    if (code == null) return;
    final msg = m['Message'] ?? m['message'];
    if (mounted) {
      setState(() {
        _trackStatusCode = code;
        _trackStatusMessage = msg?.toString() ?? _trackStatusLabelFromCode(code);
      });
    }
  }

  static String _trackStatusLabelFromCode(int code) {
    switch (code) {
      case 1: return 'GREEN';
      case 2: return 'YELLOW';
      case 4: return 'SAFETY CAR';
      case 5: return 'RED FLAG';
      case 6: return 'VSC DEPLOYED';
      case 7: return 'VSC ENDING';
      default: return 'STATUS $code';
    }
  }

  void _handleSessionInfo(dynamic payload) {
    if (payload is! Map) return;
    final m = Map<String, dynamic>.from(payload as Map);
    String pick(dynamic v) {
      if (v == null) return '';
      if (v is Map) return (v['Value'] ?? v['value'])?.toString() ?? v.toString();
      return v.toString();
    }
    final st = pick(m['SessionType'] ?? m['Type'] ?? m['SessionName']);
    final sp = pick(m['SessionPart'] ?? m['Part'] ?? m['MeetingSession']);

    // Session reset: when Status transitions to Active/Started, wipe purple maps.
    final statusRaw = pick(m['Status'] ?? m['SessionStatus']);
    final status = statusRaw.toLowerCase();
    if (status == 'active' || status == 'started') {
      _purpleSegmentOwner.clear();
      _purpleSegmentBestSec.clear();
      _sectorHighlights.clear();
    }

    if (mounted) {
      setState(() {
        if (st.isNotEmpty) _sessionTypeLabel = st;
        if (sp.isNotEmpty) _sessionPartLabel = sp;
      });
    }
  }

  /// RaceControl: Base64 (+ gzip) or JSON map; `Messages` may contain RACE STARTED / GREEN.
  void _handleRaceControl(dynamic payload) {
    dynamic json;
    if (payload is String) {
      final s = payload.trim();
      if (s.isEmpty) return;
      try {
        final bytes = base64Decode(s);
        List<int> raw;
        try {
          raw = GZipDecoder().decodeBytes(bytes);
        } catch (_) {
          raw = bytes;
        }
        json = jsonDecode(utf8.decode(raw));
      } catch (_) {
        try {
          json = jsonDecode(s);
        } catch (_) {
          return;
        }
      }
    } else if (payload is Map) {
      json = payload;
    } else {
      return;
    }

    DateTime? utc;
    var matched = false;
    void onGreen(DateTime? t) {
      matched = true;
      utc ??= t;
    }

    _scanRaceControlForGreenStart(json, onGreen);
    if (matched) {
      _scheduledRaceGreenUtc =
          utc?.toUtc() ?? _latestDataTimestamp?.toUtc() ?? DateTime.now().toUtc();
      _syncRacePhaseFromFrame(_latestDataTimestamp);
      if (mounted) setState(() {});
    }

    _scanRaceControlForTrackLimits(json);
  }

  /// Parses RaceControlMessages for "Track Limits" / "Penalty" tied to a car number.
  void _scanRaceControlForTrackLimits(dynamic node) {
    if (node is Map) {
      final msg = (node['Message'] ?? node['message'])?.toString() ?? '';
      final upper = msg.toUpperCase();
      if (upper.contains('TRACK LIMITS') || upper.contains('TRACK LIMIT') || upper.contains('PENALTY')) {
        final carRaw = node['RacingNumber'] ?? node['CarNumber'] ?? node['car'] ?? node['Car'];
        final carNum = carRaw is int ? carRaw : int.tryParse(carRaw?.toString() ?? '');
        if (carNum != null) {
          _trackLimitsByDriver[carNum] = (_trackLimitsByDriver[carNum] ?? 0) + 1;
          if (mounted) setState(() {});
        }
      }
      for (final v in node.values) {
        _scanRaceControlForTrackLimits(v);
      }
    } else if (node is List) {
      for (final item in node) {
        _scanRaceControlForTrackLimits(item);
      }
    }
  }

  /// Aligns phase with hub time: 15s pre-buffer (STARTING GRID) then [_onRaceStartedGreen].
  void _syncRacePhaseFromFrame(DateTime? frameUtc) {
    final g = _scheduledRaceGreenUtc;
    if (g == null) return;
    if (_raceTimingLiveActive) {
      _racePreStartBufferActive = false;
      return;
    }
    final t = (frameUtc ?? _latestDataTimestamp)?.toUtc();
    if (t == null) return;
    final preStart = g.toUtc().subtract(const Duration(seconds: 15));
    final gu = g.toUtc();

    if (t.isBefore(preStart)) {
      if (_racePreStartBufferActive) {
        _racePreStartBufferActive = false;
        if (mounted) setState(() {});
      }
      return;
    }

    if (t.isBefore(gu)) {
      final was = _racePreStartBufferActive;
      _racePreStartBufferActive = true;
      if (!was && _driverStorage.isNotEmpty) {
        _rebuildSortedOrderAndTrends();
      }
      if (!was && mounted) setState(() {});
      return;
    }

    _racePreStartBufferActive = false;
    _onRaceStartedGreen(gu);
  }

  void _onRaceStartedGreen(DateTime? messageUtc) {
    if (_raceTimingLiveActive) return;
    _racePreStartBufferActive = false;
    _raceTimingLiveActive = true;
    _raceStartedUtc = messageUtc ?? _latestDataTimestamp;
    _purpleSegmentOwner.clear();
    _purpleSegmentBestSec.clear();
    _bootstrapFullGridSilverstone2024();
    _resortDebounceTimer?.cancel();
    _rebuildSortedOrderAndTrends();
    if (mounted) setState(() {});
  }

  /// T-zero: ensure all 20 cars exist from static grid; timing/tyres only from stream (no fake gaps/tyres).
  void _bootstrapFullGridSilverstone2024() {
    for (var i = 0; i < _kSilverstone2024RaceGridOrder.length; i++) {
      final id = _kSilverstone2024RaceGridOrder[i];
      final num = int.parse(id);
      final merged = Map<String, dynamic>.from(_driverStorage[id] as Map? ?? {});
      merged['number'] = num;
      merged['name'] = _driverNames[id] ?? merged['name']?.toString() ?? 'Driver $id';
      merged['team'] = _silverstone2024Teams[num] ?? merged['team']?.toString() ?? '';
      merged['Position'] ??= i + 1;
      merged['NumberOfLaps'] ??= 0;
      // Lock grid position for gain/loss column (first write wins).
      if (!_gridPositions.containsKey(id)) {
        _gridPositions[id] = i + 1;
        merged['_GridPos'] = i + 1;
      }
      _syncTyreFromMergedDriverStints(merged);
      merged['TyreDataSource'] ??= 'UNKNOWN';
      _driverStorage[id] = merged;
    }
  }

  /// Live.txt / teststreams missen vaak `RaceControl` RACE STARTED+GREEN → dan bleef PRE-RACE
  /// actief en verscheen geen leaderboard. Start live timing zodra telemetrie duidelijk “race” is.
  void _maybeAutoStartRaceFromTelemetryAfterDataMerge() {
    if (_raceTimingLiveActive) return;
    if (_scheduledRaceGreenUtc != null) return;
    var maxLaps = 0;
    for (final id in _driverStorage.keys) {
      final d = _driverStorage[id] as Map?;
      final nl = _parseNumberOfLapsFieldOr(d?['NumberOfLaps'], 0);
      if (nl > maxLaps) maxLaps = nl;
    }
    if (maxLaps >= 1) {
      _onRaceStartedGreen(_latestDataTimestamp);
    }
  }

  /// Merges per-driver sector maps from `TimingStats` (same shape as TimingData lines).
  void _handleTimingStats(dynamic payload) {
    if (payload is! Map) return;
    final root = Map<String, dynamic>.from(payload as Map);
    Map<String, dynamic> lines;
    if (root['Lines'] is Map) {
      lines = Map<String, dynamic>.from(
        (root['Lines'] as Map).map((k, v) => MapEntry(k.toString(), v)),
      );
    } else {
      lines = {};
      for (final e in root.entries) {
        if (int.tryParse(e.key) != null && e.value is Map) {
          lines[e.key] = e.value;
        }
      }
    }
    if (lines.isEmpty) return;

    final highlights = Map<int, Map<int, SectorStatus>>.from(_sectorHighlights);
    final sectorUpdatedDrivers = <int>{};
    var stintIndexChangedAnyDriverStats = false;

    for (final entry in lines.entries) {
      final driverId = entry.key.toString();
      final line = entry.value;
      if (line is! Map) continue;
      final lineMap = Map<String, dynamic>.from(line as Map);
      final num = int.tryParse(driverId);
      final existingDriver = Map<String, dynamic>.from(_driverStorage[driverId] as Map? ?? {});
      final wasInPit = existingDriver['InPit'] == true;
      final prevStintIdx = _stintIndexFromStintsRaw(existingDriver['Stints']);
      final prevCompoundLetter = _tyreCompoundLetterFromStorage(existingDriver['TyreCompound']);

      final pc = lineMap['CurrentSector'] ??
          lineMap['CurrentSectorIndex'] ??
          lineMap['Sector'] ??
          lineMap['SectorCurrent'] ??
          lineMap['CurSector'] ??
          lineMap['SectorIdx'];
      if (pc != null) {
        existingDriver['ProgressCurrentSector'] = _normalizeSectorIndexForProgress(pc);
      }
      final csg = lineMap['CurrentSegment'] ??
          lineMap['CurrentSegmentIndex'] ??
          lineMap['SegmentIndex'] ??
          lineMap['MiniSector'];
      if (csg != null) {
        final g = csg is int ? csg : int.tryParse(csg.toString());
        if (g != null) existingDriver['ProgressCurrentSegment'] = g;
      }

      final nl = lineMap['NumberOfLaps'];
      if (nl != null) {
        final v = _parseNumberOfLapsField(nl);
        if (v != null) {
          final prevLaps = _parseNumberOfLapsField(existingDriver['NumberOfLaps']);
          if (prevLaps != null && v > prevLaps) {
            existingDriver['Sectors'] = <String, dynamic>{};
            if (num != null) {
              highlights[num] = {};
              _revokePurpleOwnershipForDriver(num);
            }
            _clearMicroSegmentHubMsForDriver(driverId);
          }
          existingDriver['NumberOfLaps'] = v;
        }
      }

      final sectors = (lineMap['Sectors'] ?? lineMap['BestSectors'] ?? lineMap['CurrentSectors']) as Map<String, dynamic>?;
      if (sectors != null && num != null) {
        highlights[num] ??= {};
        sectorUpdatedDrivers.add(num);
        final existingSectors = existingDriver['Sectors'] as Map?;
        final existingTimes = existingDriver['SectorTimes'] as Map?;
        final mergedSectors = Map<String, dynamic>.from(existingSectors ?? {});
        final mergedTimes = Map<String, String>.from(existingTimes ?? {});
        mergeF1SectorsPayloadInto(mergedSectors, sectors);
        for (final s in sectors.entries) {
          final sectorIdx = int.tryParse(s.key);
          if (sectorIdx == null || sectorIdx < 0 || sectorIdx > 2) continue;
          final mergedSector = mergedSectors[s.key.toString()];
          highlights[num]![sectorIdx] = _getSectorStatusFromLine(s.key, mergedSector ?? s.value);
          final sectorVal =
              mergedSector is Map ? (mergedSector['Value'] ?? mergedSector['value'])?.toString() : null;
          if (sectorVal != null && sectorVal.isNotEmpty) mergedTimes[s.key.toString()] = sectorVal;
        }
        existingDriver['Sectors'] = mergedSectors;
        existingDriver['SectorTimes'] = mergedTimes;
      }

      final tyrePatch = <String, dynamic>{};
      if (lineMap['InPit'] != null) tyrePatch['InPit'] = lineMap['InPit'] == true;
      _extractTyreData(lineMap, tyrePatch);
      _deepMerge(existingDriver, tyrePatch);

      _driverStorage[driverId] = existingDriver;
      _syncMicroSegmentCompletionTimestamps(driverId, existingDriver);
      final incomingLineHadStintsStats =
          lineMap.containsKey('Stints') && lineMap['Stints'] != null;
      if (_finalizeTyreTelemetryAfterLineMerge(
            driverId: driverId,
            existingDriver: existingDriver,
            isGridStintsPacket: false,
            incomingLineHadStints: incomingLineHadStintsStats,
            prevStintIdx: prevStintIdx,
            prevCompoundLetter: prevCompoundLetter,
            wasInPit: wasInPit,
          )) {
        stintIndexChangedAnyDriverStats = true;
      }
    }

    if (stintIndexChangedAnyDriverStats && mounted) setState(() {});

    _enforceSinglePurplePerSector(highlights, sectorUpdatedDrivers);
    final demoted1 = _enforceSinglePurplePerSegment(sectorUpdatedDrivers);
    if (demoted1.isNotEmpty) {
      _refreshHighlightsAfterSegmentEnforcement(highlights, {...sectorUpdatedDrivers, ...demoted1});
    }
    _sectorHighlights = highlights;
    _updateSectorBestFromHighlights();
    _syncRacePhaseFromFrame(_latestDataTimestamp);
    if (!_raceTimingLiveActive) {
      if (_scheduledRaceGreenUtc == null) {
        _maybeAutoStartRaceFromTelemetryAfterDataMerge();
      }
    }
    final showLeaderboard = _raceTimingLiveActive || _racePreStartBufferActive;
    if (!showLeaderboard) {
      if (_driverStorage.isNotEmpty) {
        _rebuildSortedOrderAndTrends();
      }
      if (mounted) setState(() {});
      return;
    }
    _scheduleDebouncedResort(payloadMap: root);
  }

  /// Handles TimingData payload: merges Lines into _driverStorage, re-sorts, setState.
  ///
  /// Accepts a **Base64 (+gzip) string** (grid-state / embedded TimingData) or a JSON map.
  ///
  /// **INT/GAP:** P1 = last lap; P2+ = `+|Gap−Gap_above|`. **Tyres:** [InPit] true→false triggers
  /// [_onPitExitTyreRefresh] (new stint compound + age reset). Partial lines without `Stints` keep prior tyres.
  void _handleTimingUpdate(dynamic payload, {bool skipRacePhaseSync = false}) {
    if (payload is String) {
      final dec = decodeTimingDataFromBase64String(payload);
      if (dec != null) {
        _handleTimingUpdate(dec, skipRacePhaseSync: skipRacePhaseSync);
      }
      return;
    }
    if (payload is! Map) {
      return;
    }
    final payloadMap = Map<String, dynamic>.from(payload as Map);
    final linesRaw = payloadMap['Lines'];
    final lines = linesRaw is Map
        ? Map<String, dynamic>.from(
            (linesRaw as Map).map((k, v) => MapEntry(k.toString(), v)))
        : null;
    if (lines == null || lines.isEmpty) {
      return;
    }

    // Session clock from TimingData root (live.txt / SignalR) — all Lines in this payload share it.
    final frameSessionMs = _sessionTimeMsFromTimingPayload(payloadMap);

    final highlights = Map<int, Map<int, SectorStatus>>.from(_sectorHighlights);
    final sectorUpdatedDrivers2 = <int>{};
    final lapTimes = <String>[];
    final packetHasStintsKey = _timingLinesPayloadHasStintsKey(lines);
    final isGridStintsPacket = packetHasStintsKey && !_initialStintsTimingDataConsumed;
    var stintIndexChangedAnyDriver = false;

    for (final entry in lines.entries) {
      final driverId = entry.key.toString();
      final line = entry.value;
      if (line is! Map) continue;

      final lineMap = Map<String, dynamic>.from(line);
      final num = int.tryParse(driverId);
      final data = <String, dynamic>{};

      // Ordering: laps*1000 + sector*100 + segment (_progressScore); not official Position key.

      // Lap time: LastLapTime is a nested Object {"Value": "1:31.418", "OverallFastest": true, ...} – NOT a string
      // Priority: LastLapTime['Value'], Fallback: BestLapTime['Value']
      String? lastLapStr;
      bool overallFastest = false;
      bool personalFastest = false;
      final lastLapRaw = lineMap['LastLapTime'];
      if (lastLapRaw != null && lastLapRaw is Map) {
        final val = lastLapRaw['Value'] ?? lastLapRaw['value'];
        lastLapStr = val?.toString();
        overallFastest = lastLapRaw['OverallFastest'] == true || lastLapRaw['overallFastest'] == true;
        personalFastest = lastLapRaw['PersonalFastest'] == true || lastLapRaw['personalFastest'] == true;
      }
      if ((lastLapStr == null || lastLapStr.isEmpty) && lineMap['BestLapTime'] != null) {
        final bestRaw = lineMap['BestLapTime'];
        if (bestRaw is Map) {
          final val = bestRaw['Value'] ?? bestRaw['value'];
          lastLapStr = val?.toString();
          overallFastest = overallFastest || (bestRaw['OverallFastest'] == true || bestRaw['overallFastest'] == true);
          personalFastest = personalFastest || (bestRaw['PersonalFastest'] == true || bestRaw['personalFastest'] == true);
        }
      }
      if (lastLapStr != null && lastLapStr.isNotEmpty) {
        data['LastLapTime'] = lastLapStr;
        data['LastLapOverallFastest'] = overallFastest;
        data['LastLapPersonalFastest'] = personalFastest;
        lapTimes.add(lastLapStr);
      }
      // Persistence: never overwrite LastLapTime with empty – keep existing if new value is empty
      final existing = _driverStorage[driverId] as Map<String, dynamic>?;
      if (existing != null &&
          (data['LastLapTime'] == null || data['LastLapTime'].toString().isEmpty) &&
          (existing['LastLapTime']?.toString().isNotEmpty ?? false)) {
        data['LastLapTime'] = existing['LastLapTime'];
        data['LastLapOverallFastest'] ??= existing['LastLapOverallFastest'];
        data['LastLapPersonalFastest'] ??= existing['LastLapPersonalFastest'];
      }

      // Gaps: often strings ("+1.234", "LAP") or {Value: "..."}. Support both.
      final gapRaw = lineMap['GapToLeader'] ?? lineMap['Gap'];
      if (gapRaw != null) {
        final gStr = gapRaw is Map ? (gapRaw['Value'] ?? gapRaw['value'])?.toString() ?? gapRaw.toString() : gapRaw.toString();
        if (gStr.isNotEmpty) data['GapToLeader'] = gStr;
      }
      final intervalRaw = lineMap['IntervalToPrimary'] ?? lineMap['Interval'] ?? lineMap['IntervalToPositionAhead'];
      if (intervalRaw != null) {
        final iStr = intervalRaw is Map ? (intervalRaw['Value'] ?? intervalRaw['value'])?.toString() ?? intervalRaw.toString() : intervalRaw.toString();
        if (iStr.isNotEmpty) data['IntervalToPrimary'] = iStr;
      }
      // Persistence: keep existing gaps if new update has none
      if (existing != null) {
        if (data['GapToLeader'] == null && (existing['GapToLeader']?.toString().isNotEmpty ?? false)) {
          data['GapToLeader'] = existing['GapToLeader'];
        }
        if (data['IntervalToPrimary'] == null && (existing['IntervalToPrimary']?.toString().isNotEmpty ?? false)) {
          data['IntervalToPrimary'] = existing['IntervalToPrimary'];
        }
      }

      // Gap trend: compare numeric gap to previous value.
      final gapStr = data['GapToLeader']?.toString() ?? '';
      final gapNum = _parseGapToSeconds(gapStr);
      if (gapNum != null) {
        final prev = _previousGapValues[driverId];
        if (prev != null) {
          const epsilon = 0.05;
          if (gapNum > prev + epsilon) {
            _gapTrendByDriver[driverId] = 1;
          } else if (gapNum < prev - epsilon) {
            _gapTrendByDriver[driverId] = -1;
          } else {
            _gapTrendByDriver[driverId] = 0;
          }
        }
        _previousGapValues[driverId] = gapNum;
      }

      // InPit, Stopped (crashed/retired)
      final inPit = lineMap['InPit'];
      if (inPit != null) data['InPit'] = inPit == true;
      final stopped = lineMap['Stopped'];
      if (stopped != null) data['Stopped'] = stopped == true;
      final retired = lineMap['Retired'];
      if (retired != null) data['Retired'] = retired == true;
      final nl = lineMap['NumberOfLaps'];
      if (nl != null) {
        final v = _parseNumberOfLapsField(nl);
        if (v != null) data['NumberOfLaps'] = v;
      }

      final posRaw = lineMap['Position'] ?? lineMap['GridPos'] ?? lineMap['GridPosition'];
      if (posRaw != null) {
        final pv = posRaw is int ? posRaw : int.tryParse(posRaw.toString());
        if (pv != null) data['Position'] = pv;
      }
      // First time we see GridPos for this driver → lock it for gain/loss.
      final gridPosRaw = lineMap['GridPos'] ?? lineMap['GridPosition'];
      if (gridPosRaw != null && !_gridPositions.containsKey(driverId)) {
        final gp = gridPosRaw is int ? gridPosRaw : int.tryParse(gridPosRaw.toString());
        if (gp != null) {
          _gridPositions[driverId] = gp;
          data['_GridPos'] = gp;
        }
      }

      // Tyres: TimingData → Lines → [driverId] → TyreCompound / Stints (List or Map).
      _extractTyreDataFromTimingLine(lineMap, data);

      // Capture `New` flag from Stints (fresh/used tyre indicator).
      if (lineMap.containsKey('Stints')) {
        final stint = _latestStintEntryFromStintsRaw(lineMap['Stints']);
        if (stint != null) {
          final isNew = stint['New'] ?? stint['new'];
          if (isNew is bool) {
            data['TyreNew'] = isNew;
          } else if (isNew != null) {
            data['TyreNew'] = isNew.toString().toLowerCase() == 'true';
          }
        }
      }

      final pitStops = lineMap['NumberOfPitStops'] ?? lineMap['NumberOfPitstops'] ?? lineMap['PitStops'];
      if (pitStops != null) {
        final p = pitStops is Map ? (pitStops['Value'] ?? pitStops['value']) : pitStops;
        final n = p is int ? p : int.tryParse(p.toString());
        if (n != null) data['NumberOfPitStops'] = n;
      }
      final pitDurRaw = lineMap['LastPitStopDuration'] ?? lineMap['LastPitStopTime'];
      if (pitDurRaw != null) {
        final v = pitDurRaw is Map
            ? (pitDurRaw['Value'] ?? pitDurRaw['value'])?.toString()
            : pitDurRaw.toString();
        if (v != null && v.isNotEmpty) data['LastPitStopDuration'] = v;
      }

      if (num != null) {
        data['number'] = num;
        data['name'] = _driverNames[driverId] ?? 'Driver $driverId';
        data['team'] = _silverstone2024Teams[num] ?? '';
      }

      // Track position for sequential mini-sectors (TimingStats may also update).
      final pcRaw = lineMap['CurrentSector'] ??
          lineMap['CurrentSectorIndex'] ??
          lineMap['Sector'] ??
          lineMap['SectorCurrent'] ??
          lineMap['CurSector'] ??
          lineMap['SectorIdx'];
      if (pcRaw != null) {
        data['ProgressCurrentSector'] = _normalizeSectorIndexForProgress(pcRaw);
      }
      if (lineMap['CurrentSectorIndex'] != null) {
        data['CurrentSectorIndex'] = lineMap['CurrentSectorIndex'];
      }
      final csg = lineMap['CurrentSegment'] ??
          lineMap['CurrentSegmentIndex'] ??
          lineMap['SegmentIndex'] ??
          lineMap['MiniSector'];
      if (csg != null) {
        final g = csg is int ? csg : int.tryParse(csg.toString());
        if (g != null) data['ProgressCurrentSegment'] = g;
      }

      // Deep merge: partial updates (e.g. Sector 2 only) must not delete Sector 1, Tyre, Gap, etc.
      final existingDriver = Map<String, dynamic>.from(_driverStorage[driverId] as Map<String, dynamic>? ?? {});
      final wasInPit = existingDriver['InPit'] == true;
      final prevStintIdx = _stintIndexFromStintsRaw(existingDriver['Stints']);
      final prevCompoundLetter = _tyreCompoundLetterFromStorage(existingDriver['TyreCompound']);
      // New lap → clear sector mini-state (fresh lap progression).
      if (data['NumberOfLaps'] != null) {
        final newLaps = _parseNumberOfLapsField(data['NumberOfLaps']);
        final prevLaps = _parseNumberOfLapsField(existingDriver['NumberOfLaps']);
        if (newLaps != null && prevLaps != null && newLaps > prevLaps) {
          existingDriver['Sectors'] = <String, dynamic>{};
          if (num != null) {
            highlights[num] = {};
            _revokePurpleOwnershipForDriver(num);
          }
          _clearMicroSegmentHubMsForDriver(driverId);
        }
      }
      _deepMerge(existingDriver, data);
      _driverStorage[driverId] = existingDriver;

      // Sectors: deep-merge sector objects and per-key Segments so partial TimingData/TimingStats rows don't wipe micros.
      final sectors = (lineMap['Sectors'] ?? lineMap['BestSectors'] ?? lineMap['CurrentSectors']) as Map<String, dynamic>?;
      if (sectors != null && num != null) {
        highlights[num] ??= {};
        sectorUpdatedDrivers2.add(num);
        final existingSectors = existingDriver['Sectors'] as Map?;
        final existingTimes = existingDriver['SectorTimes'] as Map?;
        final mergedSectors = Map<String, dynamic>.from(existingSectors ?? {});
        final mergedTimes = Map<String, String>.from(existingTimes ?? {});
        mergeF1SectorsPayloadInto(mergedSectors, sectors);
        for (final s in sectors.entries) {
          final sectorIdx = int.tryParse(s.key);
          if (sectorIdx == null || sectorIdx < 0 || sectorIdx > 2) continue;
          final mergedSector = mergedSectors[s.key.toString()];
          highlights[num]![sectorIdx] = _getSectorStatusFromLine(s.key, mergedSector ?? s.value);
          final sectorVal =
              mergedSector is Map ? (mergedSector['Value'] ?? mergedSector['value'])?.toString() : null;
          if (sectorVal != null && sectorVal.isNotEmpty) mergedTimes[s.key.toString()] = sectorVal;
        }
        existingDriver['Sectors'] = mergedSectors;
        existingDriver['SectorTimes'] = mergedTimes;
      }

      // Speeds (I1, I2, FL, ST) – deep merge so partial updates keep other traps
      final speeds = lineMap['Speeds'];
      if (speeds is Map) {
        final mergedSp = Map<String, dynamic>.from(existingDriver['Speeds'] as Map? ?? {});
        _deepMerge(
          mergedSp,
          Map<String, dynamic>.from(
            speeds.map((k, v) => MapEntry(k.toString(), v)),
          ),
        );
        existingDriver['Speeds'] = mergedSp;
      }

      _syncMicroSegmentCompletionTimestamps(driverId, existingDriver);

      if (frameSessionMs != null) {
        existingDriver['_timingFrameSessionMs'] = frameSessionMs;
      } else if (_lastTimingHubTsMs != null) {
        existingDriver['_timingFrameSessionMs'] = _lastTimingHubTsMs;
      }
      final incomingLineHadStints =
          lineMap.containsKey('Stints') && lineMap['Stints'] != null;
      if (_finalizeTyreTelemetryAfterLineMerge(
            driverId: driverId,
            existingDriver: existingDriver,
            isGridStintsPacket: isGridStintsPacket,
            incomingLineHadStints: incomingLineHadStints,
            prevStintIdx: prevStintIdx,
            prevCompoundLetter: prevCompoundLetter,
            wasInPit: wasInPit,
          )) {
        stintIndexChangedAnyDriver = true;
      }

      // Pit entry/exit transitions → pit timer + out-lap flag.
      final nowInPit = existingDriver['InPit'] == true;
      if (!wasInPit && nowInPit) {
        _pitEntryTimestamps[driverId] = _latestDataTimestamp ?? DateTime.now();
        _outLapFlags[driverId] = false;
      } else if (wasInPit && !nowInPit) {
        _pitEntryTimestamps.remove(driverId);
        _outLapFlags[driverId] = true;
      }
      // Clear out-lap flag when the driver completes a full lap after pit exit.
      if (_outLapFlags[driverId] == true && !nowInPit) {
        final newLaps = _parseNumberOfLapsField(existingDriver['NumberOfLaps']);
        final prevLaps = _parseNumberOfLapsField(data['NumberOfLaps'] ?? existingDriver['NumberOfLaps']);
        if (newLaps != null && prevLaps != null && newLaps > prevLaps) {
          _outLapFlags[driverId] = false;
        }
      }
    }

    if (packetHasStintsKey) {
      _initialStintsTimingDataConsumed = true;
    }
    if (stintIndexChangedAnyDriver && mounted) setState(() {});

    _enforceSinglePurplePerSector(highlights, sectorUpdatedDrivers2);
    final demoted2 = _enforceSinglePurplePerSegment(sectorUpdatedDrivers2);
    if (demoted2.isNotEmpty) {
      _refreshHighlightsAfterSegmentEnforcement(highlights, {...sectorUpdatedDrivers2, ...demoted2});
    }
    _sectorHighlights = highlights;
    _updateSectorBestFromHighlights();

    // Fastest lap of session: smallest lap time (parse "M:SS.mmm" or "SS.mmm")
    if (lapTimes.isNotEmpty) {
      String? best;
      for (final t in lapTimes) {
        if (best == null || _lapTimeCompare(t, best) < 0) best = t;
      }
      _fastestLapTime = best;
    }

    // Ensure all 20 Silverstone drivers exist as soon as we have any data flowing.
    if (_driverStorage.length < 20) {
      _bootstrapFullGridSilverstone2024();
    }

    if (!skipRacePhaseSync) {
      _syncRacePhaseFromFrame(_latestDataTimestamp);
    }
    if (!_raceTimingLiveActive) {
      if (_scheduledRaceGreenUtc == null) {
        _maybeAutoStartRaceFromTelemetryAfterDataMerge();
      }
    }
    final showLeaderboard = _raceTimingLiveActive || _racePreStartBufferActive;
    if (!showLeaderboard) {
      if (_driverStorage.isNotEmpty) {
        _rebuildSortedOrderAndTrends();
      }
      if (mounted) setState(() {});
      return;
    }

    _scheduleDebouncedResort(payloadMap: payloadMap);
  }

  /// Parses gap strings like "+1.234", "1:12.456", "LAP" → seconds or null.
  static double? _parseGapToSeconds(String raw) {
    final s = raw.replaceAll('+', '').trim();
    if (s.isEmpty || s == '–' || s == '-') return null;
    if (s.contains(':')) {
      final parts = s.split(':');
      if (parts.length == 2) {
        final m = double.tryParse(parts[0]);
        final sec = double.tryParse(parts[1]);
        if (m != null && sec != null) return m * 60 + sec;
      }
    }
    return double.tryParse(s);
  }

  /// Parses "M:SS.mmm" or "SS.mmm" to milliseconds; returns negative if a < b, 0 if equal, positive if a > b.
  static int _lapTimeCompare(String a, String b) {
    int ms(String s) {
      final parts = s.split(':');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0].trim()) ?? 0;
        final secParts = parts[1].split('.');
        final sec = int.tryParse(secParts[0].trim()) ?? 0;
        final msPart = secParts.length > 1 ? int.tryParse(secParts[1].trim()) ?? 0 : 0;
        return (m * 60 + sec) * 1000 + msPart;
      }
      return int.tryParse(s.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    }
    return ms(a).compareTo(ms(b));
  }

  /// Derives sector status from F1 API segment data.
  /// 2048 = Purple (overall fastest), 2044 = Green (personal best), else = yellow (slower).
  static SectorStatus _getSectorStatusFromLine(dynamic sectorKey, dynamic sectorValue) {
    final segs = sectorValue is Map ? (sectorValue as Map)['Segments'] : null;
    if (segs is! Map) return SectorStatus.yellow;
    SectorStatus status = SectorStatus.yellow;
    for (final seg in segs.values) {
      if (seg is Map) {
        final st = seg['Status'];
        final stInt = st is int ? st : int.tryParse(st?.toString() ?? '');
        final ob = seg['OverallFastest'] == true || seg['overallFastest'] == true;
        final pb = seg['PersonalFastest'] == true || seg['personalFastest'] == true;
        if (stInt == 2048 || stInt == 2064 || stInt == 204 || ob) return SectorStatus.purple;
        if (stInt == 2044 || stInt == 201 || pb) status = SectorStatus.green;
      }
    }
    return status;
  }

  /// After a batch of sector updates, ensures at most one driver holds purple
  /// per sector (0, 1, 2). Drivers in [justUpdatedDrivers] that earned purple
  /// take precedence; any previous purple holder for the same sector is
  /// degraded to green. If multiple drivers in the batch both earned purple,
  /// the last one processed (iteration order) wins.
  static void _enforceSinglePurplePerSector(
    Map<int, Map<int, SectorStatus>> highlights,
    Set<int> justUpdatedDrivers,
  ) {
    for (int sectorIdx = 0; sectorIdx <= 2; sectorIdx++) {
      int? newestPurple;
      for (final driverNum in justUpdatedDrivers) {
        if (highlights[driverNum]?[sectorIdx] == SectorStatus.purple) {
          newestPurple = driverNum;
        }
      }
      if (newestPurple == null) continue;
      for (final entry in highlights.entries) {
        if (entry.key != newestPurple &&
            entry.value[sectorIdx] == SectorStatus.purple) {
          entry.value[sectorIdx] = SectorStatus.green;
        }
      }
    }
  }

  /// Re-derive sector-level highlights from stored segment data after segment
  /// enforcement may have downgraded some segments.
  void _refreshHighlightsAfterSegmentEnforcement(
    Map<int, Map<int, SectorStatus>> highlights,
    Set<int> affectedDriverNums,
  ) {
    for (final driverNum in affectedDriverNums) {
      final driverId = driverNum.toString();
      final d = _driverStorage[driverId];
      if (d is! Map) continue;
      final sectors = d['Sectors'];
      if (sectors is! Map) continue;
      for (final se in (sectors as Map).entries) {
        final sectorIdx = int.tryParse(se.key.toString());
        if (sectorIdx == null || sectorIdx < 0 || sectorIdx > 2) continue;
        highlights[driverNum] ??= {};
        highlights[driverNum]![sectorIdx] =
            _getSectorStatusFromLine(se.key, se.value);
      }
    }
  }

  /// Revokes all purple segment ownerships held by [driverNum].
  /// Called when a driver starts a new lap — stale purples from previous laps
  /// must not persist (Freshness Rule).
  void _revokePurpleOwnershipForDriver(int driverNum) {
    _purpleSegmentOwner.removeWhere((_, owner) => owner == driverNum);
  }

  /// Parses a segment's time value to seconds (supports "25.123" or "1:25.123").
  static double? _parseSegmentTimeSec(Map seg) {
    final raw = seg['Value'] ?? seg['value'] ?? seg['Duration'] ?? seg['duration'];
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length == 2) {
      final min = double.tryParse(parts[0]);
      final sec = double.tryParse(parts[1]);
      if (min != null && sec != null) return min * 60 + sec;
    }
    return double.tryParse(s);
  }

  /// Returns true if a segment map represents an overall-best (purple) status.
  static bool _isSegmentPurple(Map seg) {
    final stRaw = seg['Status'];
    final st = stRaw is int ? stRaw : int.tryParse(stRaw?.toString() ?? '');
    final ob = seg['OverallFastest'] == true || seg['overallFastest'] == true;
    return ob || st == 2064 || st == 2048 || st == 204;
  }

  /// Downgrades a segment in [_driverStorage] from purple to personal-best (green).
  void _downgradeStoredSegment(String driverId, String sectorKey, String segKey) {
    final d = _driverStorage[driverId];
    if (d is! Map) return;
    final sectors = d['Sectors'];
    if (sectors is! Map) return;
    final sector = sectors[sectorKey];
    if (sector is! Map) return;
    final segments = sector['Segments'];
    if (segments is! Map) return;
    final seg = segments[segKey];
    if (seg is! Map) return;
    seg['OverallFastest'] = false;
    seg['overallFastest'] = false;
    seg['PersonalFastest'] = true;
    seg['personalFastest'] = true;
    seg['Status'] = 2049;
  }

  /// Global Purple Validator at the micro-segment level (Restrictive Ownership).
  ///
  /// For each driver in [updatedDriverNums], scans their stored Segments.
  /// A purple segment is only accepted if:
  ///  1. Its duration is strictly less than the session best for that slot, OR
  ///  2. No session best exists yet, OR
  ///  3. The feed explicitly marks it `OverallFastest` (duration may be absent).
  ///
  /// When accepted, the previous owner is downgraded in storage.
  /// When rejected (stale echo / slower time), this driver's segment is
  /// downgraded to personal-best (green).
  ///
  /// Returns the set of driver numbers whose stored segments were demoted.
  Set<int> _enforceSinglePurplePerSegment(Set<int> updatedDriverNums) {
    final demotedDrivers = <int>{};
    for (final driverNum in updatedDriverNums) {
      final driverId = driverNum.toString();
      final driverData = _driverStorage[driverId];
      if (driverData is! Map) continue;

      final sectorsRoot = driverData['Sectors'];
      if (sectorsRoot is! Map) continue;

      for (final sEntry in (sectorsRoot as Map).entries) {
        final sectorKey = sEntry.key.toString();
        final sectorMap = sEntry.value;
        if (sectorMap is! Map) continue;

        final segments = sectorMap['Segments'];
        if (segments is! Map) continue;

        for (final segEntry in (segments as Map).entries) {
          final segKey = segEntry.key.toString();
          final seg = segEntry.value;
          if (seg is! Map) continue;
          if (!_isSegmentPurple(seg)) continue;

          final ownerKey = '${sectorKey}_$segKey';
          final currentOwner = _purpleSegmentOwner[ownerKey];

          if (currentOwner == driverNum) continue;

          final timeSec = _parseSegmentTimeSec(seg);
          final storedBest = _purpleSegmentBestSec[ownerKey];
          final explicitOB =
              seg['OverallFastest'] == true || seg['overallFastest'] == true;

          // Accept purple if: first ever, strictly faster, or feed says OB.
          final accepted = storedBest == null ||
              (timeSec != null && timeSec < storedBest) ||
              explicitOB;

          if (!accepted) {
            // Stale echo — downgrade THIS driver's segment
            _downgradeSegmentInMap(seg);
            demotedDrivers.add(driverNum);
            continue;
          }

          // Update session best time
          if (timeSec != null &&
              (storedBest == null || timeSec < storedBest)) {
            _purpleSegmentBestSec[ownerKey] = timeSec;
          }

          // Downgrade the old owner
          if (currentOwner != null) {
            _downgradeStoredSegment(
              currentOwner.toString(), sectorKey, segKey,
            );
            demotedDrivers.add(currentOwner);
          }
          _purpleSegmentOwner[ownerKey] = driverNum;
        }
      }
    }
    return demotedDrivers;
  }

  /// In-place downgrade of a segment map (no storage lookup needed).
  static void _downgradeSegmentInMap(Map seg) {
    seg['OverallFastest'] = false;
    seg['overallFastest'] = false;
    seg['PersonalFastest'] = true;
    seg['personalFastest'] = true;
    seg['Status'] = 2049;
  }

  /// Extracts lap time string from Position.z or TimingData entry. Supports LastLapTime/BestLapTime as string or {Value: "..."}.
  static String? _extractLapTimeFromEntry(Map<String, dynamic> e) {
    final last = e['LastLapTime'] ?? e['BestLapTime'];
    if (last == null) return null;
    if (last is Map) {
      final v = last['Value'] ?? last['value'];
      return v?.toString();
    }
    final s = last.toString();
    return s.isEmpty ? null : s;
  }

  /// Extracts tyre compound + `Stints` from one TimingData line (no default M; age from [calculateTyreAge] after merge).
  void _extractTyreDataFromTimingLine(Map<String, dynamic> lineMap, Map<String, dynamic> data) {
    _extractTyreData(lineMap, data);
  }

  /// **Stints-only:** compound letter comes from the **last** stint entry, never from a bare `TyreCompound` line field.
  /// Also captures `New` (fresh/used) boolean from the stint.
  void _extractTyreData(Map<String, dynamic> lineMap, Map<String, dynamic> data) {
    if (!lineMap.containsKey('Stints')) return;
    data['Stints'] = lineMap['Stints'];
    final stint = _latestStintEntryFromStintsRaw(lineMap['Stints']);
    if (stint != null) {
      _applyStintTyreFieldsToTarget(stint, data);
      final isNew = stint['New'] ?? stint['new'];
      if (isNew is bool) {
        data['TyreNew'] = isNew;
      } else if (isNew != null) {
        data['TyreNew'] = isNew.toString().toLowerCase() == 'true';
      }
    } else {
      data.remove('TyreCompound');
    }
  }

  /// Pit exit uses the same stint-based sync as normal merges.
  void _onPitExitTyreRefresh(String driverId, Map<String, dynamic> driver) {
    _syncTyreFromMergedDriverStints(driver);
  }

  /// After merge: compound + age **only** from latest stint; no stint / no mappable compound → `?` + UNKNOWN upstream.
  void _syncTyreFromMergedDriverStints(Map<String, dynamic> driver) {
    final stint = _latestStintEntryFromStintsRaw(driver['Stints']);
    final cur = _parseNumberOfLapsFieldOr(driver['NumberOfLaps'], 0);
    if (stint == null) {
      driver.remove('TyreCompound');
      driver.remove('TyreAge');
      driver.remove('_StintStartLap');
      return;
    }
    _applyStintTyreFieldsToTarget(stint, driver);
    final letter = _tyreCompoundLetterFromStorage(driver['TyreCompound']);
    if (letter == null) {
      driver.remove('TyreCompound');
      driver.remove('TyreAge');
      driver.remove('_StintStartLap');
      return;
    }
    final sl = parseStintStartLapFromStint(stint);
    final start = sl ??
        (driver['_StintStartLap'] is int
            ? driver['_StintStartLap'] as int
            : int.tryParse(driver['_StintStartLap']?.toString() ?? '')) ??
        cur;
    driver['_StintStartLap'] = start;
    driver['TyreAge'] = calculateTyreAge(start, cur);
  }

  bool _finalizeTyreTelemetryAfterLineMerge({
    required String driverId,
    required Map<String, dynamic> existingDriver,
    required bool isGridStintsPacket,
    required bool incomingLineHadStints,
    required int? prevStintIdx,
    required String? prevCompoundLetter,
    required bool wasInPit,
  }) {
    final nowInPit = existingDriver['InPit'] == true;
    if (wasInPit && !nowInPit) {
      _onPitExitTyreRefresh(driverId, existingDriver);
    } else {
      _syncTyreFromMergedDriverStints(existingDriver);
    }
    final newIdx = _stintIndexFromStintsRaw(existingDriver['Stints']);
    final newLetter = _tyreCompoundLetterFromStorage(existingDriver['TyreCompound']);
    _assignTyreDataSourceForDriver(
      driver: existingDriver,
      isGridStintsPacket: isGridStintsPacket,
      incomingLineHadStints: incomingLineHadStints,
      prevStintIdx: prevStintIdx,
      prevCompoundLetter: prevCompoundLetter,
      newStintIdx: newIdx,
      newCompoundLetter: newLetter,
    );
    return prevStintIdx != null && newIdx != null && prevStintIdx != newIdx;
  }

  void _assignTyreDataSourceForDriver({
    required Map<String, dynamic> driver,
    required bool isGridStintsPacket,
    required bool incomingLineHadStints,
    required int? prevStintIdx,
    required String? prevCompoundLetter,
    required int? newStintIdx,
    required String? newCompoundLetter,
  }) {
    final existingSource = driver['TyreDataSource']?.toString();
    final idxChanged = prevStintIdx != null && newStintIdx != null && prevStintIdx != newStintIdx;
    final letterChanged = prevCompoundLetter != newCompoundLetter;

    if (newCompoundLetter == null) {
      if (existingSource == 'GRID INITIALIZED') return;
      driver['TyreDataSource'] = 'UNKNOWN';
      return;
    }

    if (existingSource == 'GRID INITIALIZED') {
      if (idxChanged || letterChanged) {
        driver['TyreDataSource'] = 'LIVE UPDATE';
      }
      return;
    }

    if (isGridStintsPacket && incomingLineHadStints && prevCompoundLetter == null) {
      driver['TyreDataSource'] = 'INITIAL LOAD';
      return;
    }

    if (idxChanged || letterChanged || (prevCompoundLetter == null && !isGridStintsPacket)) {
      driver['TyreDataSource'] = 'LIVE UPDATE';
    }
  }

  /// After TimingData/TimingStats merges: wait [_kResortDebounceMs] so staggered lines
  /// for the same hub frame merge, then sort by [_progressScore] only.
  void _scheduleDebouncedResort({Map<String, dynamic>? payloadMap}) {
    if (!_raceTimingLiveActive && !_racePreStartBufferActive) return;
    if (payloadMap != null) {
      final anchor = _sessionTimeMsFromTimingPayload(payloadMap);
      if (anchor != null) _lastSortSessionAnchorMs = anchor;
    }
    if (_driverStorage.isEmpty) return;

    if (_sortedDriverIds.isEmpty) {
      _rebuildSortedOrderAndTrends();
    }

    _resortDebounceTimer?.cancel();
    _resortDebounceTimer = Timer(Duration(milliseconds: _kResortDebounceMs), () {
      if (!mounted) return;
      _rebuildSortedOrderAndTrends();
      setState(() {});
    });
  }

  /// Starting grid order during 15s pre-buffer (Position / GridPos / static grid).
  void _rebuildSortedOrderByGridPosition() {
    final ids = _driverStorage.keys.toList();
    int cmp(String a, String b) {
      final da = Map<String, dynamic>.from(_driverStorage[a] as Map? ?? {});
      final db = Map<String, dynamic>.from(_driverStorage[b] as Map? ?? {});
      final pa = _gridPositionOrdinal(da);
      final pb = _gridPositionOrdinal(db);
      if (pa != pb) return pa.compareTo(pb);
      return a.compareTo(b);
    }
    ids.sort(cmp);
    final nextTrend = <String, int>{};
    for (var i = 0; i < ids.length; i++) {
      final id = ids[i];
      final prev = _previousListIndexByDriverId[id];
      if (prev != null && prev != i) {
        nextTrend[id] = i < prev ? 1 : -1;
      } else {
        nextTrend[id] = 0;
      }
    }
    _positionTrendByDriverId = nextTrend;
    _previousListIndexByDriverId = {for (var j = 0; j < ids.length; j++) ids[j]: j};
    _sortedDriverIds = ids;
  }

  /// Sort by [_progressScore] only (highest = P1). No gap tie-break (avoids wrong leader on Lap 2).
  void _rebuildSortedOrderAndTrends() {
    if (_racePreStartBufferActive) {
      _rebuildSortedOrderByGridPosition();
      return;
    }
    final ids = _driverStorage.keys.toList();
    int cmp(String a, String b) {
      final da = Map<String, dynamic>.from(_driverStorage[a] as Map? ?? {});
      final db = Map<String, dynamic>.from(_driverStorage[b] as Map? ?? {});
      final outA = _liveDriverIsRetired(da);
      final outB = _liveDriverIsRetired(db);
      if (outA != outB) return outA ? 1 : -1;
      final sa = _progressScore(da);
      final sb = _progressScore(db);
      if (sa != sb) return sb.compareTo(sa);
      return a.compareTo(b);
    }
    ids.sort(cmp);
    final nextTrend = <String, int>{};
    for (var i = 0; i < ids.length; i++) {
      final id = ids[i];
      final prev = _previousListIndexByDriverId[id];
      if (prev != null && prev != i) {
        nextTrend[id] = i < prev ? 1 : -1;
      } else {
        nextTrend[id] = 0;
      }
    }
    _positionTrendByDriverId = nextTrend;
    _previousListIndexByDriverId = {for (var j = 0; j < ids.length; j++) ids[j]: j};
    _sortedDriverIds = ids;
  }

  /// Tyre chip for leaderboard: solid-circle badge + age with fresh/used color.
  Widget _buildTyreTelemetryChip(String? compound, int? age, {bool? tyreNew}) {
    return _TyreTelemetryChip(compound: compound, age: age, tyreNew: tyreNew);
  }

  void _updateSectorBestFromHighlights() {
    final m = <int, String>{0: '', 1: '', 2: ''};
    for (final e in _sectorHighlights.entries) {
      final num = e.key;
      final code = _driverAbbrev[num] ?? '';
      if (code.isEmpty) continue;
      for (final se in e.value.entries) {
        if (se.value == SectorStatus.purple) {
          m[se.key] = code;
        }
      }
    }
    _sectorBestCodes = m;
  }

  String _formatGapThreeDecimals(String raw) => _formatGapThreeDecimalsTop(raw);

  int? _fastestLapDriverNumber() {
    final t = _fastestLapTime;
    if (t == null || t.isEmpty) return null;
    for (final id in _driverStorage.keys) {
      final d = _driverStorage[id] as Map?;
      final lap = d?['LastLapTime']?.toString();
      if (lap != null && lap == t) {
        return d?['number'] as int? ?? int.tryParse(id);
      }
    }
    return null;
  }

  List<LiveTimingTowerRowModel> _buildTowerRows() {
    if (_sortedDriverIds.isNotEmpty && _sortedDriverIds.length <= 2) {
      debugPrint('[TYRE-TRACE] _buildTowerRows: only ${_sortedDriverIds.length} sorted IDs!');
    }
    final rows = <LiveTimingTowerRowModel>[];
    for (var i = 0; i < _sortedDriverIds.length; i++) {
      final id = _sortedDriverIds[i];
      final data = Map<String, dynamic>.from(_driverStorage[id] as Map? ?? {});
      final number = data['number'] as int? ?? int.tryParse(id) ?? 0;
      final team = data['team'] as String? ?? _silverstone2024Teams[number] ?? '';
      final stopped = _liveDriverIsRetired(data);
      final lastLap = data['LastLapTime']?.toString() ?? '–';
      final purple = data['LastLapOverallFastest'] == true;
      final pits = data['NumberOfPitStops'];
      final pitN = pits is int ? pits : int.tryParse(pits?.toString() ?? '') ?? -1;
      final pitDur = data['LastPitStopDuration']?.toString();
      final pitsText = pitN >= 0
          ? ((pitDur != null && pitDur.isNotEmpty) ? '$pitN • $pitDur' : '$pitN')
          : '–';
      String gapLine;
      if (stopped) {
        gapLine = data['GapToLeader']?.toString() ?? '–';
      } else if (i == 0) {
        // P1: INT/GAP column shows last lap time (not lap count).
        final lt = lastLap.trim();
        gapLine = (lt.isNotEmpty && lt != '–') ? lt : '–';
      } else {
        final aboveId = _sortedDriverIds[i - 1];
        final aboveData = Map<String, dynamic>.from(_driverStorage[aboveId] as Map? ?? {});
        gapLine = _intervalFromSortedPositionFormatted(data, aboveData);
      }
      final tyreLetter = _tyreCompoundLetterFromStorage(data['TyreCompound']);
      final letter = tyreLetter ?? '?';
      if (id == '63' || id == '11') {
        debugPrint('[TYRE-TRACE] _buildTowerRows id=$id: TyreCompound=${data['TyreCompound']}, '
            'letter=$letter, Stints=${data['Stints'] != null ? 'present' : 'null'}, '
            'source=${data['TyreDataSource']}');
      }
      final age = tyreLetter != null
          ? (data['TyreAge'] is int
              ? data['TyreAge'] as int
              : int.tryParse(data['TyreAge']?.toString() ?? '') ?? -1)
          : -1;
      final ds = data['TyreDataSource']?.toString() ?? 'UNKNOWN';
      var outLabel = '';
      if (stopped) {
        outLabel = data['Stopped'] == true ? 'STOP' : 'OUT';
        gapLine = outLabel;
      }
      final lastLapTower = stopped ? outLabel : lastLap;
      final pitsTower = stopped ? '–' : pitsText;
      List<MiniSectorBlockVM> m0;
      List<MiniSectorBlockVM> m1;
      List<MiniSectorBlockVM> m2;
      if (i > 0) {
        final aid = _sortedDriverIds[i - 1];
        final ad = Map<String, dynamic>.from(_driverStorage[aid] as Map? ?? {});
        final a0 = _buildMini(aid, ad, 0);
        final a1 = _buildMini(aid, ad, 1);
        final a2 = _buildMini(aid, ad, 2);
        m0 = capMiniSectorColumnToAhead(_buildMini(id, data, 0), a0);
        m1 = capMiniSectorColumnToAhead(_buildMini(id, data, 1), a1);
        m2 = capMiniSectorColumnToAhead(_buildMini(id, data, 2), a2);
      } else {
        m0 = _buildMini(id, data, 0);
        m1 = _buildMini(id, data, 1);
        m2 = _buildMini(id, data, 2);
      }
      final tyreNewRaw = data['TyreNew'];
      final tyreNew = tyreNewRaw is bool ? tyreNewRaw : null;
      final gridPos = _gridPositions[id];
      final currentPos = i + 1;
      final gainLoss = gridPos != null ? gridPos - currentPos : 0;
      final nowInPit = data['InPit'] == true;
      rows.add(
        LiveTimingTowerRowModel(
          position: currentPos,
          number: number,
          code: _driverAbbrev[number] ?? '—',
          fullName: data['name'] as String? ?? _driverNames[id] ?? 'Driver',
          teamColor: F1TeamSchemes.getTeamColor(team),
          gapFormatted: gapLine,
          miniS1: m0,
          miniS2: m1,
          miniS3: m2,
          tyreLetter: letter,
          tyreAge: age,
          tyreNew: tyreNew,
          dataSourceLabel: ds,
          pitsText: pitsTower,
          lastLap: lastLapTower,
          lastLapPurple: !stopped && purple,
          stoppedOrOut: stopped,
          outLabel: outLabel,
          gainLoss: gainLoss,
          isOutLap: _outLapFlags[id] == true,
          inPit: nowInPit,
          pitEntryTimestamp: _pitEntryTimestamps[id],
          trackStatusCode: _trackStatusCode,
          trackLimitTicks: _trackLimitsByDriver[number] ?? 0,
          gapTrend: _gapTrendByDriver[id] ?? 0,
        ),
      );
    }
    return rows;
  }

  String _sessionDisplayTitle(AppLocalizations l10n) {
    final a = _sessionTypeLabel.trim();
    final b = _sessionPartLabel.trim();
    if (a.isEmpty && b.isEmpty) return l10n.live_timing_demo_session_title;
    if (a.isNotEmpty && b.isNotEmpty) return '$a · $b';
    return a.isNotEmpty ? a : b;
  }

  String _sessionStatusLabel(AppLocalizations l10n) {
    if (_raceTimingLiveActive) return l10n.live_timing_status_green;
    if (_racePreStartBufferActive) return l10n.live_timing_session_starting_grid;
    return l10n.live_timing_session_pre_start;
  }

  Color _sessionStatusAccent(ColorScheme scheme) {
    if (_raceTimingLiveActive || _racePreStartBufferActive) {
      return scheme.primary;
    }
    return _kLiveSecondaryText;
  }

  Widget _buildTrackStatusChip(BuildContext context, ColorScheme scheme) {
    final l10n = context.l10n;
    Color bg;
    Color fg;
    String label;
    switch (_trackStatusCode) {
      case 2:
        bg = const Color(0xFFFDE047);
        fg = const Color(0xFF1A1D21);
        label = l10n.live_timing_chip_yellow;
        break;
      case 4:
        bg = const Color(0xFFFF9000);
        fg = Colors.white;
        label = l10n.live_timing_chip_safety_car;
        break;
      case 5:
        bg = const Color(0xFFDC2626);
        fg = Colors.white;
        label = l10n.live_timing_chip_red_flag;
        break;
      case 6:
        bg = const Color(0xFFFF9000);
        fg = Colors.white;
        label = l10n.live_timing_chip_vsc;
        break;
      case 7:
        bg = const Color(0xFFFF9000);
        fg = Colors.white;
        label = l10n.live_timing_chip_vsc_end;
        break;
      default:
        bg = const Color(0xFF22C55E).withValues(alpha: 0.12);
        fg = const Color(0xFF22C55E);
        label = _sessionStatusLabel(l10n);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _trackStatusCode == 1 ? bg : bg.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg),
          ),
        ],
      ),
    );
  }

  /// Laatste ISO-timestamp uit de stream (hub `A[…]` tail), lokaal weergegeven.
  String _hubMessageTimeLabel() {
    final t = _latestDataTimestamp;
    if (t == null) return '—:—:—';
    final l = t.toLocal();
    String p2(int v) => v.toString().padLeft(2, '0');
    String p3(int v) => v.toString().padLeft(3, '0');
    return '${p2(l.hour)}:${p2(l.minute)}:${p2(l.second)}.${p3(l.millisecond)}';
  }

  Widget _buildHeaderDesktop(BuildContext context, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: _kLivePrimaryText),
            onPressed: () => context.go('/circuits'),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.live_timing_title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: _kLivePrimaryText,
                  ),
                ),
                Text(
                  _sessionDisplayTitle(context.l10n),
                  style: const TextStyle(fontSize: 11, color: _kLiveSecondaryText),
                ),
              ],
            ),
          ),
          _PulsingLiveBadge(color: scheme.primary, controller: _livePulseController),
        ],
      ),
    );
  }

  Widget _buildSlimSessionBar(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    var maxLap = 0;
    for (final id in _driverStorage.keys) {
      final d = _driverStorage[id] as Map?;
      final n = _parseNumberOfLapsFieldOr(d?['NumberOfLaps'], 0);
      if (n > maxLap) maxLap = n;
    }
    final leadId = _sortedDriverIds.isNotEmpty ? _sortedDriverIds.first : null;
    final leadLap = leadId != null
        ? (_parseNumberOfLapsField((_driverStorage[leadId] as Map?)?['NumberOfLaps']) ??
            maxLap)
        : maxLap;

    final trackStr = _trackTempC != null ? '${_trackTempC!.toStringAsFixed(1)}°C' : '—°C';
    final airStr = _airTempC != null ? '${_airTempC!.toStringAsFixed(1)}°C' : '—°C';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 50),
      child: Material(
        color: _kLiveCardSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _kLiveCardBorder),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: _kLiveCardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
              Flexible(
                child: Text(
                  _sessionDisplayTitle(l10n),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _kLivePrimaryText,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.live_timing_lap_of_total('$leadLap', '$_raceTotalLaps'),
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              if (_rainActive) ...[
                Icon(Icons.water_drop, size: 16, color: scheme.primary),
                const SizedBox(width: 4),
              ],
              Text(
                l10n.live_timing_track_temp_abbr(trackStr),
                style: const TextStyle(fontSize: 10, color: _kLiveSecondaryText),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.live_timing_air_temp_abbr(airStr),
                style: const TextStyle(fontSize: 10, color: _kLiveSecondaryText),
              ),
              const SizedBox(width: 12),
              _buildTrackStatusChip(context, scheme),
              const SizedBox(width: 8),
              Tooltip(
                message: l10n.live_timing_hub_timestamp_tooltip,
                child: Text(
                  _hubMessageTimeLabel(),
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _kLiveSecondaryText,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Legacy: delegates to _handleTimingUpdate for TimingData.
  void _handleTimingDataFromLines(dynamic data) {
    if (data is! Map) return;
    final lines = data['Lines'] as Map<String, dynamic>?;
    if (lines == null) return;

    final storage = Map<String, dynamic>.from(_driverStorage);
    final highlights = Map<int, Map<int, SectorStatus>>.from(_sectorHighlights);
    final sectorUpdatedDrivers3 = <int>{};

    for (final e in lines.entries) {
      final driverId = e.key;
      final line = e.value as Map<String, dynamic>?;
      if (line == null) continue;

      storage[driverId] ??= {};
      final driver = storage[driverId] as Map<String, dynamic>;

      final position = line['Position'];
      if (position != null) driver['Position'] = position is int ? position : int.tryParse(position.toString());

      final lastLap = line['LastLapTime'];
      if (lastLap != null) {
        if (lastLap is Map) {
          driver['LastLapTime'] = (lastLap['Value'] ?? lastLap['value'])?.toString() ?? lastLap.toString();
          driver['LastLapOverallFastest'] = lastLap['OverallFastest'] == true || lastLap['overallFastest'] == true;
          driver['LastLapPersonalFastest'] = lastLap['PersonalFastest'] == true || lastLap['personalFastest'] == true;
        } else {
          driver['LastLapTime'] = lastLap.toString();
        }
      }

      final gap = line['GapToLeader'];
      if (gap != null) driver['GapToLeader'] = gap is Map ? (gap['Value'] ?? gap['value'])?.toString() ?? gap.toString() : gap.toString();

      final interval = line['IntervalToPrimary'];
      if (interval != null) driver['IntervalToPrimary'] = interval is Map ? (interval['Value'] ?? interval['value'])?.toString() ?? interval.toString() : interval.toString();

      final num = int.tryParse(driverId);
      if (num != null) {
        driver['number'] = num;
        driver['name'] = _driverNames[driverId] ?? 'Driver $driverId';
        driver['team'] = _silverstone2024Teams[num] ?? '';
      }

      final sectors = (line['Sectors'] ?? line['BestSectors'] ?? line['CurrentSectors']) as Map<String, dynamic>?;
      if (sectors != null && num != null) {
        highlights[num] ??= {};
        sectorUpdatedDrivers3.add(num);
        for (final s in sectors.entries) {
          final sectorIdx = int.tryParse(s.key);
          if (sectorIdx == null || sectorIdx < 0 || sectorIdx > 2) continue;
          highlights[num]![sectorIdx] = _getSectorStatusFromLine(s.key, s.value);
        }
      }
    }

    _driverStorage = storage;
    _enforceSinglePurplePerSector(highlights, sectorUpdatedDrivers3);
    final demoted3 = _enforceSinglePurplePerSegment(sectorUpdatedDrivers3);
    if (demoted3.isNotEmpty) {
      _refreshHighlightsAfterSegmentEnforcement(highlights, {...sectorUpdatedDrivers3, ...demoted3});
    }
    _sectorHighlights = highlights;
    _updateSectorBestFromHighlights();

    _syncRacePhaseFromFrame(_latestDataTimestamp);
    if (!_raceTimingLiveActive) {
      if (_scheduledRaceGreenUtc == null) {
        _maybeAutoStartRaceFromTelemetryAfterDataMerge();
      }
    }
    final showLeaderboard = _raceTimingLiveActive || _racePreStartBufferActive;
    if (showLeaderboard) {
      _scheduleDebouncedResort(payloadMap: Map<String, dynamic>.from(data));
    } else if (_driverStorage.isNotEmpty) {
      _rebuildSortedOrderAndTrends();
    }

    if (mounted) setState(() {});
  }

  void _handleTimingData(dynamic data) {
    if (data is! Map) return;
    final lines = data['Lines'] as Map<String, dynamic>?;
    if (lines == null) return;

    final highlights = Map<int, Map<int, SectorStatus>>.from(_sectorHighlights);
    final sectorUpdatedDrivers4 = <int>{};

    for (final e in lines.entries) {
      final driverNum = int.tryParse(e.key);
      if (driverNum == null) continue;

      final line = e.value as Map<String, dynamic>?;
      if (line == null) continue;

      final sectors = (line['Sectors'] ?? line['BestSectors'] ?? line['CurrentSectors']) as Map<String, dynamic>?;
      if (sectors == null) continue;

      highlights[driverNum] ??= {};
      sectorUpdatedDrivers4.add(driverNum);
      for (final s in sectors.entries) {
        final sectorIdx = int.tryParse(s.key);
        if (sectorIdx == null || sectorIdx < 0 || sectorIdx > 2) continue;
        highlights[driverNum]![sectorIdx] = _getSectorStatusFromLine(s.key, s.value);
      }
    }

    _enforceSinglePurplePerSector(highlights, sectorUpdatedDrivers4);
    final demoted4 = _enforceSinglePurplePerSegment(sectorUpdatedDrivers4);
    if (demoted4.isNotEmpty) {
      _refreshHighlightsAfterSegmentEnforcement(highlights, {...sectorUpdatedDrivers4, ...demoted4});
    }
    if (mounted) setState(() => _sectorHighlights = highlights);
  }

  void _handlePositionZ(dynamic data) {
    if (data is! String) return;
    final timingFromZ = decodeTimingDataFromBase64String(data);
    if (timingFromZ != null &&
        timingFromZ['Lines'] is Map &&
        (timingFromZ['Lines'] as Map).isNotEmpty) {
      _handleTimingUpdate(timingFromZ);
      return;
    }
    try {
      final bytes = base64Decode(_normalizeMalformedBase64Padding(data));
      final decoded = GZipDecoder().decodeBytes(bytes);
      final json = jsonDecode(utf8.decode(decoded));

      // F1 Position format varies; try common shapes
      List<Map<String, dynamic>> entries = [];
      if (json is List) {
        for (final item in json) {
          if (item is Map) entries.add(Map<String, dynamic>.from(item));
        }
      } else if (json is Map) {
        final arr = json['Position'] ?? json['Entries'] ?? json['Lines'];
        if (arr is List) {
          for (final item in arr) {
            if (item is Map) entries.add(Map<String, dynamic>.from(item));
          }
        } else if (json['M'] is List) {
          // Alternative format
          for (final row in json['M'] as List) {
            if (row is List && row.length >= 2) {
              entries.add({
                'Position': row[0],
                'RacingNumber': row.length > 1 ? row[1] : null,
                'IntervalToPositionAhead': row.length > 4 ? row[4] : null,
                'GapToLeader': row.length > 3 ? row[3] : null,
              });
            }
          }
        }
      }

      if (entries.isEmpty) return;

      // Build leaderboard sorted by Position; extract LastLapTime/BestLapTime from raw entry
      final List<LiveDriverEntry> board = [];
      for (final e in entries) {
        final pos = e['Position'] ?? e['position'];
        final num = e['RacingNumber'] ?? e['Number'] ?? e['DriverNo'] ?? e['number'];
        final gap = e['GapToLeader'] ?? e['Gap'] ?? e['gap'];
        final interval = e['IntervalToPositionAhead'] ?? e['Interval'] ?? e['interval'];
        final lastLapStr = _extractLapTimeFromEntry(e);

        final position = pos is int ? pos : int.tryParse(pos?.toString() ?? '') ?? 0;
        final number = num is int ? num : int.tryParse(num?.toString() ?? '') ?? 0;
        final gapStr = gap is Map
            ? ((gap['Value'] ?? gap['value'])?.toString() ?? '–')
            : (gap?.toString() ?? '–');
        final intervalStr = interval is Map
            ? (interval['Value'] ?? interval['value'])?.toString()
            : interval?.toString();
        final nlRaw = e['NumberOfLaps'];
        final nLaps = _parseNumberOfLapsField(nlRaw);
        final rowData = <String, dynamic>{
          'GapToLeader': gapStr,
          'Stopped': e['Stopped'] == true,
          'Retired': e['Retired'] == true,
        };

        board.add(LiveDriverEntry(
          position: position,
          name: _silverstone2024Drivers[number] ?? '#$number',
          initials: _driverAbbrev[number] ?? '—',
          number: number,
          team: _silverstone2024Teams[number] ?? '',
          lastLap: lastLapStr,
          gap: gapStr,
          delta: intervalStr,
          intervalToAhead: intervalStr,
          isRetired: _liveDriverIsRetired(rowData),
          numberOfLaps: nLaps,
          totalRaceLaps: _raceTotalLaps,
          positionTrend: 0,
        ));
      }
      board.sort((a, b) => a.position.compareTo(b.position));

      // Merge Position.z into _driverStorage; include LastLapTime when present
      final storage = Map<String, dynamic>.from(_driverStorage);
      for (final e in board) {
        final id = '${e.number}';
        storage[id] ??= {};
        final m = storage[id] as Map<String, dynamic>;
        m['Position'] = e.position;
        m['GapToLeader'] = e.gap;
        m['name'] = e.name;
        m['team'] = e.team;
        m['number'] = e.number;
        if (e.isRetired) {
          m['Stopped'] = true;
        }
        if (e.lastLap != null && e.lastLap!.isNotEmpty) {
          m['LastLapTime'] = e.lastLap;
        }
        if (e.numberOfLaps != null) m['NumberOfLaps'] = e.numberOfLaps;
      }
      _driverStorage = storage;
      _syncRacePhaseFromFrame(_latestDataTimestamp);
      if (!_raceTimingLiveActive) {
        if (_scheduledRaceGreenUtc == null) {
          _maybeAutoStartRaceFromTelemetryAfterDataMerge();
        }
      }
      final showLeaderboard = _raceTimingLiveActive || _racePreStartBufferActive;
      if (showLeaderboard) {
        _scheduleDebouncedResort();
      } else if (_driverStorage.isNotEmpty) {
        _rebuildSortedOrderAndTrends();
      }

      if (mounted) {
        setState(() {
          _leaderboard = board;
        });
      }
    } catch (_) {}
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _resortDebounceTimer?.cancel();
    _disconnect();
    _livePulseController.dispose();
    _leaderboardEntranceAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final wide = MediaQuery.sizeOf(context).width >= _kDesktopTimingBreakpoint;

    return Scaffold(
      backgroundColor: _kLiveDashboardBg,
      bottomNavigationBar: _buildReplayControlBar(context, compact: wide),
      body: _buildScreenLayout(
        context: context,
        wide: wide,
        scheme: scheme,
        primary: primary,
      ),
    );
  }

  /// Image 25 layout: no teammate strip; leaderboard starts under header (mobile) or session bar (desktop).
  Widget _buildScreenLayout({
    required BuildContext context,
    required bool wide,
    required ColorScheme scheme,
    required Color primary,
  }) {
    if (wide) {
      return _buildDesktopAmbientLayout(context, scheme);
    }
    return ColoredBox(
      color: _kLiveDashboardBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, primary),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.035),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _leaderboardEntranceAnim,
                      curve: Curves.easeInOutCubic,
                    ),
                  ),
                  child: _buildLeaderboardSection(context, primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopAmbientLayout(BuildContext context, ColorScheme scheme) {
    return ColoredBox(
      color: _kLiveDashboardBg,
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGlassNavRail(context, scheme),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderDesktop(context, scheme),
                    const SizedBox(height: 6),
                    _buildSlimSessionBar(context),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.035),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _leaderboardEntranceAnim,
                            curve: Curves.easeInOutCubic,
                          ),
                        ),
                        child: LiveTimingDataTable(
                          rows: _buildTowerRows(),
                          fastestLapDriverNumber: _fastestLapDriverNumber(),
                          sectorBestCodes: Map<int, String>.from(_sectorBestCodes),
                          trackStatusCode: _trackStatusCode,
                          trackStatusMessage: _trackStatusMessage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassNavRail(BuildContext context, ColorScheme scheme) {
    final muted = _kLivePrimaryText.withValues(alpha: 0.5);
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(14)),
        side: BorderSide(color: _kLiveCardBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: NavigationRail(
        selectedIndex: _hubNavIndex,
        labelType: NavigationRailLabelType.none,
        minWidth: 56,
        groupAlignment: -0.2,
        backgroundColor: Colors.transparent,
        indicatorColor: _kLiveTimingPurple.withValues(alpha: 0.12),
        selectedIconTheme: const IconThemeData(color: _kLiveTimingPurple),
        unselectedIconTheme: IconThemeData(color: muted),
        onDestinationSelected: (i) {
          setState(() => _hubNavIndex = i);
          if (i == 0 && mounted) context.go('/circuits');
        },
        destinations: [
          NavigationRailDestination(
            icon: Icon(Icons.dashboard_outlined, color: muted),
            selectedIcon: const Icon(Icons.dashboard, color: _kLiveTimingPurple),
            label: const Text(''),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.flag_outlined, color: muted),
            selectedIcon: const Icon(Icons.flag, color: _kLiveTimingPurple),
            label: const Text(''),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.person_outline, color: muted),
            selectedIcon: const Icon(Icons.person, color: _kLiveTimingPurple),
            label: const Text(''),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.people_outline, color: muted),
            selectedIcon: const Icon(Icons.people, color: _kLiveTimingPurple),
            label: const Text(''),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.settings_outlined, color: muted),
            selectedIcon: const Icon(Icons.settings, color: _kLiveTimingPurple),
            label: const Text(''),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: _kLivePrimaryText),
            onPressed: () => context.go('/circuits'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.live_timing_title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _kLivePrimaryText,
                      ),
                ),
                Text(
                  'Silverstone 2024',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _kLiveSecondaryText,
                      ),
                ),
              ],
            ),
          ),
          _PulsingLiveBadge(color: primary, controller: _livePulseController),
        ],
      ),
    );
  }

  /// Light-mode driver card: white surface, 4px team strip, shadows; [sectorMiniTiers] are pre-capped
  /// vs. the car ahead ([capMiniSectorColumnToAhead]) for trailing rows. P1 INT/GAP = [entry.gap] (last lap).
  Widget _buildDriverCard({
    required LiveDriverEntry entry,
    required Color primary,
    required Widget tyreChip,
    Map<int, SectorStatus>? sectorHighlights,
    Map<int, String?>? sectorTimes,
    List<List<MiniSectorBlockVM>>? sectorMiniTiers,
  }) {
    return _LiveCard(
      entry: entry,
      primary: primary,
      tyreChip: tyreChip,
      sectorHighlights: sectorHighlights,
      sectorTimes: sectorTimes,
      sectorMiniTiers: sectorMiniTiers,
    );
  }

  /// Predicted list index after pit exit: count on-track cars still ahead at (gap + 25s).
  int _predictedPitRejoinIndex(String pitDriverId) {
    final pit = _driverStorage[pitDriverId] as Map<String, dynamic>?;
    if (pit == null) return 0;
    var base = _gapToLeaderSortOrdinal(pit);
    if (base >= 999990) base = 0.0;
    final predicted = base + _kPitRejoinEstimateSeconds;
    var slot = 0;
    for (final id in _sortedDriverIds) {
      if (id == pitDriverId) continue;
      final other = _driverStorage[id] as Map<String, dynamic>?;
      if (other == null || _liveDriverIsRetired(other)) continue;
      final og = _gapToLeaderSortOrdinal(other);
      if (og >= 999990) continue;
      if (og < predicted) slot++;
    }
    final n = _sortedDriverIds.length;
    final maxSlot = n <= 1 ? 0 : n - 1;
    return slot.clamp(0, maxSlot);
  }

  Widget _buildPitShadowPlaceholder(BuildContext context, String pitDriverId) {
    final data = _driverStorage[pitDriverId] as Map<String, dynamic>? ?? {};
    final number = data['number'] as int? ?? int.tryParse(pitDriverId) ?? 0;
    final team = data['team'] as String? ?? _silverstone2024Teams[number] ?? '';
    final strip = F1TeamSchemes.getTeamColor(team);
    var base = _gapToLeaderSortOrdinal(data);
    if (base >= 999990) base = 0.0;
    final estGap = base + _kPitRejoinEstimateSeconds;
    return IgnorePointer(
      child: Opacity(
        opacity: 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: _kLiveCardSurface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kLiveTimingPurple.withValues(alpha: 0.35)),
            boxShadow: _kLiveCardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: _liveTeamStripColor(strip)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_driverAbbrev[number] ?? pitDriverId} · PIT → est. ~+${estGap.toStringAsFixed(1)}s',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kLiveSecondaryText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Animated reorder: each driver keyed by id; [top] follows sort index.
  Widget _buildAnimatedLeaderboardStack(BuildContext context, Color primary) {
    final n = _sortedDriverIds.length;
    final pitIds = _sortedDriverIds
        .where((id) {
          final m = _driverStorage[id] as Map<String, dynamic>?;
          return m != null && m['InPit'] == true && !_liveDriverIsRetired(m);
        })
        .toList();

    var stackHeight = n * _kLeaderCardStride;
    for (final pid in pitIds) {
      final s = _predictedPitRejoinIndex(pid);
      final bottom = (s + 1) * _kLeaderCardStride;
      if (bottom > stackHeight) stackHeight = bottom;
    }

    return SizedBox(
      height: stackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final pid in pitIds)
            Positioned(
              key: ValueKey<String>('pit_shadow_$pid'),
              top: _predictedPitRejoinIndex(pid) * _kLeaderCardStride,
              left: 0,
              right: 0,
              height: _kLeaderCardHeight,
              child: _buildPitShadowPlaceholder(context, pid),
            ),
          for (var i = 0; i < n; i++)
            AnimatedPositioned(
              key: ValueKey<String>(_sortedDriverIds[i]),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
              top: i * _kLeaderCardStride,
              left: 0,
              right: 0,
              height: _kLeaderCardHeight,
              child: _leaderboardCardAtIndex(context, i, primary),
            ),
        ],
      ),
    );
  }

  Widget _leaderboardCardAtIndex(BuildContext context, int index, Color primary) {
    final id = _sortedDriverIds[index];
    final data = _driverStorage[id] as Map<String, dynamic>? ?? {};
    final aheadId = index > 0 ? _sortedDriverIds[index - 1] : null;
    final aheadData =
        aheadId != null ? (_driverStorage[aheadId] as Map<String, dynamic>? ?? {}) : null;
    final number = data['number'] as int? ?? int.tryParse(id) ?? 0;
    final team = data['team'] as String? ?? _silverstone2024Teams[number] ?? '';
    final teamColor = F1TeamSchemes.getTeamColor(team);
    final lastLap = data['LastLapTime'] as String?;
    final overallFastest = data['LastLapOverallFastest'] == true;
    final personalFastest = data['LastLapPersonalFastest'] == true;
    final inPit = data['InPit'] == true;
    final sectorTimesMap = data['SectorTimes'] as Map?;
    final s0 = sectorTimesMap != null ? sectorTimesMap['0']?.toString() : null;
    final s1 = sectorTimesMap != null ? sectorTimesMap['1']?.toString() : null;
    final s2 = sectorTimesMap != null ? sectorTimesMap['2']?.toString() : null;
    final sectorTimes = <int, String?>{
      0: _shortSectorTime(s0),
      1: _shortSectorTime(s1),
      2: _shortSectorTime(s2),
    };
    final numberOfLaps = _parseNumberOfLapsField(data['NumberOfLaps']);
    final isRetired = _liveDriverIsRetired(data);
    late final String gapLine;
    if (isRetired) {
      gapLine = data['Stopped'] == true ? 'STOP' : 'OUT';
    } else if (index == 0) {
      final lt = lastLap?.trim() ?? '';
      gapLine = (lt.isNotEmpty && lt != '–') ? lt : '–';
    } else if (aheadData != null) {
      gapLine = _intervalFromSortedPositionFormatted(data, aheadData);
    } else {
      gapLine = '–';
    }
    Map<int, SectorStatus>? sectorHighlights = _sectorHighlights[number];
    if (sectorHighlights == null) {
      final sectors = data['Sectors'] as Map<String, dynamic>?;
      if (sectors != null) {
        sectorHighlights = {};
        for (final s in sectors.entries) {
          final sectorIdx = int.tryParse(s.key);
          if (sectorIdx == null || sectorIdx < 0 || sectorIdx > 2) continue;
          sectorHighlights[sectorIdx] = _getSectorStatusFromLine(s.key, s.value);
        }
      }
    }
    final List<List<MiniSectorBlockVM>> sectorMiniTiers;
    if (aheadId != null) {
      final ad = _driverStorage[aheadId] as Map<String, dynamic>? ?? {};
      final a0 = _buildMini(aheadId, ad, 0);
      final a1 = _buildMini(aheadId, ad, 1);
      final a2 = _buildMini(aheadId, ad, 2);
      sectorMiniTiers = [
        capMiniSectorColumnToAhead(_buildMini(id, data, 0), a0),
        capMiniSectorColumnToAhead(_buildMini(id, data, 1), a1),
        capMiniSectorColumnToAhead(_buildMini(id, data, 2), a2),
      ];
    } else {
      sectorMiniTiers = [
        _buildMini(id, data, 0),
        _buildMini(id, data, 1),
        _buildMini(id, data, 2),
      ];
    }
    final tyreLetter = _tyreCompoundLetterFromStorage(data['TyreCompound']);
    final gridPos = _gridPositions[id];
    final currentPos = index + 1;
    final gainLoss = gridPos != null ? gridPos - currentPos : 0;
    final entry = LiveDriverEntry(
      position: currentPos,
      name: data['name'] as String? ?? _driverNames[id] ?? 'Driver $id',
      initials: _driverAbbrev[number] ?? '—',
      number: number,
      team: team,
      lastLap: lastLap,
      gap: gapLine,
      delta: null,
      intervalToAhead: null,
      isFastestLap: lastLap != null && lastLap == _fastestLapTime,
      overallFastestLap: overallFastest,
      personalFastestLap: personalFastest,
      inPit: inPit,
      tyreCompound: tyreLetter,
      tyreAge: tyreLetter != null
          ? (data['TyreAge'] is int
              ? data['TyreAge'] as int
              : int.tryParse(data['TyreAge']?.toString() ?? ''))
          : null,
      tyreNew: data['TyreNew'] is bool ? data['TyreNew'] as bool : null,
      speedTrapKmh: _speedTrapKmhFromData(data),
      isRetired: isRetired,
      numberOfLaps: numberOfLaps,
      totalRaceLaps: _raceTotalLaps,
      positionTrend: _positionTrendByDriverId[id] ?? 0,
      tyreDataSourceLabel: data['TyreDataSource']?.toString() ?? 'UNKNOWN',
      gridPosition: gridPos,
      gainLoss: gainLoss,
      isOutLap: _outLapFlags[id] == true,
      pitEntryTimestamp: _pitEntryTimestamps[id],
    );
    return _buildDriverCard(
      entry: entry,
      primary: teamColor,
      sectorHighlights: sectorHighlights,
      sectorTimes: sectorTimes,
      sectorMiniTiers: sectorMiniTiers,
      tyreChip: _buildTyreTelemetryChip(entry.tyreCompound, entry.tyreAge, tyreNew: entry.tyreNew),
    );
  }

  /// Convenience: builds mini-sector column with ghost-prevention wired in.
  List<MiniSectorBlockVM> _buildMini(String driverId, Map<String, dynamic> data, int sectorIdx) {
    final num = int.tryParse(driverId);
    return buildMiniSectorBlockColumn(
      driverId, data, sectorIdx, _microSegmentCompleteHubMs,
      purpleOwners: _purpleSegmentOwner,
      driverNum: num,
    );
  }

  Widget _buildLeaderboardSection(BuildContext context, Color primary) {
    final hasStorageData = _sortedDriverIds.isNotEmpty;
    final hasLeaderboard = _leaderboard.isNotEmpty;
    final isEmpty = !hasStorageData && !hasLeaderboard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.live_leaderboard,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kLivePrimaryText,
          ),
        ),
        const SizedBox(height: 8),
        if (isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kLiveCardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kLiveCardBorder, width: 1),
              boxShadow: _kLiveCardShadow,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: _kLiveTimingPurple),
                  const SizedBox(height: 16),
                  Text(
                    _raceTimingLiveActive
                        ? 'Wachten op eerste frame...'
                        : 'Waiting for RACE STARTED (GREEN flag)...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _kLiveSecondaryText.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (hasStorageData)
          _buildAnimatedLeaderboardStack(context, primary)
        else
          ..._leaderboard.asMap().entries.map((e) {
            final entry = e.value;
            final highlights = _sectorHighlights[entry.number];
            final teamColor = F1TeamSchemes.getTeamColor(entry.team);
            return Padding(
              padding: EdgeInsets.only(bottom: e.key < _leaderboard.length - 1 ? _kLeaderCardGap : 0),
              child: _LiveCard(
                entry: entry,
                primary: entry.team.isNotEmpty ? teamColor : primary,
                sectorHighlights: highlights,
                tyreChip: _buildTyreTelemetryChip(entry.tyreCompound, entry.tyreAge, tyreNew: entry.tyreNew),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildReplayControlBar(BuildContext context, {bool compact = false}) {
    final firstMs = _sessionFirstTsMs ?? 0.0;
    final lastMs = _sessionLastTsMs ?? 1.0;
    final rangeMs = (lastMs - firstMs).clamp(1.0, double.infinity);
    final currentMs = (_latestDataTimestamp?.millisecondsSinceEpoch.toDouble() ?? firstMs);
    final sliderValue = ((currentMs - firstMs) / rangeMs).clamp(0.0, 1.0);

    String sessionTimeStr = '--:--:--';
    if (_latestDataTimestamp != null && _firstDataTimestamp != null) {
      final diff = _latestDataTimestamp!.difference(_firstDataTimestamp!);
      final h = diff.inHours;
      final m = diff.inMinutes.remainder(60);
      final s = diff.inSeconds.remainder(60);
      sessionTimeStr = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    final onBar = _kLivePrimaryText;
    final speedRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SpeedButton(
          label: '1x',
          speed: 1.0,
          currentSpeed: _replaySpeed,
          onTap: () => _setSpeedAndReconnect(1.0),
        ),
        SizedBox(width: compact ? 6 : 8),
        _SpeedButton(
          label: '2x',
          speed: 2.0,
          currentSpeed: _replaySpeed,
          onTap: () => _setSpeedAndReconnect(2.0),
        ),
        SizedBox(width: compact ? 6 : 8),
        _SpeedButton(
          label: '5x',
          speed: 5.0,
          currentSpeed: _replaySpeed,
          onTap: () => _setSpeedAndReconnect(5.0),
        ),
      ],
    );

    final sliderThemed = Theme.of(context).copyWith(
      sliderTheme: SliderTheme.of(context).copyWith(
        activeTrackColor: _kLiveTimingPurple.withValues(alpha: 0.45),
        inactiveTrackColor: _kLiveCardBorder.withValues(alpha: 0.85),
        thumbColor: _kLiveTimingPurple,
        trackHeight: compact ? 2 : 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: compact ? 5 : 10),
      ),
    );

    Widget barContent = compact
        ? SizedBox(
            height: 40,
            child: Row(
              children: [
                speedRow,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Slider(
                      value: sliderValue,
                      onChanged: null,
                    ),
                  ),
                ),
                Text(
                  sessionTimeStr,
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: onBar,
                  ),
                ),
              ],
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: sliderValue,
                onChanged: null,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  speedRow,
                  Text(
                    sessionTimeStr,
                    style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: onBar,
                    ),
                  ),
                ],
              ),
            ],
          );

    if (compact) {
      return BottomAppBar(
        elevation: 0,
        color: Colors.transparent,
        padding: EdgeInsets.zero,
        child: SafeArea(
          top: false,
          child: Material(
            color: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              side: BorderSide(color: _kLiveCardBorder, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Theme(
                data: sliderThemed,
                child: barContent,
              ),
            ),
          ),
        ),
      );
    }

    return BottomAppBar(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        top: false,
        child: Theme(
          data: sliderThemed,
          child: barContent,
        ),
      ),
    );
  }

  void _setSpeedAndReconnect(double speed) {
    setState(() => _replaySpeed = speed);
    _connect(resetReplayOffset: false);
  }
}

/// Sector time pill + sequential mini-segment strip (matches timing tower logic).
class _SectorCellColumn extends StatelessWidget {
  const _SectorCellColumn({
    required this.label,
    required this.status,
    this.timeText,
    required this.miniBlocks,
  });

  final String label;
  final SectorStatus status;
  final String? timeText;
  final List<MiniSectorBlockVM> miniBlocks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectorPill(label: label, status: status, timeText: timeText),
        const SizedBox(height: 4),
        _DarkMiniSectorRow(blocks: miniBlocks),
      ],
    );
  }
}

class _DarkMiniSectorRow extends StatelessWidget {
  const _DarkMiniSectorRow({required this.blocks});

  final List<MiniSectorBlockVM> blocks;
  static const double _barHeight = 9;

  static Color _tierColor(MiniSectorTier t) {
    switch (t) {
      case MiniSectorTier.off:
        return const Color(0xFFE8EAEF);
      case MiniSectorTier.neutral:
        return const Color(0xFFC4A84A);
      case MiniSectorTier.personalBest:
        return const Color(0xFF0D9488);
      case MiniSectorTier.overallBest:
        return _kLiveTimingPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: _barHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            _darkSectorCell(blocks[i]),
          ],
        ],
      ),
    );
  }

  static Widget _darkSectorCell(MiniSectorBlockVM vm) {
    final base = vm.fill != MiniSectorTier.off ? _tierColor(vm.fill) : const Color(0xFFE8EAEF);
    Widget box = Container(
      width: 6,
      height: _barHeight,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: const Color(0xFFCBD2DC).withValues(
            alpha: vm.fill != MiniSectorTier.off ? 0.55 : (vm.glow > 0.02 ? 0.45 : 0.35),
          ),
          width: 0.3,
        ),
      ),
    );
    if (vm.fill == MiniSectorTier.off && vm.glow > 0.02) {
      final g = vm.glow.clamp(0.0, 1.0);
      box = Stack(
        alignment: Alignment.center,
        children: [
          box,
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFC4A84A).withValues(alpha: 0),
                    const Color(0xFF0D9488).withValues(alpha: 0.12 * g),
                    _kLiveTimingPurple.withValues(alpha: 0.1 * g),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    return box;
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({
    required this.entry,
    required this.primary,
    required this.tyreChip,
    this.sectorHighlights,
    this.sectorTimes,
    this.sectorMiniTiers,
  });

  final LiveDriverEntry entry;
  final Color primary;
  final Widget tyreChip;
  final Map<int, SectorStatus>? sectorHighlights;
  /// Optional sector times (0,1,2) – short strings e.g. "29.3".
  final Map<int, String?>? sectorTimes;
  /// When set (storage path), shows sequential mini-sectors under each S1–S3 pill.
  final List<List<MiniSectorBlockVM>>? sectorMiniTiers;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLeader = entry.position == 1;
    final dsLabel = entry.tyreDataSourceLabel ?? '';
    final lastLapColor = entry.overallFastestLap || entry.isFastestLap
        ? _kF1Purple
        : entry.personalFastestLap
            ? _kF1Green
            : _kLivePrimaryText.withValues(alpha: 0.92);

    /// P1: last lap in INT/GAP. P2+: single line `+|(gap−gap_above)|` via [entry.gap].
    Widget lapGapBlock() {
      if (isLeader) {
        final lt = entry.lastLap?.trim() ?? '';
        final show =
            entry.isRetired ? entry.gap : ((lt.isNotEmpty && lt != '–') ? lt : '–');
        return _buildIntervalWidget(
          show,
          color: entry.isRetired ? _kLiveSecondaryText : _kF1Purple,
        );
      }
      if (entry.inPit) {
        return _buildIntervalWidget(
          '---',
          color: _kLiveSecondaryText,
        );
      }
      return _buildIntervalWidget(_formatGap(entry.gap));
    }

    Widget card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kLiveCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kLiveCardBorder, width: 1),
        boxShadow: _kLiveCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: _liveTeamStripColor(primary)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  10,
                  8,
                  10,
                  entry.speedTrapKmh != null
                      ? 28
                      : (dsLabel.isNotEmpty ? 22 : 8),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${entry.position} ${entry.initials}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _kLivePrimaryText,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  if (entry.positionTrend > 0) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_upward, size: 15, color: Color(0xFF00E676)),
                                  ] else if (entry.positionTrend < 0) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_downward, size: 15, color: Color(0xFFFF5252)),
                                  ],
                                  if (entry.isRetired) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFD32F2F),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        l10n.live_timing_driver_out,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (entry.team.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  entry.team,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: _kLiveSecondaryText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 3),
                              Text(
                                entry.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _kLivePrimaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              lapGapBlock(),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  tyreChip,
                                  if (entry.inPit) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        l10n.live_timing_driver_pit,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (dsLabel.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  l10n.live_timing_data_source(dsLabel),
                                  style: TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.w500,
                                    color: _kLiveSecondaryText.withValues(alpha: 0.85),
                                    letterSpacing: 0.15,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                entry.inPit ? '---' : (entry.lastLap ?? '--:--.---'),
                                style: GoogleFonts.robotoMono(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: lastLapColor,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          if (sectorMiniTiers != null && sectorMiniTiers!.length >= 3) ...[
                            _SectorCellColumn(
                              label: l10n.live_timing_header_s1,
                              status: sectorHighlights?[0] ?? SectorStatus.yellow,
                              timeText: sectorTimes?[0],
                              miniBlocks: sectorMiniTiers![0],
                            ),
                            const SizedBox(width: 6),
                            _SectorCellColumn(
                              label: l10n.live_timing_header_s2,
                              status: sectorHighlights?[1] ?? SectorStatus.yellow,
                              timeText: sectorTimes?[1],
                              miniBlocks: sectorMiniTiers![1],
                            ),
                            const SizedBox(width: 6),
                            _SectorCellColumn(
                              label: l10n.live_timing_header_s3,
                              status: sectorHighlights?[2] ?? SectorStatus.yellow,
                              timeText: sectorTimes?[2],
                              miniBlocks: sectorMiniTiers![2],
                            ),
                          ] else ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _SectorPill(
                                  label: l10n.live_timing_header_s1,
                                  status: sectorHighlights?[0] ?? SectorStatus.yellow,
                                  timeText: sectorTimes?[0],
                                ),
                                const SizedBox(width: 5),
                                _SectorPill(
                                  label: l10n.live_timing_header_s2,
                                  status: sectorHighlights?[1] ?? SectorStatus.yellow,
                                  timeText: sectorTimes?[1],
                                ),
                                const SizedBox(width: 5),
                                _SectorPill(
                                  label: l10n.live_timing_header_s3,
                                  status: sectorHighlights?[2] ?? SectorStatus.yellow,
                                  timeText: sectorTimes?[2],
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (entry.speedTrapKmh != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kLiveDashboardBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _kLiveCardBorder, width: 0.5),
                          ),
                          child: Text(
                            '${entry.speedTrapKmh} km/h',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: _kLiveSecondaryText,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (entry.isRetired) {
      card = Opacity(opacity: 0.55, child: card);
    }

    return card;
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({
    required this.label,
    required this.speed,
    required this.currentSpeed,
    required this.onTap,
  });

  final String label;
  final double speed;
  final double currentSpeed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = (currentSpeed - speed).abs() < 0.01;
    final scheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: scheme.onSurface,
        backgroundColor:
            isSelected ? scheme.primary.withValues(alpha: 0.18) : null,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

/// Broadcast-style tyre telemetry: Soft red, Medium yellow, Hard white, Inter green; unknown = grey `?`.
class _TyreTelemetryChip extends StatelessWidget {
  const _TyreTelemetryChip({this.compound, this.age, this.tyreNew});

  final String? compound;
  final int? age;
  final bool? tyreNew;

  bool get _unknown =>
      compound == null || compound!.isEmpty || compound == '–' || compound == '?';

  String get _letter {
    if (_unknown) return '?';
    return compound!.toUpperCase().substring(0, 1);
  }

  static const _badgeColors = <String, (Color bg, Color fg, Color? border)>{
    'S': (Color(0xFFFF0000), Colors.white, null),
    'M': (Color(0xFFFFFF00), Colors.black, null),
    'H': (Colors.white, Colors.black, Color(0xFF9E9E9E)),
    'I': (Color(0xFF00D21D), Colors.white, null),
    'W': (Color(0xFF0082FA), Colors.white, null),
  };

  @override
  Widget build(BuildContext context) {
    final letter = _letter;
    final (bg, fg, border) = _badgeColors[letter] ??
        (const Color(0xFFD1D5DB), const Color(0xFF6B7280), null);
    final showAge = !_unknown && age != null;
    final ageColor = tyreNew == true
        ? const Color(0xFF00D21D)
        : tyreNew == false
            ? const Color(0xFFFF9000)
            : const Color(0xFF9CA3AF);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: border != null
                ? Border.all(color: border, width: 1)
                : null,
          ),
          child: Text(
            letter,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: fg,
              height: 1.0,
            ),
          ),
        ),
        if (showAge) ...[
          const SizedBox(width: 4),
          Text(
            '${age!}',
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: ageColor,
              height: 1.1,
            ),
          ),
        ],
      ],
    );
  }
}

/// Stadium pill: S1/S2/S3 label + sector time (8pt white); fill = purple / green / yellow by status.
class _SectorPill extends StatelessWidget {
  const _SectorPill({
    required this.label,
    required this.status,
    this.timeText,
  });

  final String label;
  final SectorStatus status;
  final String? timeText;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    switch (status) {
      case SectorStatus.purple:
        fill = const Color(0xFFD8C8EB);
        break;
      case SectorStatus.green:
        fill = const Color(0xFFB8DDD4);
        break;
      case SectorStatus.yellow:
        fill = const Color(0xFFEDE9B8);
        break;
    }
    final display = (timeText != null && timeText!.isNotEmpty) ? timeText! : '–';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      constraints: const BoxConstraints(minWidth: 36),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _kLiveCardBorder, width: 0.5),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.w800,
              color: _kLivePrimaryText,
              height: 1,
            ),
          ),
          Text(
            display,
            style: GoogleFonts.robotoMono(
              fontSize: 8.0,
              fontWeight: FontWeight.w700,
              color: _kF1Purple,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingLiveBadge extends StatelessWidget {
  const _PulsingLiveBadge({
    required this.color,
    required this.controller,
  });

  final Color color;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final opacity = 0.6 + (controller.value * 0.4);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: opacity)),
          ),
          child: Text(
            'LIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: const Color(0xFFDC2626).withValues(alpha: opacity),
            ),
          ),
        );
      },
    );
  }
}

class LiveDriverEntry {
  LiveDriverEntry({
    required this.position,
    required this.name,
    required this.initials,
    required this.number,
    required this.team,
    this.lastLap,
    required this.gap,
    this.delta,
    this.intervalToAhead,
    this.isFastestLap = false,
    this.overallFastestLap = false,
    this.personalFastestLap = false,
    this.inPit = false,
    this.tyreCompound,
    this.tyreAge,
    this.tyreNew,
    this.tyreDataSourceLabel,
    this.speedTrapKmh,
    this.isRetired = false,
    this.numberOfLaps,
    this.totalRaceLaps = _kDefaultRaceTotalLaps,
    this.positionTrend = 0,
    this.gridPosition,
    this.gainLoss = 0,
    this.isOutLap = false,
    this.pitEntryTimestamp,
    this.trackLimitTicks = 0,
    this.gapTrend = 0,
  });

  final int position;
  final String name;
  final String initials;
  final int number;
  final String team;
  final String? lastLap;
  final String gap;
  final String? delta;
  final String? intervalToAhead;
  final bool isFastestLap;
  final bool overallFastestLap;
  final bool personalFastestLap;
  final bool inPit;
  final String? tyreCompound;
  final int? tyreAge;
  /// True = fresh (green dot), False = used (orange dot), null = unknown.
  final bool? tyreNew;
  /// INITIAL LOAD / LIVE UPDATE / UNKNOWN — tyre pipeline debug.
  final String? tyreDataSourceLabel;
  final String? speedTrapKmh;
  final bool isRetired;
  final int? numberOfLaps;
  final int totalRaceLaps;
  /// -1 down, 0 same/new, +1 up (vs previous progress-sorted list).
  final int positionTrend;
  /// Grid position at race start (for gain/loss arrow).
  final int? gridPosition;
  /// Positive = gained, negative = lost positions vs grid. `gridPos - currentPos`.
  final int gainLoss;
  /// True during the first lap after a pit exit.
  final bool isOutLap;
  /// Non-null while driver is currently in pit (for live pit timer).
  final DateTime? pitEntryTimestamp;
  /// Track limit warnings this session.
  final int trackLimitTicks;
  /// +1 gap increasing, -1 decreasing, 0 stable.
  final int gapTrend;
}
