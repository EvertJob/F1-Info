import 'package:flutter/material.dart';

import '../theme/hub_visual_language.dart';

/// PNG logos under [kTeamStandingsLogoRoot].
/// Root `images/` → web URL `/assets/images/constructors/…` (no `assets/assets/`).
///
/// Naming (same folder): `{slug}.png` (dark UI) and `{slug}_dark.png` (light UI), e.g.
/// `mclaren.png` / `mclaren_dark.png`, `red-bull-racing.png` / `red-bull-racing_dark.png`.
/// Slugs below match bundled files: alpine, aston-martin, audi, cadillac, ferrari,
/// haas-f1-team, mclaren, mercedes, racing-bulls, red-bull-racing, williams.
const String kTeamStandingsLogoRoot = 'images/constructors/';

List<String> _constructorLogoFileCandidates(String slug, {required bool darkVariant}) {
  final file = darkVariant ? '${slug}_dark.png' : '$slug.png';
  return [
    '$kTeamStandingsLogoRoot$file',
    'data/images/constructors/$file',
  ];
}

/// 2026 official grid: team display name → asset slug (without `.png` / `_dark.png`).
const Map<String, String> kTeamStandingsLogoSlugByName = {
  'Mercedes': 'mercedes',
  'Ferrari': 'ferrari',
  'McLaren': 'mclaren',
  'Haas F1 Team': 'haas-f1-team',
  'Red Bull Racing': 'red-bull-racing',
  'Racing Bulls': 'racing-bulls',
  'Alpine': 'alpine',
  'Audi': 'audi',
  'Cadillac': 'cadillac',
  'Williams': 'williams',
  'Aston Martin': 'aston-martin',
};

/// Primary brand color: logo tile background (solid), team principal, and points.
const Map<String, Color> kTeamStandingsAccentByName = {
  'Mercedes': Color(0xFF00A19B),
  'Ferrari': Color(0xFFE30010),
  'McLaren': Color(0xFFFF8700),
  'Red Bull Racing': Color(0xFF00103F),
  'Aston Martin': Color(0xFF00352F),
  'Alpine': Color(0xFF0078C1),
  'Williams': Color(0xFF002A54),
  'Racing Bulls': Color(0xFF022F5E),
  'Haas F1 Team': Color(0xFFF21D25),
  'Audi': Color(0xFF000000),
  'Cadillac': Color(0xFF0A0A0A),
};

/// Corner radius for the logo tile.
const double kTeamStandingsLogoTileRadius = 10;

String? teamStandingsLogoAssetPath(String teamName) {
  final slug = kTeamStandingsLogoSlugByName[teamName];
  if (slug == null) return null;
  return '$kTeamStandingsLogoRoot$slug.png';
}

/// Light theme: tries each `{slug}_dark.png` path, then `{slug}.png` paths.
/// Dark theme: `{slug}.png` only.
///
/// Tries [kTeamStandingsLogoRoot] then `data/images/constructors/` (do not use a leading
/// `assets/` key here — on web that becomes `assets/assets/…` and 404s).
/// **New PNGs are not picked up by hot restart** — stop the run, then `flutter pub get`
/// and start again (or `flutter build web`) so AssetManifest updates.
List<String> teamStandingsLogoAssetPathCandidates(
  String teamName, {
  required bool forLightTheme,
}) {
  final slug = kTeamStandingsLogoSlugByName[teamName];
  if (slug == null) return const [];
  if (forLightTheme) {
    return [
      ..._constructorLogoFileCandidates(slug, darkVariant: true),
      ..._constructorLogoFileCandidates(slug, darkVariant: false),
    ];
  }
  return _constructorLogoFileCandidates(slug, darkVariant: false);
}

Color? teamStandingsAccentColor(String teamName) =>
    kTeamStandingsAccentByName[teamName];

/// Same solid color as [teamStandingsAccentColor] (logo tile fill).
Color? teamStandingsLogoBackgroundColor(String teamName) =>
    kTeamStandingsAccentByName[teamName];

/// Primary brand color for a team label from JSON/UI (exact name, casing, or fuzzy).
Color? teamBrandPrimaryColor(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;

  final byKey = teamStandingsAccentColor(s);
  if (byKey != null) return byKey;
  final lower = s.toLowerCase();
  for (final e in kTeamStandingsAccentByName.entries) {
    if (e.key.toLowerCase() == lower) return e.value;
  }

  final n = lower;
  if (n.contains('racing bulls')) {
    return kTeamStandingsAccentByName['Racing Bulls'];
  }
  if (n.contains('red bull')) {
    return kTeamStandingsAccentByName['Red Bull Racing'];
  }
  if (n.contains('haas')) {
    return kTeamStandingsAccentByName['Haas F1 Team'];
  }
  if (n.contains('ferrari')) {
    return kTeamStandingsAccentByName['Ferrari'];
  }
  if (n.contains('mercedes')) {
    return kTeamStandingsAccentByName['Mercedes'];
  }
  if (n.contains('mclaren')) {
    return kTeamStandingsAccentByName['McLaren'];
  }
  if (n.contains('aston')) {
    return kTeamStandingsAccentByName['Aston Martin'];
  }
  if (n.contains('alpine')) {
    return kTeamStandingsAccentByName['Alpine'];
  }
  if (n.contains('williams')) {
    return kTeamStandingsAccentByName['Williams'];
  }
  if (n.contains('audi') || n.contains('sauber')) {
    return kTeamStandingsAccentByName['Audi'];
  }
  if (n.contains('cadillac')) {
    return kTeamStandingsAccentByName['Cadillac'];
  }
  if (n == 'rb' || n.startsWith('rb ') || n.endsWith(' rb') || n.contains(' alphatauri')) {
    return kTeamStandingsAccentByName['Racing Bulls'];
  }

  return null;
}

Color teamBrandPrimaryColorOrF1(String? raw) =>
    teamBrandPrimaryColor(raw) ?? HubVisualLanguage.f1DefaultAccent;
