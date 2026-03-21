import 'dart:convert';
import 'dart:io';

/// Splits driver_comparison_stats_2017_2025.json into per-year files in data/results/drivers/
Future<void> main() async {
  final input = File('data/results/driver_comparison_stats_2017_2025.json');
  if (!await input.exists()) {
    print('Input file not found');
    exit(1);
  }

  final decoded = jsonDecode(await input.readAsString()) as Map<String, dynamic>;
  final years = decoded['years'] as Map<String, dynamic>? ?? {};
  final outputDir = Directory('data/results/drivers');
  await outputDir.create(recursive: true);

  for (final entry in years.entries) {
    final year = entry.key;
    final yearData = entry.value as Map<String, dynamic>;
    final output = {
      'year': int.tryParse(year) ?? year,
      'available': yearData['available'] ?? true,
      'drivers': yearData['drivers'] ?? {},
      if (yearData.containsKey('teams')) 'teams': yearData['teams'],
    };
    final file = File('data/results/drivers/driver_comparison_stats_$year.json');
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(output));
    print('Written ${file.path}');
  }
  print('Done. Split ${years.length} years.');
}
