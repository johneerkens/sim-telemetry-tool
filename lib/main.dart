import 'package:flutter/material.dart';
import 'ui/dashboard/dashboard_page.dart';

void main() {
  runApp(const SimTelemetryApp());
}

class SimTelemetryApp extends StatelessWidget {
  const SimTelemetryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.teal,
    );

    return MaterialApp(
      title: 'Sim Telemetry Tool',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        scaffoldBackgroundColor: baseTheme.colorScheme.surface,
      ),
      home: const DashboardPage(),
    );
  }
}
