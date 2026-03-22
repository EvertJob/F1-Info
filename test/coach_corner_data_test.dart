import 'package:f1/coach_corner_data.dart';
import 'package:f1/main.dart' show races;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every calendar race has coach slugs and five lines per locale', () {
    const locales = ['en', 'nl', 'de', 'fr'];
    for (final race in races) {
      expect(
        kRaceNameToCoachSlug[race.name],
        isNotNull,
        reason: 'Add ${race.name} to kRaceNameToCoachSlug',
      );
      final slug = kRaceNameToCoachSlug[race.name]!;
      for (final loc in locales) {
        final lines = coachCornerFiveLines(race.name, loc);
        expect(lines.length, 5, reason: '$slug / $loc');
      }
    }
    expect(kRaceNameToCoachSlug.length, races.length);
  });
}
