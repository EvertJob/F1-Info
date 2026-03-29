import 'package:flutter/services.dart'
    show AssetBundle, AssetManifest, rootBundle;

import '../utils/driver_name_utils.dart' show driverJsonSlugCandidates;

/// Resolves bundled OpenF1 JSON paths: `assets/data/{year}/{venue}/{session}_{kind}.json`.
///
/// Venue folder names follow OpenF1 `circuit_short_name` sanitization (see `fetch_session_data.dart`).
/// [circuitAssetId] values come from [Race.circuitAssetId] in `f1_data.dart`.
abstract final class F1AssetResolver {
  F1AssetResolver._();

  /// Championship round → OpenF1 venue folder (1-based round index).
  /// Kept in sync with `races` order in `lib/f1_data.dart` for [year].
  static const Map<int, List<String>> kVenueOrderByYear = {
    /// Same round order as the 2026 list for bundled `assets/data/{year}/{venue}/` lookups
    /// when `Race.circuitAssetId` is empty. Adjust if a season’s calendar diverges.
    2025: [
      'melbourne',
      'shanghai',
      'suzuka',
      'sakhir',
      'jeddah',
      'miami',
      'montreal',
      'monaco',
      'barcelona',
      'spielberg',
      'silverstone',
      'spa',
      'budapest',
      'zandvoort',
      'monza',
      'madrid',
      'baku',
      'singapore',
      'austin',
      'mexico_city',
      'sao_paulo',
      'las_vegas',
      'lusail',
      'yas_marina',
    ],
    2026: [
      'melbourne',
      'shanghai',
      'suzuka',
      'sakhir',
      'jeddah',
      'miami',
      'montreal',
      'monaco',
      'barcelona',
      'spielberg',
      'silverstone',
      'spa',
      'budapest',
      'zandvoort',
      'monza',
      'madrid',
      'baku',
      'singapore',
      'austin',
      'mexico_city',
      'sao_paulo',
      'las_vegas',
      'lusail',
      'yas_marina',
    ],
  };

  /// OpenF1-style folder names first (see [fetch_session_data] `_sanitizeName`), then
  /// legacy short names still present on disk. [venueFolderCandidates] merges a token
  /// with its group so both `spafrancorchamps` and `spa` resolve the same search order.
  static const List<List<String>> kVenueFolderAliasGroups = [
    ['spafrancorchamps', 'spa_francorchamps', 'spa'],
    ['hungaroring', 'budapest'],
    ['catalunya', 'barcelona_catalunya', 'barcelona'],
    ['monte_carlo', 'monaco'],
    ['interlagos', 'sao_paulo'],
    ['yas_marina_circuit', 'yas_marina'],
  ];

  /// Maps hub [circuitAssetId] to **preferred** bundle folder under `assets/data/{year}/`
  /// (OpenF1 sanitization where it differs from older short folders).
  ///
  /// Legacy slugs such as `spa` / `budapest` are still reachable via [venueFolderCandidates]
  /// and [kVenueOrderByYear] round fallback.
  static const Map<String, String> kCircuitAssetIdToVenueFolder = {
    'albert_park': 'melbourne',
    'shanghai_international': 'shanghai',
    'suzuka_circuit': 'suzuka',
    'bahrain_international': 'sakhir',
    'jeddah_corniche': 'jeddah',
    'miami_autodrome': 'miami',
    'gilles_villeneuve': 'montreal',
    'circuit_de_monaco': 'monte_carlo',
    'circuit_barcelona_catalunya': 'catalunya',
    'red_bull_ring': 'spielberg',
    'silverstone_circuit': 'silverstone',
    'spa_francorchamps': 'spafrancorchamps',
    'hungaroring': 'hungaroring',
    'circuit_zandvoort': 'zandvoort',
    'monza_circuit': 'monza',
    'madrid_madring': 'madrid',
    'baku_city_circuit': 'baku',
    'marina_bay_circuit': 'singapore',
    'circuit_of_the_americas': 'austin',
    'hermanos_rodriguez': 'mexico_city',
    'interlagos_circuit': 'interlagos',
    'las_vegas_strip': 'las_vegas',
    'lusail_circuit': 'lusail',
    'yas_marina': 'yas_marina_circuit',
  };

