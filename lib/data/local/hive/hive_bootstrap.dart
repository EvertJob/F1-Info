import 'package:hive_flutter/hive_flutter.dart';

import '../models/race_result.dart';
import '../models/race_results_cache.dart';
import 'hive_boxes.dart';

abstract final class HiveBootstrap {
  static bool _initialized = false;

  /// Registers adapters and opens all boxes required by the repository layer.
  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(RaceResultAdapter().typeId)) {
      Hive.registerAdapter(RaceResultAdapter());
    }
    if (!Hive.isAdapterRegistered(RaceResultsCacheAdapter().typeId)) {
      Hive.registerAdapter(RaceResultsCacheAdapter());
    }

    if (!Hive.isBoxOpen(HiveBoxes.raceResults)) {
      await Hive.openBox<RaceResultsCache>(HiveBoxes.raceResults);
    }
    if (!Hive.isBoxOpen(HiveBoxes.sessionPayloads)) {
      await Hive.openBox<String>(HiveBoxes.sessionPayloads);
    }

    _initialized = true;
  }
}
