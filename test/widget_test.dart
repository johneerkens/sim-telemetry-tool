// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// ignore_for_file: library_prefixes

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sim_telemetry_tool/main.dart' as mainApp;

void main() {
  testWidgets('Dashboard shows empty state on startup',
      (WidgetTester tester) async {
    await tester.pumpWidget(const mainApp.SimTelemetryApp());
    await tester.pump();

    expect(find.text('Sim Telemetry Tool'), findsOneWidget);
    expect(find.text('Starting mock telemetry'), findsOneWidget);
    expect(find.text('Mock Starting'), findsOneWidget);
  });
}
