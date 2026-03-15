import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const int first2026MeetingKey = 1280;
  const int latestMeetingKey = 1400;

  // Fetch all meetings for 2026
  final meetingsResp = await http.get(Uri.parse('https://api.openf1.org/v1/meetings?year=2026'));
  if (meetingsResp.statusCode != 200) {
    print('Failed to fetch meetings: ${meetingsResp.statusCode}');
    exit(1);
  }
  final meetings = jsonDecode(meetingsResp.body) as List;
  final meetingKeys = meetings
      .map((m) => m['meeting_key'] as int)
      .where((k) => k >= first2026MeetingKey && k <= latestMeetingKey)
      .toList();
  print('Meetings found: ${meetingKeys.length}');

  // For each meeting, fetch the drivers championship standings
  List<Map<String, dynamic>> allEvents = [];
  for (final meetingKey in meetingKeys) {
    print('Fetching standings for meeting_key=$meetingKey');
    final standingsResp = await http.get(Uri.parse('https://api.openf1.org/v1/championship_drivers?meeting_key=$meetingKey'));
    if (standingsResp.statusCode != 200) {
      print('  Failed to fetch for meeting_key=$meetingKey');
      continue;
    }
    final standings = jsonDecode(standingsResp.body) as List;
    if (standings.isNotEmpty) {
      allEvents.add({
        'meeting_key': meetingKey,
        'standings': standings,
      });
      print('  Added ${standings.length} driver entries');
    }
  }

  // Save to file in a simple format for the driver chart
  final file = File('data/results/drivers_standings_2026.json');
  await file.create(recursive: true);
  await file.writeAsString(JsonEncoder.withIndent('  ').convert(allEvents));
  print('Saved drivers standings to data/results/drivers_standings_2026.json');
}
