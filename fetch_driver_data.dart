import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

const String apiBase = 'https://api.jolpi.ca/ergast/f1';
const String outputPath = './assets/data/drivers';

Future<void> main() async {
  // CRUCIAL: Gebruik 'max_verstappen' om Jos te negeren
  final String driverId = 'max_verstappen'; 
  final String wikiSearch = 'Max Verstappen';

  print('🏎️ Schoonmaken van data voor $driverId...');

  try {
    // 1. Wikipedia Records (Met betere opschoning)
    final wikiRecords = await fetchWikiRecords(wikiSearch);

    // 2. API Data
    final response = await http.get(Uri.parse('$apiBase/drivers/$driverId/results.json?limit=1000'));
    final races = jsonDecode(response.body)['MRData']['RaceTable']['Races'] as List;

    int wins = 0, podiums = 0, poles = 0, fl = 0, ht = 0, dnf = 0;
    final Map<String, List<Map<String, dynamic>>> retirements = {};

    for (var race in races) {
      final result = race['Results'][0];
      final status = result['status'] as String;
      final int pos = int.tryParse(result['positionText'] ?? result['position']) ?? 99;
      final int grid = int.tryParse(result['grid']) ?? 0;
      final bool isFL = result['FastestLap']?['rank'] == "1";

      if (pos == 1) wins++;
      if (pos <= 3) podiums++;
      if (grid == 1) poles++;
      if (isFL) fl++;
      if (pos == 1 && grid == 1 && isFL) ht++;

      if (!status.contains('Finished') && !status.contains('Lap')) {
        dnf++;
        final year = race['season'];
        retirements.putIfAbsent(year, () => []);
        retirements[year]!.add({
          "grandPrix": race['raceName'],
          "reason": status,
          "lap": result['laps']
        });
      }
    }

    // 3. De finale JSON constructie
    final finalJson = {
      "driver": {
        "id": "verstappen", // We houden 'verstappen' als ID voor je app-logica
        "firstName": "Max",
        "lastName": "Verstappen",
        "careerStats": {
          "entries": races.length,
          "wins": wins,
          "podiums": podiums,
          "polePositions": poles,
          "fastestLaps": fl,
          "hatTricks": ht
        },
        "experienceStats": {
          "retirements": dnf,
          "retirementsList": retirements
        },
        "historicalRecords": wikiRecords,
        "lastUpdate": DateTime.now().toIso8601String()
      }
    };

    final file = File('$outputPath/verstappen.json');
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(finalJson));
    print('✅ SUCCESS! Max zijn data is nu gescheiden van Jos.');

  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<List<Map<String, String>>> fetchWikiRecords(String name) async {
  final res = await http.get(Uri.parse('https://en.wikipedia.org/w/api.php?action=parse&page=List_of_Formula_One_driver_records&format=json&prop=text'));
  final doc = parse(jsonDecode(res.body)['parse']['text']['*']);
  final List<Map<String, String>> results = [];

  for (var table in doc.querySelectorAll('table.wikitable')) {
    for (var row in table.querySelectorAll('tr')) {
      if (row.text.contains(name)) {
        final cells = row.querySelectorAll('td');
        if (cells.length >= 4) {
          // Schoonmaken van CSS troep en Wiki-links
          String age = cells[2].text.trim().replaceAll(RegExp(r'\.mw-parser-output.*\{.*\}'), '').trim();
          age = age.replaceAll(RegExp(r'\[.*?\]'), '');
          
          results.add({
            "title": "Historical Record",
            "age": age,
            "achievedAt": cells[3].text.trim().replaceAll(RegExp(r'\[.*?\]'), '')
          });
        }
      }
    }
  }
  return results;
}