// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hopin_app/main.dart';

void main() {
  testWidgets('Hopin app launches with splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HopinApp());

    // Verify that the splash screen shows up
    expect(find.text('Hopin'), findsOneWidget);
    expect(find.text('Student ride-sharing made simple'), findsOneWidget);
    expect(find.byIcon(Icons.directions_car), findsOneWidget);
  });
}
