import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:f1/ai_strategist_prefs_service.dart';
import 'package:f1/calendar_prefs_service.dart';
import 'package:f1/data/local/hive/hive_boxes.dart';
import 'package:f1/data/local/models/race_result.dart';
import 'package:f1/data/local/models/race_results_cache.dart';
import 'package:f1/detail_expansion_prefs_service.dart';
import 'package:f1/display_settings_controller.dart';
import 'package:f1/last_podium_prefs_service.dart';
import 'package:f1/main.dart';
import 'package:f1/profile_favorites_service.dart';
import 'package:f1/theme/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://aeekchoaetlksooyylsv.supabase.co',
      anonKey: 'sb_publishable_38F48DBpJ7cWwVo-2yZjhA_rE6wE9uz',
    );
    final tmp = await Directory.systemTemp.createTemp('f1_widget_test_hive');
    Hive.init(tmp.path);
    if (!Hive.isAdapterRegistered(RaceResultAdapter().typeId)) {
      Hive.registerAdapter(RaceResultAdapter());
    }
    if (!Hive.isAdapterRegistered(RaceResultsCacheAdapter().typeId)) {
      Hive.registerAdapter(RaceResultsCacheAdapter());
    }
    await Hive.openBox<RaceResultsCache>(HiveBoxes.raceResults);
    await Hive.openBox<String>(HiveBoxes.sessionPayloads);
    await SessionDataManager().init(races);
  });

  testWidgets('app renders primary navigation', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final themeController = ThemeController(
      initialSchemeIndex: 0,
      initialThemeMode: ThemeMode.light,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeController>.value(value: themeController),
          ChangeNotifierProvider<ProfileFavoritesNotifier>(
            create: (_) => ProfileFavoritesNotifier(),
          ),
          ChangeNotifierProvider<AiStrategistPrefsNotifier>(
            create: (_) => AiStrategistPrefsNotifier(),
          ),
          ChangeNotifierProvider<CalendarPrefsNotifier>(
            create: (_) => CalendarPrefsNotifier(),
          ),
          ChangeNotifierProvider<LastPodiumPrefsNotifier>(
            create: (_) => LastPodiumPrefsNotifier(),
          ),
          ChangeNotifierProvider<DetailExpansionPrefsNotifier>(
            create: (_) => DetailExpansionPrefsNotifier(),
          ),
          ChangeNotifierProvider<DisplaySettingsController>(
            create: (context) => DisplaySettingsController(
              context.read<DetailExpansionPrefsNotifier>(),
            ),
          ),
        ],
        child: const F1HubApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();

    expect(find.text('CIRCUITS'), findsOneWidget);
    expect(find.text('DRIVERS'), findsOneWidget);
    expect(find.text('TEAMS'), findsOneWidget);
  });
}
