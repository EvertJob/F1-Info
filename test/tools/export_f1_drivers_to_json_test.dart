// One-shot export: schrijft assets/data/drivers/{slug}.json uit [driversData].
//
// Draai vanaf de repo-root:
//   flutter test test/tools/export_f1_drivers_to_json_test.dart --name exportDriversToJson
//
// (Gebruikt de Flutter-testomgeving zodat package:f1/main.dart compileert.)

import 'dart:convert';
import 'dart:io';

import 'package:f1/main.dart' show Driver, driversData;
import 'package:flutter_test/flutter_test.dart';

String _slugify(String value) {
  final slug = value
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-{2,}'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return slug.isEmpty ? 'item' : slug;
}

Map<String, dynamic> _driverRecordToJson(Driver d) => {
      'name': d.name,
      'flag': d.flag,
      'points': d.points,
      'number': d.number,
      'nationality': d.nationality,
      'team': d.team,
      'points_finish_pct': d.pointsFinishPct,
      'season_points_finish_pct': d.seasonPointsFinishPct,
      'wins': d.wins,
      'podiums_2nd': d.podiums2nd,
      'podiums_3rd': d.podiums3rd,
      'podiums': d.podiums,
      'poles': d.poles,
      'fastest_laps': d.fastestLaps,
      'total_points': d.totalPoints,
      'championships': d.championships,
      'championship_years': d.championshipYears,
      'laps_raced': d.lapsRaced,
      'starts': d.starts,
      'dnfs': d.dnfs,
      'dsqs': d.dsqs,
      'dnqs': d.dnqs,
      'laps_led': d.lapsLed,
      'front_row_starts': d.frontRowStarts,
      'highest_finish': d.highestFinish,
      'highest_grid': d.highestGrid,
      'hat_tricks': d.hatTricks,
      'overtakes': d.overtakes,
      'age': d.age,
      'height': d.height,
      'birth_place': d.birthPlace,
      'partner': d.partner,
      'children': d.children,
      'pets': d.pets,
      'manager': d.manager,
      'real_world_facts_en': d.realWorldFactsEn,
      'real_world_facts_nl': d.realWorldFactsNl,
      'points_per_season': d.pointsPerSeason.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'debut_year': d.debutYear,
      'contract_until': d.contractUntil,
      'previous_teams': d.previousTeams,
      'personal_sponsors': d.personalSponsors,
      'reserve_driver': d.reserveDriver,
    };

String _fileSlugForDriver(Driver d, Map<String, String> baseSlugOwner) {
  final base = _slugify(d.name);
  final owner = baseSlugOwner[base];
  if (owner == null) {
    baseSlugOwner[base] = d.name;
    return base;
  }
  if (owner == d.name) {
    return base;
  }
  final disambig = '${base}_${d.number}';
  // ignore: avoid_print
  print(
    'Slug collision: base "$base" used by "$owner" and "${d.name}" — '
    'writing latter as "$disambig".',
  );
  return disambig;
}

void main() {
  test('exportDriversToJson', () {
    final projectRoot = _findProjectRoot();
    final outDir = Directory.fromUri(
      projectRoot.uri.resolve('assets/data/drivers/'),
    );
    outDir.createSync(recursive: true);

    final bySlug = <String, List<Map<String, dynamic>>>{};
    final baseSlugOwner = <String, String>{};

    final years = driversData.keys.toList()..sort();

    for (final year in years) {
      final list = driversData[year];
      if (list == null) continue;
      for (final driver in list) {
        final fileSlug = _fileSlugForDriver(driver, baseSlugOwner);
        bySlug.putIfAbsent(fileSlug, () => []);
        bySlug[fileSlug]!.add({
          'season_year': year,
          'record': _driverRecordToJson(driver),
        });
      }
    }

    const encoder = JsonEncoder.withIndent('  ');

    for (final entry in bySlug.entries) {
      final seasons = entry.value
        ..sort(
          (a, b) =>
              (a['season_year'] as int).compareTo(b['season_year'] as int),
        );
      final driverName =
          (seasons.last['record'] as Map<String, dynamic>)['name'] as String;

      final doc = <String, dynamic>{
        'schema': 'f1_hub_driver_export_v1',
        'slug': entry.key,
        'driver_name': driverName,
        'source': 'lib/f1_data.dart → driversData',
        'seasons': seasons,
      };

      final file = File.fromUri(outDir.uri.resolve('${entry.key}.json'));
      file.writeAsStringSync('${encoder.convert(doc)}\n');
    }

    // ignore: avoid_print
    print('Wrote ${bySlug.length} files to ${outDir.path}');
    expect(bySlug, isNotEmpty);
  });
}

/// Zoekt map met pubspec.yaml omhoog vanaf de test working directory.
Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 12; i++) {
    if (File.fromUri(dir.uri.resolve('pubspec.yaml')).existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('pubspec.yaml niet gevonden vanaf ${Directory.current.path}');
}
