import 'package:flutter/material.dart';
import '../../core/models/telemetry_frame.dart';
import '../../core/telemetry/telemetry_mode.dart';
import '../../core/telemetry/telemetry_source_factory.dart';
import 'line_chart.dart';
import 'telemetry_series.dart';
import 'telemetry_view_model.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TelemetryFrame>(
      stream: createTelemetryStream(),
      builder: (context, snapshot) {
        final status = _connectionStatus(
          telemetryMode,
          hasData: snapshot.hasData,
        );

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Telemetry Dashboard'),
              actions: [
                _ConnectionStatusIndicator(status: status),
                const SizedBox(width: 16),
              ],
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final vm = TelemetryViewModel.fromFrame(snapshot.data!);

        return _DashboardContent(vm: vm, status: status);
      },
    );
  }
}

ConnectionStatus _connectionStatus(
  TelemetryMode mode, {
  required bool hasData,
}) {
  if (mode == TelemetryMode.acc) {
    return hasData
        ? const ConnectionStatus(
            label: 'ACC Connected',
            color: Colors.green,
          )
        : const ConnectionStatus(
            label: 'ACC Disconnected',
            color: Colors.red,
          );
  }

  return const ConnectionStatus(
    label: 'Mock Data',
    color: Colors.blue,
  );
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent({required this.vm, required this.status});

  final TelemetryViewModel vm;
  final ConnectionStatus status;

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
      appBar: AppBar(
        title: const Text('Telemetry Dashboard'),
        actions: [
          _ConnectionStatusIndicator(status: widget.status),
          const SizedBox(width: 16),
        ],
      ),
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

class ConnectionStatus {
  const ConnectionStatus({required this.label, required this.color});

  final String label;
  final Color color;
}

class _ConnectionStatusIndicator extends StatelessWidget {
  const _ConnectionStatusIndicator({required this.status});

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status.label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
