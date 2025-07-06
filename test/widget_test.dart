// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:techtical_stand/main.dart';

void main() {
  group('App Integration Tests', () {
    testWidgets('App loads and shows main menu', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const ProviderScope(child: TechticalStandApp()));

      // Verify that our app shows the correct content.
      expect(find.text('Techtical Defense'), findsOneWidget);
      expect(find.text('Strategic Tower Defense'), findsOneWidget);

      // Verify main menu buttons are present
      expect(find.text('Quick Play'), findsOneWidget);
      expect(find.text('Level Select'), findsOneWidget);
      expect(find.text('Achievements'), findsOneWidget);
    });

    testWidgets('App theme is applied correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: TechticalStandApp()));

      // Verify the app uses the correct theme
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, equals('Techtical Stand'));
    });
  });
}