  /// Sakhir-style weekends use `day_N_*` instead of `race_*` in some bundles.
  static const Set<String> kVenuesWithDayNumberedSessions = {'sakhir'};

  static String? venueFolderForCircuitAssetId(String circuitAssetId) {
    if (circuitAssetId.isEmpty) return null;
    return kCircuitAssetIdToVenueFolder[circuitAssetId];
  }

  static String? venueFolderForYearAndRound(int year, int round) {
    if (round < 1) return null;
    final order = kVenueOrderByYear[year];
    if (order == null || round > order.length) return null;
    return order[round - 1];
  }

  /// Ordered folder names to probe on disk for [folderToken] (any alias from a group).
  static List<String> venueFolderCandidates(String folderToken) {
    final key = folderToken.trim().toLowerCase();
    if (key.isEmpty) return const [];
    for (final group in kVenueFolderAliasGroups) {
      for (final g in group) {
        if (g == key) {
          return List<String>.from(group);
        }
      }
    }
    return <String>[key];
  }

  /// Stable `/weekendhub/{slug}` segment (short names) for shareable URLs.
  static String weekendHubPathSlug(String folderToken) {
    final c = folderToken.trim().toLowerCase();
    if (c == 'spafrancorchamps' || c == 'spa_francorchamps' || c == 'spa') {
      return 'spa';
    }
    if (c == 'hungaroring' || c == 'budapest') {
      return 'budapest';
    }
    if (c == 'catalunya' || c == 'barcelona_catalunya' || c == 'barcelona') {
      return 'barcelona';
    }
    if (c == 'monte_carlo' || c == 'monaco') {
      return 'monaco';
    }
    if (c == 'interlagos' || c == 'sao_paulo') {
      return 'sao_paulo';
    }
    if (c == 'yas_marina_circuit' || c == 'yas_marina') {
      return 'yas_marina';
    }
    return c;
  }

  /// Whether [slug] (path or alias) refers to the same venue as [canonicalVenueFolder]
  /// from [venueFolderForCircuitAssetId] / [venueFolderForYearAndRound].
  static bool weekendHubSlugMatches(String slug, String canonicalVenueFolder) {
    final s = slug.trim().toLowerCase();
    if (s.isEmpty) return false;
    final canon = canonicalVenueFolder.trim().toLowerCase();
    if (s == canon) return true;
    if (s == weekendHubPathSlug(canon)) return true;
    for (final c in venueFolderCandidates(canon)) {
      if (s == c) return true;
      if (s == weekendHubPathSlug(c)) return true;
    }
    return false;
  }

  /// Unique folder names to search for modular JSON, circuit mapping first, then round.
  static List<String> expandedVenueFoldersForRace({
    required String circuitAssetId,
    required int year,
    required int round,
  }) {
    final seen = <String>{};
    final out = <String>[];
    void addTok(String? t) {
      if (t == null || t.isEmpty) return;
      for (final c in venueFolderCandidates(t)) {
        if (seen.add(c)) {
          out.add(c);
        }
      }
    }

    addTok(venueFolderForCircuitAssetId(circuitAssetId));
    addTok(venueFolderForYearAndRound(year, round));
    return out;
  }

  /// True if any obvious session results JSON exists for this year/folder.
  static Future<bool> bundledVenueHasProbeResults({
    required AssetBundle bundle,
    required int year,
    required String venueFolder,
  }) async {
    if (kVenuesWithDayNumberedSessions.contains(venueFolder)) {
      for (final stem in ['day_3', 'day_2', 'race', 'day_1']) {
        final p = sessionAssetPath(
          year: year,
          venueFolder: venueFolder,
          sessionStem: stem,
          suffix: 'results',
        );
        if (await bundleHasAsset(bundle, p)) {
          return true;
        }
      }
      return false;
    }
    for (final stem in ['race', 'practice_1', 'qualifying']) {
      final p = sessionAssetPath(
        year: year,
        venueFolder: venueFolder,
        sessionStem: stem,
        suffix: 'results',
      );
      if (await bundleHasAsset(bundle, p)) {
        return true;
      }
    }
    return false;
  }

