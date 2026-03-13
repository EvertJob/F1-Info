import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:f1/main.dart';

void main() {
  testWidgets('app renders primary navigation', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const F1HubApp());
    await tester.pump();

    expect(find.text('CIRCUITS'), findsOneWidget);
    expect(find.text('DRIVERS'), findsOneWidget);
    expect(find.text('TEAMS'), findsOneWidget);
  });
}
