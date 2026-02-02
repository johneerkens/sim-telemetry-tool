import 'package:flutter/material.dart';
import '../../core/telemetry/telemetry_source_factory.dart';
import '../../core/models/telemetry_frame.dart';
import 'telemetry_view_model.dart';
import 'line_chart.dart';
import 'telemetry_series.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TelemetryFrame>(
      stream: createTelemetryStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final vm = TelemetryViewModel.fromFrame(snapshot.data!);

        return _DashboardContent(vm: vm);
      },
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent({required this.vm});

  final TelemetryViewModel vm;

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  final _speedSeries = TelemetrySeries(maxPoints: 120);
  final _rpmSeries = TelemetrySeries(maxPoints: 120);

  @override
  void didUpdateWidget(covariant _DashboardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _speedSeries.add(widget.vm.speedKph);
    _rpmSeries.add(widget.vm.rpm.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;

    return Scaffold(
      appBar: AppBar(title: const Text('Telemetry Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Speed', '${vm.speedKph.toStringAsFixed(1)} km/h'),
            LineChart(
              values: _speedSeries.values,
              min: 0,
              max: 320,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _row('RPM', vm.rpm.toString()),
            LineChart(
              values: _rpmSeries.values,
              min: 0,
              max: 9000,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            _row('Gear', vm.gear.toString()),
            _row('Throttle', '${(vm.throttle * 100).toStringAsFixed(0)}%'),
            _row('Brake', '${(vm.brake * 100).toStringAsFixed(0)}%'),
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
