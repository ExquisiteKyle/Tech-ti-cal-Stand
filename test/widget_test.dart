// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:techtical_stand/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: TechticalStandApp()));

    // Verify that our app shows the correct content.
    expect(find.text('Techtical Stand'), findsWidgets);
    expect(find.text('Tower Defense Game'), findsOneWidget);
    expect(find.text('Game engine coming soon...'), findsOneWidget);
  });
}
