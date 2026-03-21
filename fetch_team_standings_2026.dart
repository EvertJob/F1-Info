
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

String? _posChangeString(dynamic start, dynamic finish) {
	if (start is int && finish is int) {
		final diff = finish - start;
		return diff >= 0 ? '+$diff' : '$diff';
	}
	return null;
}

Future<void> main() async {
	// 1. Haal alle sessies op voor 2026
	final sessionsResp = await http.get(Uri.parse('https://api.openf1.org/v1/sessions?year=2026'));
	if (sessionsResp.statusCode != 200) {
		print('Failed to fetch sessions: ${sessionsResp.statusCode}');
		exit(1);
	}
	final sessions = jsonDecode(sessionsResp.body) as List;
	// Groepeer per meeting_key (round)
	final Map<int, List<Map<String, dynamic>>> sessionsByMeeting = {};
	for (final s in sessions) {
		final meetingKey = s['meeting_key'] as int?;
		if (meetingKey == null) continue;
		sessionsByMeeting.putIfAbsent(meetingKey, () => []).add(s as Map<String, dynamic>);
	}

	// Alleen meetings met relevante sessies (Race/Sprint)
	final relevantMeetings = sessionsByMeeting.entries.where((e) => e.value.any((s) => s['session_name'] == 'Race' || s['session_name'] == 'Sprint')).toList();
	relevantMeetings.sort((a, b) => a.key.compareTo(b.key));

	final rounds = <Map<String, dynamic>>[];
	final teamPoints = <String, int>{};
	final teamLastPoints = <String, int>{};

	for (var i = 0; i < relevantMeetings.length; i++) {
		final roundName = (i + 1).toString();
		final teamsForRound = <String, Map<String, dynamic>>{};
		final sessions = relevantMeetings[i].value.where((s) => s['session_name'] == 'Race' || s['session_name'] == 'Sprint').toList();

		for (final session in sessions) {
			final sessionKey = session['session_key'];
			final sessionType = session['session_name'];
			// 2. Championship Teams API
			final teamsUrl = 'https://api.openf1.org/v1/championship_teams?session_key=$sessionKey';
			final teamsResp = await http.get(Uri.parse(teamsUrl));
			print('GET $teamsUrl => status: ${teamsResp.statusCode}');
			await Future.delayed(Duration(seconds: 1));
			if (teamsResp.statusCode != 200) continue;
			final teamsData = jsonDecode(teamsResp.body) as List;
			for (final entry in teamsData) {
				final teamName = entry['team_name'] as String?;
				if (teamName == null) continue;
				final pointsStart = (entry['points_start'] as num?)?.toInt() ?? 0;
				final pointsFinish = (entry['points_current'] as num?)?.toInt() ?? pointsStart;
				final pointsReceived = pointsFinish - pointsStart;
				final posStart = entry['position_start'] as int?;
				final posFinish = entry['position_current'] as int?;
				teamsForRound.putIfAbsent(teamName, () => {});
				(teamsForRound[teamName] ??= {})[sessionType] = {
					'points_start': pointsStart,
					'points_finish': pointsFinish,
					'points_received': pointsReceived,
					'position_start': posStart,
					'position_finish': posFinish,
					'position_changed': (posStart != null && posFinish != null) ? _posChangeString(posStart, posFinish) : null
				};
				teamLastPoints[teamName] = pointsFinish;
				teamPoints[teamName] = pointsFinish;
			}
		}

		rounds.add({
			'round': roundName,
			'teams': teamsForRound,
		});
	}

	// 4. Maak standings array (laatste punten per team)
	final standings = teamPoints.entries
			.map((e) => {'team': e.key, 'points': e.value})
			.toList();
	standings.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

	final output = {
		'standings': standings,
		'rounds': rounds,
	};

	final file = File('data/results/teams/teams_standings_2026.json');
	await file.create(recursive: true);
	await file.writeAsString(JsonEncoder.withIndent('  ').convert(output));
	print('Saved teams standings to data/results/teams/teams_standings_2026.json');
}

