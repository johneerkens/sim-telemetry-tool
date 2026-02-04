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
          hasError: snapshot.hasError,
        );

        if (snapshot.hasError) {
          return _DashboardScaffold(
            status: status,
            body: _TelemetryEmptyState(
              mode: telemetryMode,
              error: snapshot.error,
            ),
          );
        }

        if (!snapshot.hasData) {
          return _DashboardScaffold(
            status: status,
            body: _TelemetryEmptyState(mode: telemetryMode),
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
  required bool hasError,
}) {
  if (mode == TelemetryMode.acc) {
    if (hasError) {
      return const ConnectionStatus(
        label: 'ACC Error',
        color: Colors.red,
      );
    }

    return hasData
        ? const ConnectionStatus(
            label: 'ACC Connected',
            color: Colors.green,
          )
        : const ConnectionStatus(
            label: 'ACC Waiting',
            color: Colors.orange,
          );
  }

  if (hasError) {
    return const ConnectionStatus(
      label: 'Mock Error',
      color: Colors.red,
    );
  }

  return hasData
      ? const ConnectionStatus(
          label: 'Mock Data',
          color: Colors.blue,
        )
      : const ConnectionStatus(
          label: 'Mock Starting',
          color: Colors.orange,
        );
}

class _DashboardScaffold extends StatelessWidget {
  const _DashboardScaffold({required this.status, required this.body});

  final ConnectionStatus status;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemetry Dashboard'),
        actions: [
          _ConnectionStatusIndicator(status: status),
          const SizedBox(width: 16),
        ],
      ),
      body: body,
    );
  }
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
  void initState() {
    super.initState();
    _speedSeries.add(widget.vm.speedKph);
    _rpmSeries.add(widget.vm.rpm.toDouble());
  }

  @override
  void didUpdateWidget(covariant _DashboardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.vm.timestamp != oldWidget.vm.timestamp) {
      _speedSeries.add(widget.vm.speedKph);
      _rpmSeries.add(widget.vm.rpm.toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final theme = Theme.of(context);
    final lastUpdate = TimeOfDay.fromDateTime(vm.timestamp).format(context);

    return _DashboardScaffold(
      status: widget.status,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          const spacing = 16.0;
          final columns = width >= 1100
              ? 4
              : width >= 780
                  ? 2
                  : 1;
          final tileWidth =
              (width - spacing * (columns - 1)) / columns;
          final chartWidth = width >= 900 ? (width - spacing) / 2 : width;

          final tiles = <Widget>[
            _MetricCard(
              label: 'Speed',
              value: vm.speedKph.toStringAsFixed(0),
              unit: 'km/h',
              accent: Colors.blue,
              footer: Text(
                'Updated $lastUpdate',
                style: theme.textTheme.bodySmall,
              ),
            ),
            _MetricCard(
              label: 'RPM',
              value: vm.rpm.toString(),
              unit: 'rpm',
              accent: Colors.red,
            ),
            _MetricCard(
              label: 'Gear',
              value: vm.gear.toString(),
              accent: Colors.orange,
              footer: Text(
                _modeLabel(telemetryMode),
                style: theme.textTheme.bodySmall,
              ),
            ),
            _PedalCard(
              throttle: vm.throttle,
              brake: vm.brake,
            ),
            _SteeringCard(steering: vm.steering),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: tiles
                      .map((tile) => SizedBox(width: tileWidth, child: tile))
                      .toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Trends',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: chartWidth,
                      child: _ChartCard(
                        label: 'Speed',
                        color: Colors.blue,
                        child: LineChart(
                          values: _speedSeries.values,
                          min: 0,
                          max: 320,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: chartWidth,
                      child: _ChartCard(
                        label: 'RPM',
                        color: Colors.red,
                        child: LineChart(
                          values: _rpmSeries.values,
                          min: 0,
                          max: 9000,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _modeLabel(TelemetryMode mode) {
  switch (mode) {
    case TelemetryMode.acc:
      return 'Mode: ACC';
    case TelemetryMode.mock:
      return 'Mode: Mock';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.unit,
    this.accent,
    this.footer,
  });

  final String label;
  final String value;
  final String? unit;
  final Color? accent;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 0.6,
              color: accent ?? theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent ?? theme.colorScheme.primary,
                ),
              ),
              if (unit != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 6),
                  child: Text(
                    unit!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _PedalCard extends StatelessWidget {
  const _PedalCard({required this.throttle, required this.brake});

  final double throttle;
  final double brake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pedals',
            style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.6),
          ),
          const SizedBox(height: 12),
          _bar(
            context,
            label: 'Throttle',
            value: throttle,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _bar(
            context,
            label: 'Brake',
            value: brake,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _bar(
    BuildContext context, {
    required String label,
    required double value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text('${(value * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}

class _SteeringCard extends StatelessWidget {
  const _SteeringCard({required this.steering});

  final double steering;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steeringValue = steering.clamp(-1.0, 1.0);
    final percent = (steeringValue.abs() * 100).toStringAsFixed(0);
    final direction = steeringValue >= 0 ? 'Right' : 'Left';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Steering',
            style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            '$direction $percent%',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (steeringValue + 1) / 2,
              minHeight: 8,
              color: theme.colorScheme.primary,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Left', style: theme.textTheme.bodySmall),
              Text('Right', style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.label,
    required this.color,
    required this.child,
  });

  final String label;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.6),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TelemetryEmptyState extends StatelessWidget {
  const _TelemetryEmptyState({required this.mode, this.error});

  final TelemetryMode mode;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = error != null;

    final title = isError
        ? 'Telemetry stream error'
        : mode == TelemetryMode.acc
            ? 'Waiting for ACC telemetry'
            : 'Starting mock telemetry';

    final message = isError
        ? 'We could not read telemetry from the current source.'
        : mode == TelemetryMode.acc
            ? 'Launch ACC and start a session. Telemetry packets will appear here once the game is running.'
            : 'Generating simulated telemetry so you can explore the dashboard without the game.';

    final icon = isError ? Icons.error_outline : Icons.sensors_off;
    final accent = isError ? theme.colorScheme.error : theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 40, color: accent),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              if (isError) ...[
                const SizedBox(height: 12),
                SelectableText(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              if (!isError) ...[
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    color: accent,
                    backgroundColor: accent.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ],
          ),
        ),
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
