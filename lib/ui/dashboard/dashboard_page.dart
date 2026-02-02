import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/telemetry/telemetry_source_factory.dart';
import 'telemetry_view_model.dart';
// Add this import if you are using fl_chart package for LineChart
// import 'package:fl_chart/fl_chart.dart';

// If you don't have a LineChart widget, you can define a placeholder below:

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

// Simple placeholder LineChart widget for demonstration
class LineChart extends StatelessWidget {
  final List<double> values;
  final double min;
  final double max;
  final Color color;

  const LineChart({
    super.key,
    required this.values,
    required this.min,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Replace this Container with your actual chart implementation
    return Container(
      height: 100,
      // ignore: deprecated_member_use
      color: color.withOpacity(0.1),
      child: Center(child: Text('LineChart Placeholder')),
    );
  }
}

class _DashboardPageState extends State<DashboardPage> {
  StreamSubscription? _sub;
  TelemetryViewModel? _vm;

  static const int _seriesLength = 50;
  final List<double> _speedSeries = List.filled(_seriesLength, 0.0);
  final List<double> _rpmSeries = List.filled(_seriesLength, 0.0);


@override
void initState() {
  super.initState();

  _sub = createTelemetryStream().listen((frame) {
  if (kDebugMode) {
    print('Telemetry frame received: ${frame.speedKph}');
  }
  setState(() {
    _vm = TelemetryViewModel.fromFrame(frame);

      // Update speed and rpm series
      _speedSeries.removeAt(0);
      _speedSeries.add(_vm!.speedKph);

      _rpmSeries.removeAt(0);
      _rpmSeries.add(_vm!.rpm.toDouble());
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
  const SizedBox(height: 8),
  LineChart(
    values: _speedSeries,
    min: 0,
    max: 320,
    color: Colors.blue,
  ),
  const SizedBox(height: 16),
  _row('RPM', _vm!.rpm.toString()),
  const SizedBox(height: 8),
  LineChart(
    values: _rpmSeries,
    min: 0,
    max: 9000,
    color: Colors.red,
  ),
  const SizedBox(height: 16),
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