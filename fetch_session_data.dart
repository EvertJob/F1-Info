import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

const String _baseUrl = 'https://api.openf1.org/v1';

const Map<String, String> _sessionNameMap = {
  'fp1': 'Practice 1', 'fp2': 'Practice 2', 'fp3': 'Practice 3',
  'q': 'Qualifying', 'qs': 'Sprint Shootout', 's': 'Sprint', 'race': 'Race'
};

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('year', help: 'Jaar of range (bijv. 2026 of 2020-2025)')
    ..addOption('round', help: 'Specifieke ronde')
    ..addOption('session', help: 'fp1, fp2, fp3, q, qs, s, race')
    ..addOption('data', help: 'results, weather, race_control')
    ..addFlag('drivers', help: 'Update uitsluitend drivers standings', negatable: false)
    ..addFlag('constructors', help: 'Update uitsluitend constructors standings', negatable: false);

  final argResults = parser.parse(arguments);
  final String yearArg = argResults['year'] ?? DateTime.now().year.toString();
  
  // Bereken de lijst van jaren (ondersteunt 2020-2025)
  List<String> yearsToFetch = [];
  if (yearArg.contains('-')) {
    var parts = yearArg.split('-');
    int start = int.parse(parts[0]);
    int end = int.parse(parts[1]);
    for (var y = start; y <= end; y++) yearsToFetch.add(y.toString());
  } else {
    yearsToFetch.add(yearArg);
  }

  final client = http.Client();
  stdout.writeln('\x1B[2J\x1B[H');
  stdout.writeln('🏎️  F1 HUB DATA SYNC TOOL');
  stdout.writeln('==================================================');

  for (var currentYear in yearsToFetch) {
    stdout.writeln('\n📅 START VERWERKING JAAR: $currentYear');
    try {
      await _processYear(client, currentYear, argResults);
    } catch (e) {
      stderr.writeln('❌ Kritieke fout in jaar $currentYear: $e');
      // Ga door naar het volgende jaar
    }
  }

  client.close();
  stdout.writeln('\n🏁 ALLE JAAR-RANGES VOLTOOID.');
}

Future<void> _processYear(http.Client client, String year, ArgResults flags) async {
  final int? targetRound = flags['round'] != null ? int.tryParse(flags['round']!) : null;
  final String? sessionFlag = flags['session'];
  final String? dataFlag = flags['data'];
  final bool onlyDrivers = flags['drivers'] as bool;
  final bool onlyConstructors = flags['constructors'] as bool;
  final String? targetSessionName = sessionFlag != null ? _sessionNameMap[sessionFlag.toLowerCase()] : null;

  if (onlyDrivers || onlyConstructors) {
    await _buildAndSaveStandings(client, year, doDrivers: onlyDrivers || !onlyConstructors, doConstructors: onlyConstructors || !onlyDrivers);
    return;
  }

  final meetings = await _fetchChampionshipMeetings(client, year);
  if (meetings.isEmpty) {
    stdout.writeln('⚠️ Geen data gevonden voor $year, wordt overgeslagen.');
    return;
  }

  for (int i = 0; i < meetings.length; i++) {
    final int currentRound = i + 1;
    if (targetRound != null && currentRound != targetRound) continue;

    final mKey = meetings[i]['meeting_key'];
    final circuitName = _sanitizeName(meetings[i]['circuit_short_name']);
    final sessions = await _fetchList(client, '$_baseUrl/sessions?meeting_key=$mKey', 'Ronde $currentRound sessions');

    for (var session in sessions) {
      final String sessionName = session['session_name'];
      final int sessionKey = session['session_key'];
      if (DateTime.parse(session['date_end']).isAfter(DateTime.now())) continue;
      if (targetSessionName != null && sessionName != targetSessionName) continue;

      stdout.writeln('\n📂 Ronde $currentRound | $circuitName - $sessionName');
      final driversMap = await _buildDriverLookup(client, sessionKey);
      final dir = Directory('assets/data/$year/$circuitName');
      if (!await dir.exists()) await dir.create(recursive: true);

      final safeName = _sanitizeName(sessionName);
      if (dataFlag == null || dataFlag == 'race_control') await _fetchAndSaveRaceControl(client, dir.path, safeName, sessionKey);
      if (dataFlag == null || dataFlag == 'weather') await _fetchAndSaveWeather(client, dir.path, safeName, sessionKey);
      if (dataFlag == null || dataFlag == 'results') await _fetchAndSaveResults(client, dir.path, safeName, sessionKey, driversMap);
    }
  }

  // Standen altijd updaten na een volledig jaar
  await _buildAndSaveStandings(client, year, doDrivers: true, doConstructors: true);
}

