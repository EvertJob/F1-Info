import '../utils/driver_name_utils.dart';

/// Root `images/` → web `/assets/images/cars/…`.
const String kTeamCarImageRoot = 'images/cars/';

List<String> _teamCarFileCandidates(String base, {required bool darkVariant}) {
  final file = darkVariant ? '${base}_dark.png' : '$base.png';
  return [
    '$kTeamCarImageRoot$file',
    'data/images/cars/$file',
  ];
}

/// PNG stem (lowercase, no spaces) → matches files like `mercedes-2026.png`.
const Map<String, String> kTeamCarImageStemByName = {
  'Mercedes': 'mercedes',
  'Ferrari': 'ferrari',
  'McLaren': 'mclaren',
  'Red Bull Racing': 'redbullracing',
  'Aston Martin': 'astonmartin',
  'Alpine': 'alpine',
  'Williams': 'williams',
  'Racing Bulls': 'racingbulls',
  'Haas F1 Team': 'haas',
  'Audi': 'audi',
  'Cadillac': 'cadillac',
};

/// Stem for `{stem}-2026.png` under [kTeamCarImageRoot] or data override paths.
String teamCarImageStem(String teamName) {
  return kTeamCarImageStemByName[teamName] ??
      slugifyForHubUrl(teamName).replaceAll('-', '');
}

/// Local car on team detail: `images/cars/{stem}-2026.png` (project root; web → `/assets/images/cars/…`).
///
/// Stems match bundled assets (e.g. `redbullracing-2026.png`, `astonmartin-2026.png`).
/// Unknown names: kebab URL slug with hyphens removed, e.g. `foo-bar` → `foobar-2026.png`.
String teamCarImageAssetPath(String teamName) {
  final stem = teamCarImageStem(teamName);
  return '$kTeamCarImageRoot$stem-2026.png';
}

/// Light theme: `{stem}-2026_dark.png` first (parallel to `{slug}_dark.png` for logos).
/// Dark theme: `{stem}-2026.png` only.
///
/// [kTeamCarImageRoot] before `data/images/cars/`.
List<String> teamCarImageAssetPathCandidates(
  String teamName, {
  required bool forLightTheme,
}) {
  final stem = teamCarImageStem(teamName);
  const year = '2026';
  final base = '$stem-$year';
  if (forLightTheme) {
    return [
      ..._teamCarFileCandidates(base, darkVariant: true),
      ..._teamCarFileCandidates(base, darkVariant: false),
    ];
  }
  return _teamCarFileCandidates(base, darkVariant: false);
}
