import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/telemetry/telemetry_source_factory.dart';
import 'telemetry_view_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  StreamSubscription? _sub;
  TelemetryViewModel? _vm;

  @override
  void initState() {
    super.initState();

    _sub = createTelemetryStream().listen((frame) {
      setState(() {
        _vm = TelemetryViewModel.fromFrame(frame);
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_vm == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Telemetry Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Speed', '${_vm!.speedKph.toStringAsFixed(1)} km/h'),
            _row('RPM', _vm!.rpm.toString()),
            _row('Gear', _vm!.gear.toString()),
            _row('Throttle', '${(_vm!.throttle * 100).toStringAsFixed(0)}%'),
            _row('Brake', '${(_vm!.brake * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}