// --- STANDEN GENERATOR (INCLUSIEF TEAMNAAM) ---
Future<void> _buildAndSaveStandings(http.Client client, String year, {required bool doDrivers, required bool doConstructors}) async {
  final meetings = await _fetchChampionshipMeetings(client, year);
  Map<String, double> dPoints = {};
  Map<String, String> dTeamMap = {}; // Koppelt rijder aan hun laatste team
  Map<String, double> tPoints = {};
  List<Map<String, dynamic>> dRounds = [];
  List<Map<String, dynamic>> tRounds = [];

  for (int i = 0; i < meetings.length; i++) {
    final roundNum = i + 1;
    final sessions = await _fetchList(client, '$_baseUrl/sessions?meeting_key=${meetings[i]['meeting_key']}', 'Standen berekenen: Ronde $roundNum');
    
    var scoring = sessions.where((s) => s['session_name'] == 'Sprint' || s['session_name'] == 'Race').toList();
    Map<String, Map<String, dynamic>> rDriver = {};
    Map<String, Map<String, dynamic>> rTeam = {};

    for (var sess in scoring) {
      if (DateTime.parse(sess['date_end']).isAfter(DateTime.now())) continue;
      final results = await _fetchList(client, '$_baseUrl/session_result?session_key=${sess['session_key']}', '   > Punten scan');
      if (results.isEmpty) continue;

      final dLookup = await _buildDriverLookup(client, sess['session_key']);
      for (var res in results) {
        final dNum = res['driver_number'];
        if (dNum == null) continue;
        final dName = dLookup[dNum]?['full_name'] ?? 'Unknown';
        final tName = dLookup[dNum]?['team_name'] ?? 'Unknown';
        final pts = (res['points'] ?? 0.0).toDouble();

        if (doDrivers) {
          dPoints[dName] = (dPoints[dName] ?? 0.0) + pts;
          dTeamMap[dName] = tName; // Update team naar meest recente
          rDriver.putIfAbsent(dName, () => {})[sess['session_name']] = { "points_received": pts, "position_finish": res['position'] };
        }
        if (doConstructors) {
          tPoints[tName] = (tPoints[tName] ?? 0.0) + pts;
          rTeam.putIfAbsent(tName, () => {})[sess['session_name']] = { "points_received": pts };
        }
      }
    }
    if (rDriver.isNotEmpty) dRounds.add({"round": roundNum.toString(), "drivers": rDriver});
    if (rTeam.isNotEmpty) tRounds.add({"round": roundNum.toString(), "teams": rTeam});
  }

  final path = 'assets/data/$year';
  if (doDrivers) {
    var list = dPoints.entries.map((e) => {"driver": e.key, "team": dTeamMap[e.key] ?? "Unknown", "points": e.value}).toList();
    list.sort((a, b) => (b['points'] as num).compareTo(a['points'] as num));
    await _writeJsonFile(path, 'drivers_standings_$year.json', {"standings": list, "rounds": dRounds});
  }
  if (doConstructors) {
    var list = tPoints.entries.map((e) => {"team": e.key, "points": e.value}).toList();
    list.sort((a, b) => (b['points'] as num).compareTo(a['points'] as num));
    await _writeJsonFile(path, 'teams_standings_$year.json', {"standings": list, "rounds": tRounds});
  }
}

