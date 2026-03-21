import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'theme/f1_team_schemes.dart';
import 'theme/f1_theme_tokens.dart';
import 'widgets/f1_module.dart';

/// Sector status from F1 API: 2064 = Overall Best (purple), 2048 = Personal Best (green), else = slower (yellow).
enum SectorStatus { purple, green, yellow }

/// F1 official colors for timing indicators (Silverstone/official broadcast).
const Color _kF1Purple = Color(0xFFB15BE0); // Overall fastest lap/sector
const Color _kF1Green = Color(0xFF00D2BE);  // Personal fastest lap/sector

/// Production URL for the F1 Live Timing proxy (Silverstone replay).
const String kLiveTimingProxyBase = String.fromEnvironment(
  'LIVE_TIMING_PROXY',
  defaultValue: 'https://f1-live-timing-proxy.89wph6ymgg.workers.dev',
);

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

/// Protected Live Timing page. Requires auth; redirects to login if not logged in.
class LiveTimingPage extends StatefulWidget {
  const LiveTimingPage({super.key});

  @override
  State<LiveTimingPage> createState() => _LiveTimingPageState();
}

class _LiveTimingPageState extends State<LiveTimingPage>
    with TickerProviderStateMixin {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _useTestData = true; // Silverstone replay by default
  /// Driver ID -> { position, lastLapTime, gapToLeader, team, ... }
  Map<String, dynamic> _driverStorage = {};
  List<String> _sortedDriverIds = [];
  List<LiveDriverEntry> _leaderboard = [];
  String? _teammateDelta; // Hamilton vs Russell interval (from live data or Position.z)
  /// Sector status: driverNumber -> {sectorIndex: SectorStatus}
  /// 2064 = purple (overall best), 2048 = green (personal best), else = yellow (slower)
  Map<int, Map<int, SectorStatus>> _sectorHighlights = {};
  /// Fastest lap time string for session (e.g. "1:29.834") for purple last-lap styling.
  String? _fastestLapTime;
  String _lastRawData = ''; // For debug footer
  bool _hasLoggedTimingKeys = false; // Debug: log keys only once
  late AnimationController _livePulseController;

  @override
  void initState() {
    super.initState();
    _livePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAuthAndConnect();
  }

  Future<void> _checkAuthAndConnect() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }
    _connect();
  }

  String _wsUrl() {
    final base = kLiveTimingProxyBase;
    final scheme = base.startsWith('https') ? 'wss' : 'ws';
    final host = base
        .replaceFirst('https://', '')
        .replaceFirst('http://', '');
    return '$scheme://$host${_useTestData ? '?test=true' : ''}';
  }

  void _connect() {
    _disconnect();
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

  /// Processes raw WebSocket payload. Handles SignalR formats and heartbeats.
  void _processMessage(dynamic rawData) {
    if (!mounted) return;
    final raw = rawData is String ? rawData : utf8.decode(rawData as List<int>);
    _lastRawData = raw;

    // Stage 1: Raw data received
    if (kDebugMode) {
      print('[LiveTiming] Stage 1: Raw data received, length=${raw.length}, preview=${raw.length > 80 ? raw.substring(0, 80) : raw}');
    }

    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) {
        if (kDebugMode) print('[LiveTiming] Stage 2: jsonDecode ok but root is not Map');
        return;
      }

      // Stage 2: Successful jsonDecode
      if (kDebugMode) print('[LiveTiming] Stage 2: jsonDecode ok, keys=${map.keys.toList()}');

      // Heartbeat: no "A" key or "A" is null/empty (e.g. {"M":"Hello from Cloudflare"})
      final args = map['A'] as List<dynamic>?;

      // Stage 3: Detection of "M" and "A"
      if (map['M'] is List) {
        // Wrapped format: json['M'] (List) -> message['A'] (List)
        // {"M": [{"H":"Streaming","M":"ReceiveMessage","A":["TimingData",{...}]}]}
        if (kDebugMode) print('[LiveTiming] Stage 3: M is List (wrapped format), length=${(map['M'] as List).length}');
        final hubMessages = map['M'] as List<dynamic>;
        for (final hub in hubMessages) {
          if (hub is! Map) continue;
          final hubArgs = hub['A'] as List<dynamic>?;
          if (hubArgs == null || hubArgs.length < 2) {
            if (kDebugMode) print('[LiveTiming] Stage 4: Skipping message - A missing or < 2 elements');
            continue;
          }
          final dataType = hubArgs[0]?.toString();
          final payload = hubArgs[1];
          if (kDebugMode) print('[LiveTiming] Stage 4: dataType=$dataType, payload type=${payload.runtimeType}');
          _dispatchByType(dataType, payload);
        }
        return;
      }

      // Direct format: { H, M:"feed", A:[type, payload, timestamp] }
      if (args == null || args.isEmpty) {
        if (kDebugMode) print('[LiveTiming] Stage 3: Heartbeat or no A - ignoring');
        return;
      }
      if (args.length < 2) {
        if (kDebugMode) print('[LiveTiming] Stage 4: A has < 2 elements - ignoring');
        return;
      }
      final dataType = args[0]?.toString();
      final payload = args[1];
      if (kDebugMode) print('[LiveTiming] Stage 4: Direct format dataType=$dataType');
      _dispatchByType(dataType, payload);
    } catch (e, st) {
      if (kDebugMode) {
        print('[LiveTiming] Parse error: $e');
        print('[LiveTiming] Stack: $st');
      }
    }
  }

  void _dispatchByType(String? dataType, dynamic payload) {
    switch (dataType) {
      case 'TimingData':
        _handleTimingUpdate(payload);
        break;
      case 'Position.z':
        _handlePositionZ(payload);
        break;
      case 'Heartbeat':
        if (mounted) setState(() {});
        break;
      case 'TimingStats':
        break;
      default:
        if (kDebugMode && dataType != null) {
          print('[LiveTiming] Ignoring dataType: $dataType');
        }
    }
  }

  /// Handles TimingData payload: merges Lines into _driverStorage, re-sorts, setState.
  void _handleTimingUpdate(dynamic payload) {
    if (payload is! Map) {
      if (kDebugMode) print('[LiveTiming] _handleTimingUpdate: payload is not Map');
      return;
    }
    final payloadMap = Map<String, dynamic>.from(payload as Map);
    final linesRaw = payloadMap['Lines'];
    final lines = linesRaw is Map
        ? Map<String, dynamic>.from(
            (linesRaw as Map).map((k, v) => MapEntry(k.toString(), v)))
        : null;
    if (lines == null || lines.isEmpty) {
      if (kDebugMode) print('[LiveTiming] _handleTimingUpdate: Lines missing or empty');
      return;
    }
    if (kDebugMode) {
      print('[LiveTiming] _handleTimingUpdate: processing ${lines.length} driver(s)');
      if (!_hasLoggedTimingKeys) {
        _hasLoggedTimingKeys = true;
        final firstLine = lines.values.first;
        if (firstLine is Map) {
          (firstLine as Map).keys.toList().forEach((key) => print('Found Key: $key'));
        }
      }
    }

    final highlights = Map<int, Map<int, SectorStatus>>.from(_sectorHighlights);
    final lapTimes = <String>[];

    for (final entry in lines.entries) {
      final driverId = entry.key.toString();
      final line = entry.value;
      if (line is! Map) continue;

      final lineMap = Map<String, dynamic>.from(line);
      final data = <String, dynamic>{};

      // Only overwrite Position when present; otherwise keep existing (sort uses 999 as fallback)
      final pos = lineMap['Position'];
      if (pos != null) {
        data['Position'] = pos is int ? pos : (int.tryParse(pos.toString()) ?? 999);
      }

      // LastLapTime: support both string and {Value, OverallFastest, PersonalFastest}
      // Smart mapping: BestLapTime often used at start of replay when LastLapTime is empty
      String? lastLapStr;
      bool overallFastest = false;
      bool personalFastest = false;
      final lastLapRaw = lineMap['LastLapTime'];
      if (lastLapRaw != null) {
        if (lastLapRaw is Map) {
          lastLapStr = (lastLapRaw['Value'] ?? lastLapRaw['value'])?.toString();
          overallFastest = lastLapRaw['OverallFastest'] == true || lastLapRaw['overallFastest'] == true;
          personalFastest = lastLapRaw['PersonalFastest'] == true || lastLapRaw['personalFastest'] == true;
        } else {
          lastLapStr = lastLapRaw.toString();
        }
      }
      if ((lastLapStr == null || lastLapStr.isEmpty) && lineMap['BestLapTime'] != null) {
        final bestRaw = lineMap['BestLapTime'];
        if (bestRaw is Map) {
          lastLapStr = (bestRaw['Value'] ?? bestRaw['value'])?.toString();
          overallFastest = overallFastest || bestRaw['OverallFastest'] == true || bestRaw['overallFastest'] == true;
          personalFastest = personalFastest || bestRaw['PersonalFastest'] == true || bestRaw['personalFastest'] == true;
        } else {
          lastLapStr = bestRaw.toString();
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

      final num = int.tryParse(driverId);
      if (num != null) {
        data['number'] = num;
        data['name'] = _driverNames[driverId] ?? 'Driver $driverId';
        data['team'] = _silverstone2024Teams[num] ?? '';
      }

      _driverStorage[driverId] = {
        ...(_driverStorage[driverId] as Map<String, dynamic>? ?? {}),
        ...data,
      };

      // Sectors: try Sectors, BestSectors, CurrentSectors (Silverstone may use any)
      final sectors = (lineMap['Sectors'] ?? lineMap['BestSectors'] ?? lineMap['CurrentSectors']) as Map<String, dynamic>?;
      if (sectors != null && num != null) {
        highlights[num] ??= {};
        // Persistence: merge with existing – only update sectors present in this message
        for (final s in sectors.entries) {
          final sectorIdx = int.tryParse(s.key);
          if (sectorIdx == null || sectorIdx < 0 || sectorIdx > 2) continue;
          highlights[num]![sectorIdx] = _getSectorStatusFromLine(s.key, s.value);
        }
        // Store sectors for persistence – merge into driver storage
        final existingSectors = (_driverStorage[driverId] as Map<String, dynamic>?)?['Sectors'] as Map?;
        final mergedSectors = Map<String, dynamic>.from(existingSectors ?? {});
        for (final e in sectors.entries) {
          mergedSectors[e.key.toString()] = e.value;
        }
        data['Sectors'] = mergedSectors;
        // Merge sectors into storage (data was merged before sectors block)
        final cur = _driverStorage[driverId] as Map<String, dynamic>? ?? {};
        _driverStorage[driverId] = {...cur, 'Sectors': mergedSectors};
      }
    }

    _sectorHighlights = highlights;

    // Fastest lap of session: smallest lap time (parse "M:SS.mmm" or "SS.mmm")
    if (lapTimes.isNotEmpty) {
      String? best;
      for (final t in lapTimes) {
        if (best == null || _lapTimeCompare(t, best) < 0) best = t;
      }
      _fastestLapTime = best;
    }

    // Teammate battle: Hamilton (44) vs Russell (63) - gap difference from live data
    _teammateDelta = _computeTeammateGap();

    _sortedDriverIds = _driverStorage.keys.toList()
      ..sort((a, b) {
        final posA = (_driverStorage[a] as Map?)?['Position'];
        final posB = (_driverStorage[b] as Map?)?['Position'];
        final ia = posA is int ? posA : int.tryParse(posA?.toString() ?? '') ?? 999;
        final ib = posB is int ? posB : int.tryParse(posB?.toString() ?? '') ?? 999;
        return ia.compareTo(ib);
      });

    if (kDebugMode) {
      print('[LiveTiming] _handleTimingUpdate: storage now has ${_driverStorage.length} drivers, sortedIds=${_sortedDriverIds.length}');
    }
    if (mounted) setState(() {});
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
  /// 2064/2048 = Overall Best (purple), 2044 = Personal Best (green).
  static SectorStatus _getSectorStatusFromLine(dynamic sectorKey, dynamic sectorValue) {
    final segs = sectorValue is Map ? (sectorValue as Map)['Segments'] : null;
    if (segs is! Map) return SectorStatus.yellow;
    SectorStatus status = SectorStatus.yellow;
    for (final seg in segs.values) {
      if (seg is Map) {
        final st = seg['Status'];
        final ob = seg['OverallFastest'] == true || seg['overallFastest'] == true;
        final pb = seg['PersonalFastest'] == true || seg['personalFastest'] == true;
        if (st == 2048 || st == 2064 || ob) return SectorStatus.purple;
        if (st == 2044 || pb) status = SectorStatus.green;
      }
    }
    return status;
  }

  /// Hamilton (44) vs Russell (63): gap between them from |GapToLeader[44] - GapToLeader[63]|.
  String? _computeTeammateGap() {
    final h = _driverStorage['44'] as Map<String, dynamic>?;
    final r = _driverStorage['63'] as Map<String, dynamic>?;
    final gh = h?['GapToLeader']?.toString();
    final gr = r?['GapToLeader']?.toString();
    if (gh == null || gr == null || gh == '–' || gr == '–') return null;
    double parse(String s) {
      final n = s.replaceFirst('+', '').trim();
      return double.tryParse(n) ?? 0;
    }
    final diff = (parse(gh) - parse(gr)).abs();
    if (diff < 0.001) return '–';
    return '+${diff.toStringAsFixed(3)}';
  }

  /// Legacy: delegates to _handleTimingUpdate for TimingData.
  void _handleTimingDataFromLines(dynamic data) {
    if (data is! Map) return;
    final lines = data['Lines'] as Map<String, dynamic>?;
    if (lines == null) return;

    final storage = Map<String, dynamic>.from(_driverStorage);
    final highlights = Map<int, Map<int, SectorStatus>>.from(_sectorHighlights);

    for (final e in lines.entries) {
      final driverId = e.key;
      final line = e.value as Map<String, dynamic>?;
      if (line == null) continue;

      storage[driverId] ??= {};
      final driver = storage[driverId] as Map<String, dynamic>;

      final position = line['Position'];
      if (position != null) driver['Position'] = position is int ? position : int.tryParse(position.toString());

      final lastLap = line['LastLapTime'];
      if (lastLap != null) driver['LastLapTime'] = lastLap is Map ? (lastLap['Value'] ?? lastLap['value'])?.toString() ?? lastLap.toString() : lastLap.toString();

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

      // Sector highlights: 2064=purple, 2048=green, else=yellow
      final sectors = line['Sectors'] as Map<String, dynamic>?;
      if (sectors != null && num != null) {
        highlights[num] ??= {};
        for (final s in sectors.entries) {
          final sectorIdx = int.tryParse(s.key);
          if (sectorIdx == null || sectorIdx < 0 || sectorIdx > 2) continue;
          final segs = s.value is Map ? (s.value as Map)['Segments'] : null;
          if (segs is! Map) continue;
          SectorStatus status = SectorStatus.yellow;
          for (final seg in segs.values) {
            if (seg is Map) {
              final st = seg['Status'];
              if (st == 2064) { status = SectorStatus.purple; break; }
              if (st == 2048) status = SectorStatus.green;
            }
          }
          highlights[num]![sectorIdx] = status;
        }
      }
    }

    _driverStorage = storage;
    _sectorHighlights = highlights;

    _sortedDriverIds = storage.keys.toList()
      ..sort((a, b) {
        final posA = (storage[a] as Map?)?['Position'];
        final posB = (storage[b] as Map?)?['Position'];
        final ia = posA is int ? posA : int.tryParse(posA?.toString() ?? '') ?? 999;
        final ib = posB is int ? posB : int.tryParse(posB?.toString() ?? '') ?? 999;
        return ia.compareTo(ib);
      });

    if (mounted) setState(() {});
  }

  void _handleTimingData(dynamic data) {
    if (data is! Map) return;
    final lines = data['Lines'] as Map<String, dynamic>?;
    if (lines == null) return;

    final highlights = Map<int, Map<int, SectorStatus>>.from(_sectorHighlights);

    for (final e in lines.entries) {
      final driverNum = int.tryParse(e.key);
      if (driverNum == null) continue;

      final line = e.value as Map<String, dynamic>?;
      if (line == null) continue;

      final sectors = line['Sectors'] as Map<String, dynamic>?;
      if (sectors == null) continue;

      highlights[driverNum] ??= {};
      for (final s in sectors.entries) {
        final sectorIdx = int.tryParse(s.key);
        if (sectorIdx == null || sectorIdx < 0 || sectorIdx > 2) continue;

        final segs = s.value is Map ? (s.value as Map)['Segments'] : null;
        if (segs is! Map) continue;

        SectorStatus status = SectorStatus.yellow;
        for (final seg in segs.values) {
          if (seg is Map) {
            final st = seg['Status'];
            if (st == 2064) { status = SectorStatus.purple; break; }
            if (st == 2048) status = SectorStatus.green;
          }
        }
        highlights[driverNum]![sectorIdx] = status;
      }
    }

    if (mounted) setState(() => _sectorHighlights = highlights);
  }

  void _handleTimingStats(dynamic data) {
    if (data is! Map) return;
    // TimingStats can contain aggregated data; merge with TimingData if needed
  }

  void _handlePositionZ(dynamic data) {
    if (data is! String) return;
    try {
      final bytes = base64Decode(data);
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

      // Build leaderboard sorted by Position
      final List<LiveDriverEntry> board = [];
      for (final e in entries) {
        final pos = e['Position'] ?? e['position'];
        final num = e['RacingNumber'] ?? e['Number'] ?? e['DriverNo'] ?? e['number'];
        final gap = e['GapToLeader'] ?? e['Gap'] ?? e['gap'];
        final interval = e['IntervalToPositionAhead'] ?? e['Interval'] ?? e['interval'];

        final position = pos is int ? pos : int.tryParse(pos?.toString() ?? '') ?? 0;
        final number = num is int ? num : int.tryParse(num?.toString() ?? '') ?? 0;
        final gapStr = gap?.toString() ?? '–';
        final intervalStr = interval?.toString();

        board.add(LiveDriverEntry(
          position: position,
          name: _silverstone2024Drivers[number] ?? '#$number',
          number: number,
          team: _silverstone2024Teams[number] ?? '',
          lastLap: null,
          gap: gapStr,
          delta: intervalStr,
          intervalToAhead: intervalStr,
        ));
      }
      board.sort((a, b) => a.position.compareTo(b.position));

      // Teammate battle: Hamilton (44) vs Russell (63) - interval between them
      final ham = board.cast<LiveDriverEntry?>().where((d) => d!.number == 44).firstOrNull;
      final rus = board.cast<LiveDriverEntry?>().where((d) => d!.number == 63).firstOrNull;
      String? delta;
      if (ham != null && rus != null) {
        if (ham.position < rus.position) {
          delta = rus.intervalToAhead ?? '+${rus.gap}';
        } else {
          delta = ham.intervalToAhead ?? '+${ham.gap}';
        }
      }

      // Merge Position.z into _driverStorage for UI consistency
      final storage = Map<String, dynamic>.from(_driverStorage);
      for (final e in board) {
        final id = '${e.number}';
        storage[id] ??= {};
        (storage[id] as Map<String, dynamic>).addAll({
          'Position': e.position,
          'GapToLeader': e.gap,
          'name': e.name,
          'team': e.team,
          'number': e.number,
        });
      }
      _driverStorage = storage;
      _sortedDriverIds = storage.keys.toList()
        ..sort((a, b) {
          final posA = (storage[a] as Map?)?['Position'];
          final posB = (storage[b] as Map?)?['Position'];
          final ia = posA is int ? posA : int.tryParse(posA?.toString() ?? '') ?? 999;
          final ib = posB is int ? posB : int.tryParse(posB?.toString() ?? '') ?? 999;
          return ia.compareTo(ib);
        });

      if (mounted) {
        setState(() {
          _leaderboard = board;
          _teammateDelta = _computeTeammateGap() ?? delta;
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
    _disconnect();
    _livePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final tokens = Theme.of(context).extension<F1ThemeTokens>();
    final ambientGlow = primary.withValues(alpha: 0.08);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ambientGlow,
                  scheme.surface,
                  scheme.surface,
                  ambientGlow,
                ],
                stops: const [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, primary),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildTeammateBattleCard(context, primary, tokens),
                      const SizedBox(height: 16),
                      _buildLeaderboardSection(context, primary),
                      const SizedBox(height: 24),
                      if (kDebugMode) _buildTestDataSwitch(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (kDebugMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.black26,
                child: Text(
                  _lastRawData.length > 100
                      ? '${_lastRawData.substring(0, 100)}...'
                      : _lastRawData,
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ),
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
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/circuits'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  't.live_timing_title'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  'Silverstone 2024',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildTeammateBattleCard(
    BuildContext context,
    Color primary,
    F1ThemeTokens? tokens,
  ) {
    return F1Module(
      fillWidth: true,
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      backgroundColor: Colors.white,
      showFadingBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_outlined, size: 16, color: primary),
              const SizedBox(width: 6),
              Text(
                't.live_teammate_battle'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _driverChip(context, 'Hamilton', primary),
              Text(
                _teammateDelta ?? '–',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
              _driverChip(context, 'Russell', primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _driverChip(BuildContext context, String name, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  /// Builds a driver card from _driverStorage data. Bridges storage to UI with sector colors and lap times.
  Widget _buildDriverCard({
    Key? key,
    required LiveDriverEntry entry,
    required Color primary,
    Map<int, SectorStatus>? sectorHighlights,
  }) {
    return _LiveCard(
      key: key,
      entry: entry,
      primary: primary,
      sectorHighlights: sectorHighlights,
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
          't.live_leaderboard'.tr(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (isEmpty)
          F1Module(
            fillWidth: true,
            padding: const EdgeInsets.all(24),
            borderRadius: 20,
            backgroundColor: Colors.white,
            showFadingBorder: true,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Wachten op eerste Silverstone frame...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (hasStorageData)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sortedDriverIds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final id = _sortedDriverIds[index];
              final data = _driverStorage[id] as Map<String, dynamic>? ?? {};
              final number = data['number'] as int? ?? int.tryParse(id) ?? 0;
              final team = data['team'] as String? ?? _silverstone2024Teams[number] ?? '';
              final teamColor = F1TeamSchemes.getTeamColor(team);
              final lastLap = data['LastLapTime'] as String?;
              final overallFastest = data['LastLapOverallFastest'] == true;
              final personalFastest = data['LastLapPersonalFastest'] == true;
              final entry = LiveDriverEntry(
                position: (data['Position'] as int?) ?? int.tryParse(data['Position']?.toString() ?? '') ?? index + 1,
                name: data['name'] as String? ?? _driverNames[id] ?? 'Driver $id',
                number: number,
                team: team,
                lastLap: lastLap,
                gap: (data['GapToLeader'] as String?) ?? '–',
                delta: null,
                intervalToAhead: data['IntervalToPrimary'] as String?,
                isFastestLap: lastLap != null && lastLap == _fastestLapTime,
                overallFastestLap: overallFastest,
                personalFastestLap: personalFastest,
              );
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
              return _buildDriverCard(
                key: ValueKey(id),
                entry: entry,
                primary: teamColor,
                sectorHighlights: sectorHighlights,
              );
            },
          )
        else
          ..._leaderboard.asMap().entries.map((e) {
            final entry = e.value;
            final highlights = _sectorHighlights[entry.number];
            final teamColor = F1TeamSchemes.getTeamColor(entry.team);
            return Padding(
              padding: EdgeInsets.only(bottom: e.key < _leaderboard.length - 1 ? 8 : 0),
              child: _LiveCard(
                entry: entry,
                primary: entry.team.isNotEmpty ? teamColor : primary,
                sectorHighlights: highlights,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTestDataSwitch(BuildContext context) {
    return F1Module(
      fillWidth: true,
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      showFadingBorder: false,
      child: Row(
        children: [
          Text(
            't.live_switch_test'.tr(),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Switch(
            value: _useTestData,
            onChanged: (v) {
              setState(() {
                _useTestData = v;
                _connect();
              });
            },
          ),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({
    super.key,
    required this.entry,
    required this.primary,
    this.sectorHighlights,
  });

  final LiveDriverEntry entry;
  final Color primary;
  final Map<int, SectorStatus>? sectorHighlights;

  @override
  Widget build(BuildContext context) {
    return F1Module(
      fillWidth: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 20,
      backgroundColor: Colors.white,
      showFadingBorder: true,
      borderColor: primary,
      child: Row(
        children: [
          // Left: Position and Driver Name/Team
          SizedBox(
            width: 28,
            child: Text(
              '${entry.position}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.team.isNotEmpty)
                  Text(
                    entry.team,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Center: Sector boxes
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SectorBadge(label: 'S1', status: sectorHighlights?[0] ?? SectorStatus.yellow),
              const SizedBox(width: 4),
              _SectorBadge(label: 'S2', status: sectorHighlights?[1] ?? SectorStatus.yellow),
              const SizedBox(width: 4),
              _SectorBadge(label: 'S3', status: sectorHighlights?[2] ?? SectorStatus.yellow),
            ],
          ),
          const SizedBox(width: 12),
          // Right: Gaps and Last Lap (monospaced)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.gap,
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (entry.intervalToAhead != null)
                Text(
                  entry.intervalToAhead!,
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              Text(
                entry.lastLap ?? '--:--.---',
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: entry.overallFastestLap || entry.isFastestLap
                      ? _kF1Purple
                      : entry.personalFastestLap
                          ? _kF1Green
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectorBadge extends StatelessWidget {
  const _SectorBadge({required this.label, required this.status});

  final String label;
  final SectorStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;
    switch (status) {
      case SectorStatus.purple:
        bg = _kF1Purple.withValues(alpha: 0.25);
        fg = _kF1Purple;
        border = Border.all(color: _kF1Purple, width: 1);
        break;
      case SectorStatus.green:
        bg = _kF1Green.withValues(alpha: 0.25);
        fg = _kF1Green;
        border = Border.all(color: _kF1Green, width: 1);
        break;
      case SectorStatus.yellow:
        bg = Colors.amber.withValues(alpha: 0.2);
        fg = Colors.amber.shade800;
        border = Border.all(color: Colors.amber.shade600, width: 1);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: border,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
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
            color: color.withValues(alpha: opacity * 0.2),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: opacity)),
          ),
          child: Text(
            'LIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: color.withValues(alpha: opacity),
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
    required this.number,
    required this.team,
    this.lastLap,
    required this.gap,
    this.delta,
    this.intervalToAhead,
    this.isFastestLap = false,
    this.overallFastestLap = false,
    this.personalFastestLap = false,
  });

  final int position;
  final String name;
  final int number;
  final String team;
  final String? lastLap;
  final String gap;
  final String? delta;
  final String? intervalToAhead;
  final bool isFastestLap;
  /// From API: LastLapOverallFastest – use F1 Purple when true.
  final bool overallFastestLap;
  /// From API: LastLapPersonalFastest – use F1 Green when true.
  final bool personalFastestLap;
}