  /// First folder under `assets/data/{year}/` that has bundled session results, or null.
  static Future<String?> resolveBundledVenueFolder({
    required AssetBundle bundle,
    required int year,
    String circuitAssetId = '',
    int round = 0,
  }) async {
    for (final folder in expandedVenueFoldersForRace(
      circuitAssetId: circuitAssetId,
      year: year,
      round: round,
    )) {
      if (await bundledVenueHasProbeResults(
        bundle: bundle,
        year: year,
        venueFolder: folder,
      )) {
        return folder;
      }
    }
    return null;
  }

  /// Same rules as `fetch_session_data.dart` `_sanitizeName`.
  static String sanitizeSessionStem(String sessionName) {
    return sessionName
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  /// Builds `assets/data/{year}/{venue}/{stem}_{suffix}.json`.
  static String sessionAssetPath({
    required int year,
    required String venueFolder,
    required String sessionStem,
    required String suffix,
  }) {
    return 'assets/data/$year/$venueFolder/${sessionStem}_$suffix.json';
  }

  static String driversStandingsPath(int year) =>
      'assets/data/$year/drivers_standings_$year.json';

  static String teamsStandingsPath(int year) =>
      'assets/data/$year/teams_standings_$year.json';

  /// `assets/data/drivers/{slug}.json` — tries diacritic slug then ASCII (e.g. Pérez).
  static List<String> hubDriverExportAssetPaths(String displayName) {
    return driverJsonSlugCandidates(displayName)
        .map((slug) => 'assets/data/drivers/$slug.json')
        .toList();
  }

  static List<String> driversStandingsCandidatePaths(int year) => [
        driversStandingsPath(year),
        'assets/data/results/drivers_standings_$year.json',
        'data/results/drivers/drivers_standings_$year.json',
      ];

  static List<String> teamsStandingsCandidatePaths(int year) => [
        teamsStandingsPath(year),
        'assets/data/results/teams_standings_$year.json',
        'data/results/teams/teams_standings_$year.json',
      ];

  /// Candidate paths for **grand prix race** results (longest non-empty list wins).
  static List<String> candidateRaceResultPaths({
    required int year,
    required String venueFolder,
  }) {
    final paths = <String>[];
    if (kVenuesWithDayNumberedSessions.contains(venueFolder)) {
      for (var d = 3; d >= 1; d--) {
        paths.add(
          sessionAssetPath(
            year: year,
            venueFolder: venueFolder,
            sessionStem: 'day_$d',
            suffix: 'results',
          ),
        );
      }
    }
    paths.add(
      sessionAssetPath(
        year: year,
        venueFolder: venueFolder,
        sessionStem: 'race',
        suffix: 'results',
      ),
    );
    return paths;
  }

  static List<String> candidateRaceWeatherPaths({
    required int year,
    required String venueFolder,
  }) {
    final paths = <String>[];
    if (kVenuesWithDayNumberedSessions.contains(venueFolder)) {
      for (var d = 3; d >= 1; d--) {
        paths.add(
          sessionAssetPath(
            year: year,
            venueFolder: venueFolder,
            sessionStem: 'day_$d',
            suffix: 'weather',
          ),
        );
      }
    }
    paths.add(
      sessionAssetPath(
        year: year,
        venueFolder: venueFolder,
        sessionStem: 'race',
        suffix: 'weather',
      ),
    );
    return paths;
  }

  static List<String> candidateRaceRaceControlPaths({
    required int year,
    required String venueFolder,
  }) {
    final paths = <String>[];
    if (kVenuesWithDayNumberedSessions.contains(venueFolder)) {
      for (var d = 3; d >= 1; d--) {
        paths.add(
          sessionAssetPath(
            year: year,
            venueFolder: venueFolder,
            sessionStem: 'day_$d',
            suffix: 'race_control',
          ),
        );
      }
    }
    paths.add(
      sessionAssetPath(
        year: year,
        venueFolder: venueFolder,
        sessionStem: 'race',
        suffix: 'race_control',
      ),
    );
    return paths;
  }

  static List<String> legacyRoundResultPaths(int year, int round) => [
    'results_${year}_round_$round.json',
    'data/results_${year}_round_$round.json',
    'data/results/results_${year}_round_$round.json',
    'assets/data/results/results_${year}_round_$round.json',
  ];

  static List<String> legacyRoundWeatherPaths(int year, int round) => [
    'weather_${year}_round_$round.json',
    'data/weather_${year}_round_$round.json',
    'data/results/weather_${year}_round_$round.json',
    'assets/data/results/weather_${year}_round_$round.json',
  ];

  static List<String> legacyRoundRaceControlPaths(int year, int round) => [
    'race_control_${year}_round_$round.json',
    'data/race_control_${year}_round_$round.json',
    'data/results/race_control_${year}_round_$round.json',
    'assets/data/results/race_control_${year}_round_$round.json',
  ];

  static List<String> legacySessionsOverviewPaths(int year, int round) => [
    'sessions_${year}_round_$round.json',
    'data/sessions_${year}_round_$round.json',
    'data/results/sessions_${year}_round_$round.json',
    'assets/data/results/sessions_${year}_round_$round.json',
  ];

  static Future<Set<String>>? _logicalAssetKeysFuture;

  /// Logical keys (`assets/...`) from [AssetManifest], built once from [rootBundle].
  ///
  /// Used so existence checks do not hit the network on web for every missing
  /// candidate path (which would spam the console with 404s).
  static Future<Set<String>> logicalAssetKeys() {
    return _logicalAssetKeysFuture ??= () async {
      try {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        return {
          for (final p in manifest.listAssets())
            normalizeManifestAssetPath(p),
        };
      } catch (_) {
        return <String>{};
      }
    }();
  }

  /// Whether [path] exists in the asset bundle.
  ///
  /// Uses [logicalAssetKeys] as a fast positive cache only: if the normalized
  /// manifest lists [path], returns true without I/O. Otherwise calls
  /// [AssetBundle.loadString] to decide.
  ///
  /// Relying only on `keys.contains(path)` when `keys` is non-empty caused
  /// **false negatives** on some builds (manifest not listing every file under
  /// a declared folder). That broke [discoverSessionResultStemsByProbing] and
  /// Weekend Hub preload, which then saw empty session stems and hid Top 3 /
  /// race control.
  static Future<bool> bundleHasAsset(AssetBundle bundle, String path) async {
    final keys = await logicalAssetKeys();
    if (keys.isNotEmpty && keys.contains(path)) {
      return true;
    }
    try {
      await bundle.loadString(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// [AssetManifest.listAssets] keys may be `packages/name/assets/...`.
  static String normalizeManifestAssetPath(String path) {
    final m = RegExp(r'^packages/[^/]+/').firstMatch(path);
    if (m == null) {
      return path;
    }
    return path.substring(m.end);
  }

  /// True if any `assets/data/{year}/{venueFolder}/*_results.json` exists for a
  /// recent range of seasons (through [referenceYear]).
  ///
  /// Call sites must not depend on only [DateTime.now].year: the current-year
  /// folder is often empty or incomplete before the event while older seasons
  /// are already bundled. [WeekendHubScreen] still resolves the latest GP via
  /// `/weekendhub/{venue}`.
  static Future<bool> venueHasAnyBundledSessionResults({
    required AssetBundle bundle,
    required String venueFolder,
    int referenceYear = 0,
    int yearsBack = 8,
  }) async {
    for (final folder in venueFolderCandidates(venueFolder)) {
      if (await _venueHasAnyBundledSessionResultsForSingleFolder(
            bundle: bundle,
            venueFolder: folder,
            referenceYear: referenceYear,
            yearsBack: yearsBack,
          )) {
        return true;
      }
    }
    return false;
  }

  static Future<bool> _venueHasAnyBundledSessionResultsForSingleFolder({
    required AssetBundle bundle,
    required String venueFolder,
    int referenceYear = 0,
    int yearsBack = 8,
  }) async {
    final now = referenceYear > 0 ? referenceYear : DateTime.now().year;
    final minYear = now - yearsBack;
    final maxYear = now + 1;
    final keys = await logicalAssetKeys();
    if (keys.isNotEmpty) {
      final escaped = RegExp.escape(venueFolder);
      final re = RegExp(
        '^assets/data/(\\d{4})/$escaped/[^/]+_results\\.json\$',
      );
      for (final k in keys) {
        final m = re.firstMatch(k);
        if (m == null) continue;
        final y = int.tryParse(m.group(1)!);
        if (y == null || y < minYear || y > maxYear) continue;
        return true;
      }
    }
    // Manifest key scan can miss assets (e.g. keys from [rootBundle] differ from
    // [bundle], or incomplete web manifests). Always fall back to discovery.
    for (var y = maxYear; y >= minYear; y--) {
      var stems = await discoverSessionResultStems(
        bundle: bundle,
        year: y,
        venueFolder: venueFolder,
        hasSprintWeekend: false,
      );
      if (stems.isNotEmpty) return true;
      stems = await discoverSessionResultStems(
        bundle: bundle,
        year: y,
        venueFolder: venueFolder,
        hasSprintWeekend: true,
      );
      if (stems.isNotEmpty) return true;
    }
    for (var y = maxYear; y >= minYear; y--) {
      for (final stem in const ['race', 'practice_1', 'qualifying']) {
        final path = sessionAssetPath(
          year: y,
          venueFolder: venueFolder,
          sessionStem: stem,
          suffix: 'results',
        );
        try {
          await bundle.loadString(path);
          return true;
        } catch (_) {}
      }
    }
    return false;
  }

  /// Stems discovered from [AssetManifest] (`*_results.json` under the venue folder).
  ///
  /// Returns empty if the manifest cannot be read (tests / unusual embeds).
  static Future<List<String>> discoverSessionResultStemsFromManifest({
    required AssetBundle bundle,
    required int year,
    required String venueFolder,
    required bool hasSprintWeekend,
  }) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(bundle);
      final prefix = 'assets/data/$year/$venueFolder/';
      const suffix = '_results.json';
      final stems = <String>{};
      for (final path in manifest.listAssets()) {
        final logical = normalizeManifestAssetPath(path);
        if (!logical.startsWith(prefix)) continue;
        if (!logical.endsWith(suffix)) continue;
        final rest = logical.substring(prefix.length);
        if (rest.contains('/')) continue;
        final stem = rest.substring(0, rest.length - suffix.length);
        if (stem.isEmpty) continue;
        stems.add(stem);
      }
      final list = stems.toList()
        ..sort(
          (a, b) => stemDiscoveryIndex(a, venueFolder, hasSprintWeekend)
              .compareTo(stemDiscoveryIndex(b, venueFolder, hasSprintWeekend)),
        );
      return list;
    } catch (_) {
      return const <String>[];
    }
  }

  /// Probe known session stems (fallback when manifest is empty or unavailable).
  static Future<List<String>> discoverSessionResultStemsByProbing({
    required AssetBundle bundle,
    required int year,
    required String venueFolder,
    required bool hasSprintWeekend,
  }) async {
    final found = <String>[];
    Future<void> probe(String stem) async {
      final path = sessionAssetPath(
        year: year,
        venueFolder: venueFolder,
        sessionStem: stem,
        suffix: 'results',
      );
      if (await bundleHasAsset(bundle, path)) {
        found.add(stem);
      }
    }

    if (kVenuesWithDayNumberedSessions.contains(venueFolder)) {
      await probe('day_1');
      await probe('day_2');
      await probe('day_3');
      await probe('race');
    } else {
      await probe('practice_1');
      await probe('practice_2');
      await probe('practice_3');
      if (hasSprintWeekend) {
        await probe('sprint_qualifying');
        await probe('sprint');
      }
      await probe('qualifying');
      await probe('race');
    }

    found.sort(
      (a, b) => stemDiscoveryIndex(a, venueFolder, hasSprintWeekend)
          .compareTo(stemDiscoveryIndex(b, venueFolder, hasSprintWeekend)),
    );
    return found;
  }

  /// Session stems with a bundled `_results.json`, in weekend order.
  ///
  /// Merges [AssetManifest] discovery with path probing. Relying on the manifest
  /// alone can **drop** sessions on some web builds (incomplete key lists), so
  /// the dropdown would miss e.g. `practice_3` / `qualifying` even when those
  /// JSON files are bundled.
  static Future<List<String>> discoverSessionResultStems({
    required AssetBundle bundle,
    required int year,
    required String venueFolder,
    required bool hasSprintWeekend,
  }) async {
    final fromManifest = await discoverSessionResultStemsFromManifest(
      bundle: bundle,
      year: year,
      venueFolder: venueFolder,
      hasSprintWeekend: hasSprintWeekend,
    );
    final fromProbing = await discoverSessionResultStemsByProbing(
      bundle: bundle,
      year: year,
      venueFolder: venueFolder,
      hasSprintWeekend: hasSprintWeekend,
    );
    final merged = <String>{...fromManifest, ...fromProbing}.toList()
      ..sort(
        (a, b) => stemDiscoveryIndex(a, venueFolder, hasSprintWeekend)
            .compareTo(stemDiscoveryIndex(b, venueFolder, hasSprintWeekend)),
      );
    return merged;
  }

  /// Chronological index for dropdown ordering (low → high through the weekend).
  static int stemDiscoveryIndex(
    String stem,
    String venueFolder,
    bool hasSprintWeekend,
  ) {
    if (kVenuesWithDayNumberedSessions.contains(venueFolder)) {
      const order = ['day_1', 'day_2', 'day_3', 'race'];
      return order.indexOf(stem).clamp(0, 99);
    }
    final order = hasSprintWeekend
        ? const [
            'practice_1',
            'practice_2',
            'practice_3',
            'sprint_qualifying',
            'sprint',
            'qualifying',
            'race',
          ]
        : const [
            'practice_1',
            'practice_2',
            'practice_3',
            'qualifying',
            'race',
          ];
    final i = order.indexOf(stem);
    return i >= 0 ? i : 50;
  }

  /// Pick the “latest” session that has results (Race / day_3 wins over FP1).
  static String preferredDefaultStem(
    List<String> stems,
    String venueFolder,
  ) {
    if (stems.isEmpty) return '';
    var best = stems.first;
    var bestP = stemDefaultPriority(best, venueFolder);
    for (final s in stems.skip(1)) {
      final p = stemDefaultPriority(s, venueFolder);
      if (p > bestP) {
        bestP = p;
        best = s;
      }
    }
    return best;
  }

  static int stemDefaultPriority(String stem, String venueFolder) {
    if (kVenuesWithDayNumberedSessions.contains(venueFolder)) {
      if (stem == 'race' || stem == 'day_3') return 100;
      if (stem == 'day_2') return 60;
      if (stem == 'day_1') return 20;
      return 10;
    }
    switch (stem) {
      case 'race':
        return 100;
      case 'sprint':
        return 85;
      case 'sprint_qualifying':
        return 80;
      case 'qualifying':
        return 75;
      case 'practice_3':
        return 40;
      case 'practice_2':
        return 30;
      case 'practice_1':
        return 20;
      default:
        return 10;
    }
  }
}