// --- VEILIGE API FETCHER ---
Future<List<dynamic>> _fetchList(http.Client client, String url, [String? message]) async {
  if (message != null) stdout.write('⏳ $message...');
  await Future.delayed(const Duration(seconds: 2)); // Rate limit 2s

  try {
    final response = await client.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      stdout.write(' [OK]\r');
      return (decoded is List) ? decoded : [];
    } else {
      stdout.writeln(' [FAIL: ${response.statusCode}]');
      return [];
    }
  } catch (e) {
    stdout.writeln(' [ERROR: $e]');
    return [];
  }
}

// --- OVERIGE HELPERS ---
Future<void> _fetchAndSaveRaceControl(http.Client client, String dir, String sess, int key) async {
  final data = await _fetchList(client, '$_baseUrl/race_control?session_key=$key', '   > Race Control');
  if (data.isNotEmpty) await _writeJsonFile(dir, '${sess}_race_control.json', {'sessionKey': key, 'messages': data});
}

Future<void> _fetchAndSaveWeather(http.Client client, String dir, String sess, int key) async {
  final data = await _fetchList(client, '$_baseUrl/weather?session_key=$key', '   > Weerdata');
  if (data.isNotEmpty) await _writeJsonFile(dir, '${sess}_weather.json', {'sessionKey': key, 'samples': data});
}

Future<void> _fetchAndSaveResults(http.Client client, String dir, String sess, int key, Map<int, Map<String, dynamic>> lookup) async {
  final res = await _fetchList(client, '$_baseUrl/session_result?session_key=$key', '   > Resultaten');
  if (res.isEmpty) return;
  final stints = await _fetchList(client, '$_baseUrl/stints?session_key=$key', '   > Banden');
  final pits = await _fetchList(client, '$_baseUrl/pit?session_key=$key', '   > Pits');

  List<Map<String, dynamic>> enriched = res.map((r) {
    final d = r['driver_number'];
    return {
      'driverNumber': d, 'broadcastName': lookup[d]?['broadcast_name'] ?? '??', 'teamName': lookup[d]?['team_name'] ?? '??',
      'finishPosition': r['position'], 'points': r['points'] ?? 0,
      // Voor weekend hub: verschil t.o.v. leider (OpenF1 session_result).
      if (r['gap_to_leader'] != null) 'gap_to_leader': r['gap_to_leader'],
      'tyreStints': stints.where((s) => s['driver_number'] == d).map((s) => {'compound': s['compound'], 'lapStart': s['lap_start'], 'lapEnd': s['lap_end']}).toList(),
      'pitStops': pits.where((p) => p['driver_number'] == d).map((p) => {'lap': p['lap_number'], 'duration': p['pit_duration']}).toList()
    };
  }).toList();
  await _writeJsonFile(dir, '${sess}_results.json', {'sessionKey': key, 'results': enriched});
}

Future<List<dynamic>> _fetchChampionshipMeetings(http.Client client, String year) async {
  final raw = await _fetchList(client, '$_baseUrl/meetings?year=$year', 'Kalender $year');
  return raw.where((m) => !(m['meeting_name'] ?? '').toString().toLowerCase().contains('test')).toList()..sort((a, b) => DateTime.parse(a['date_start']).compareTo(DateTime.parse(b['date_start'])));
}

Future<Map<int, Map<String, dynamic>>> _buildDriverLookup(http.Client client, int key) async {
  final data = await _fetchList(client, '$_baseUrl/drivers?session_key=$key', 'Driver Map');
  return {for (var d in data) if (d['driver_number'] != null) d['driver_number']: d};
}

Future<void> _writeJsonFile(String dir, String name, Object data) async {
  final f = File('$dir/$name');
  if (!await f.parent.exists()) await f.parent.create(recursive: true);
  await f.writeAsString(JsonEncoder.withIndent('  ').convert(data));
}

String _sanitizeName(String? n) => (n ?? 'unknown').toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');