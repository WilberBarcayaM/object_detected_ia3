// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reconocimiento/app/app.dart';

void main() {
  testWidgets('Shows onboarding screen on first launch',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const EcoVisionApp());
    await tester.pumpAndSettle();

    expect(find.text('EcoVision'), findsOneWidget);
    expect(find.text('Primera vez en la app'), findsOneWidget);
  });
}
