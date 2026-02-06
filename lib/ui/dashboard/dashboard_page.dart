import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/models/telemetry_frame.dart';
import '../../core/telemetry/telemetry_mode.dart';
import '../../core/telemetry/telemetry_source_factory.dart';
import 'line_chart.dart';
import 'telemetry_series.dart';
import 'telemetry_view_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  TelemetryMode _mode = TelemetryMode.mock;
  TelemetryStreamHandle? _handle;
  Stream<TelemetryFrame>? _stream;

  bool _isRecording = false;
  final List<TelemetryFrame> _recordedFrames = [];
  DateTime? _lastRecordedTimestamp;
  DateTime? _lastPacketTimestamp;

  static const int _maxRecordedFrames = 6000;
  static const Duration _playbackInterval = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    unawaited(_createStream());
  }

  @override
  void dispose() {
    unawaited(_disposeHandle());
    super.dispose();
  }

  Future<void> _disposeHandle() async {
    final handle = _handle;
    _handle = null;
    if (handle?.dispose != null) {
      await handle!.dispose!();
    }
  }

  Future<void> _createStream() async {
    await _disposeHandle();

    final playbackFrames = _mode == TelemetryMode.playback
        ? List<TelemetryFrame>.from(_recordedFrames)
        : const <TelemetryFrame>[];

    final handle = createTelemetryStream(
      _mode,
      playbackFrames: playbackFrames,
      playbackInterval: _playbackInterval,
    );

    if (!mounted) return;

    setState(() {
      _handle = handle;
      _stream = handle.stream;
    });
  }

  Future<void> _setMode(TelemetryMode mode) async {
    if (mode == _mode) return;

    setState(() {
      _mode = mode;
      _isRecording = false;
    });

    await _createStream();
  }

  Future<void> _refresh() async {
    await _createStream();
  }

  void _toggleRecording() {
    if (_mode == TelemetryMode.playback) return;

    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _recordedFrames.clear();
        _lastRecordedTimestamp = null;
      }
    });
  }

  void _recordFrame(TelemetryFrame frame) {
    if (!_isRecording || _mode == TelemetryMode.playback) return;
    if (_lastRecordedTimestamp == frame.timestamp) return;

    _lastRecordedTimestamp = frame.timestamp;
    _recordedFrames.add(frame);

    if (_recordedFrames.length > _maxRecordedFrames) {
      _recordedFrames.removeAt(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _stream ?? Stream<TelemetryFrame>.empty();

    return StreamBuilder<TelemetryFrame>(
      stream: stream,
      builder: (context, snapshot) {
        final frame = snapshot.data;
        if (frame != null) {
          _recordFrame(frame);
          _lastPacketTimestamp = frame.timestamp;
        }

        final status = _connectionStatus(
          _mode,
          hasData: frame != null,
          hasError: snapshot.hasError,
          hasRecording: _recordedFrames.isNotEmpty,
        );

        final actions = _buildActions(Theme.of(context));
        final lastPacketAt = frame?.timestamp ?? _lastPacketTimestamp;

        final details = ConnectionDetails(
          mode: _mode,
          status: status,
          hasData: frame != null,
          hasError: snapshot.hasError,
          error: snapshot.error,
          lastPacketAt: lastPacketAt,
          lastRecordedAt: _lastRecordedTimestamp,
          recordedFrames: _recordedFrames.length,
          isRecording: _isRecording,
          playbackInterval: _playbackInterval,
          accPort: 9000,
          connectionState: snapshot.connectionState,
        );

        if (snapshot.hasError) {
          return _DashboardScaffold(
            status: status,
            actions: actions,
            details: details,
            body: _TelemetryEmptyState(
              mode: _mode,
              hasRecording: _recordedFrames.isNotEmpty,
              error: snapshot.error,
            ),
          );
        }

        if (frame == null) {
          return _DashboardScaffold(
            status: status,
            actions: actions,
            details: details,
            body: _TelemetryEmptyState(
              mode: _mode,
              hasRecording: _recordedFrames.isNotEmpty,
            ),
          );
        }

        final vm = TelemetryViewModel.fromFrame(frame);

        return _DashboardContent(
          key: ValueKey(_mode),
          vm: vm,
          status: status,
          details: details,
          mode: _mode,
          isRecording: _isRecording,
          actions: actions,
        );
      },
    );
  }

  List<Widget> _buildActions(ThemeData theme) {
    final actions = <Widget>[
      _ModeSelector(
        mode: _mode,
        onChanged: (mode) async {
          await _setMode(mode);
        },
      ),
    ];

    if (_mode != TelemetryMode.playback) {
      actions.add(
        IconButton(
          tooltip: _isRecording ? 'Stop recording' : 'Record telemetry',
          icon: Icon(
            _isRecording ? Icons.stop_circle : Icons.fiber_manual_record,
            color: _isRecording ? theme.colorScheme.error : null,
          ),
          onPressed: _toggleRecording,
        ),
      );
    }

    actions.add(
      IconButton(
        tooltip: 'Retry/refresh',
        icon: const Icon(Icons.refresh),
        onPressed: () async {
          await _refresh();
        },
      ),
    );

    return actions;
  }
}

ConnectionStatus _connectionStatus(
  TelemetryMode mode, {
  required bool hasData,
  required bool hasError,
  required bool hasRecording,
}) {
  if (hasError) {
    return ConnectionStatus(
      label: '${_modeLabel(mode)} Error',
      color: Colors.red,
    );
  }

  if (mode == TelemetryMode.acc) {
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

  if (mode == TelemetryMode.playback) {
    if (!hasRecording) {
      return const ConnectionStatus(
        label: 'No Recording',
        color: Colors.orange,
      );
    }

    return hasData
        ? const ConnectionStatus(
            label: 'Playback',
            color: Colors.teal,
          )
        : const ConnectionStatus(
            label: 'Playback Starting',
            color: Colors.blueGrey,
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

class ConnectionDetails {
  const ConnectionDetails({
    required this.mode,
    required this.status,
    required this.hasData,
    required this.hasError,
    required this.error,
    required this.lastPacketAt,
    required this.lastRecordedAt,
    required this.recordedFrames,
    required this.isRecording,
    required this.playbackInterval,
    required this.accPort,
    required this.connectionState,
  });

  final TelemetryMode mode;
  final ConnectionStatus status;
  final bool hasData;
  final bool hasError;
  final Object? error;
  final DateTime? lastPacketAt;
  final DateTime? lastRecordedAt;
  final int recordedFrames;
  final bool isRecording;
  final Duration playbackInterval;
  final int accPort;
  final ConnectionState connectionState;
}

class _DashboardScaffold extends StatelessWidget {
  const _DashboardScaffold({
    required this.status,
    required this.body,
    required this.actions,
    required this.details,
  });

  final ConnectionStatus status;
  final Widget body;
  final List<Widget> actions;
  final ConnectionDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Sim Telemetry Tool'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        actions: [
          _ConnectionStatusIndicator(status: status),
          const SizedBox(width: 12),
          ...actions,
          const SizedBox(width: 12),
          Builder(
            builder: (context) {
              return IconButton(
                tooltip: 'Connection details',
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      endDrawer: _ConnectionDetailsDrawer(details: details),
      body: _DashboardBackground(child: body),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent({
    super.key,
    required this.vm,
    required this.status,
    required this.details,
    required this.mode,
    required this.isRecording,
    required this.actions,
  });

  final TelemetryViewModel vm;
  final ConnectionStatus status;
  final ConnectionDetails details;
  final TelemetryMode mode;
  final bool isRecording;
  final List<Widget> actions;

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent>
    with SingleTickerProviderStateMixin {
  final _speedSeries = TelemetrySeries(maxPoints: 120);
  final _rpmSeries = TelemetrySeries(maxPoints: 120);
  late final AnimationController _entryController;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curve = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _entryFade = curve;
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(curve);
    _entryController.forward();
    _speedSeries.add(widget.vm.speedKph);
    _rpmSeries.add(widget.vm.rpm.toDouble());
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
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
      actions: widget.actions,
      details: widget.details,
      body: FadeTransition(
        opacity: _entryFade,
        child: SlideTransition(
          position: _entrySlide,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              const spacing = 12.0;
              final columns = width >= 1100
                  ? 4
                  : width >= 780
                      ? 2
                      : 1;
              final tileWidth =
                  (width - spacing * (columns - 1)) / columns;
              final chartWidth =
                  width >= 900 ? (width - spacing) / 2 : width;

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
                    _modeFooterLabel(widget.mode, widget.isRecording),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: tiles
                          .map((tile) =>
                              SizedBox(width: tileWidth, child: tile))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    const _SectionHeader(title: 'Trends'),
                    const SizedBox(height: 10),
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
        ),
      ),
    );
  }
}

String _modeLabel(TelemetryMode mode) {
  switch (mode) {
    case TelemetryMode.acc:
      return 'ACC';
    case TelemetryMode.mock:
      return 'Mock';
    case TelemetryMode.playback:
      return 'Playback';
  }
}

String _modeFooterLabel(TelemetryMode mode, bool isRecording) {
  final base = 'Mode: ${_modeLabel(mode)}';
  return isRecording ? '$base | Recording' : base;
}

IconData _modeIcon(TelemetryMode mode) {
  switch (mode) {
    case TelemetryMode.acc:
      return Icons.sports_motorsports;
    case TelemetryMode.mock:
      return Icons.auto_awesome;
    case TelemetryMode.playback:
      return Icons.play_circle_outline;
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final TelemetryMode mode;
  final ValueChanged<TelemetryMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<TelemetryMode>(
            value: mode,
            icon: const Icon(Icons.expand_more),
            style: theme.textTheme.bodyMedium,
            dropdownColor: theme.colorScheme.surface,
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
            items: TelemetryMode.values
                .map(
                  (mode) => DropdownMenuItem(
                    value: mode,
                    child: Row(
                      children: [
                        Icon(
                          _modeIcon(mode),
                          size: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(_modeLabel(mode)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _DashboardBackground extends StatelessWidget {
  const _DashboardBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final tertiary = theme.colorScheme.tertiary;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -140,
          right: -120,
          child: _GlowCircle(
            color: primary.withValues(alpha: 0.18),
            size: 280,
          ),
        ),
        Positioned(
          bottom: -180,
          left: -140,
          child: _GlowCircle(
            color: tertiary.withValues(alpha: 0.18),
            size: 320,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 80,
              spreadRadius: 40,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.child,
    this.accent,
  });

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = accent ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withValues(alpha: 0.95),
            theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.55),
            accentColor.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
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

    return _DashboardCard(
      accent: accent,
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
            const SizedBox(height: 10),
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

    return _DashboardCard(
      accent: Colors.green,
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

    return _DashboardCard(
      accent: theme.colorScheme.primary,
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

    return _DashboardCard(
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 0.6,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TelemetryEmptyState extends StatelessWidget {
  const _TelemetryEmptyState({
    required this.mode,
    required this.hasRecording,
    this.error,
  });

  final TelemetryMode mode;
  final bool hasRecording;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = error != null;

    final title = isError
        ? 'Telemetry stream error'
        : mode == TelemetryMode.acc
            ? 'Waiting for ACC telemetry'
            : mode == TelemetryMode.playback
                ? hasRecording
                    ? 'Starting playback'
                    : 'No recording yet'
                : 'Starting mock telemetry';

    final message = isError
        ? 'We could not read telemetry from the current source.'
        : mode == TelemetryMode.acc
            ? 'Launch ACC and start a session. Telemetry packets will appear here once the game is running.'
            : mode == TelemetryMode.playback
                ? hasRecording
                    ? 'Preparing your last recording for playback.'
                    : 'Record telemetry from ACC or the mock source to enable playback.'
                : 'Generating simulated telemetry so you can explore the dashboard without the game.';

    final icon = isError
        ? Icons.error_outline
        : mode == TelemetryMode.playback
            ? Icons.play_circle_outline
            : Icons.sensors_off;
    final accent = isError ? theme.colorScheme.error : theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 20),
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

class _ConnectionDetailsDrawer extends StatelessWidget {
  const _ConnectionDetailsDrawer({required this.details});

  final ConnectionDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = details.status;
    final connectionStateLabel = details.connectionState
        .toString()
        .split('.')
        .last;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Connection Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Status',
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
                  Expanded(child: Text(status.label)),
                ],
              ),
            ),
            _DetailRow(
              label: 'Source',
              child: Text(_modeLabel(details.mode)),
            ),
            _DetailRow(
              label: 'Stream state',
              child: Text(connectionStateLabel),
            ),
            _DetailRow(
              label: 'Has data',
              child: Text(details.hasData ? 'Yes' : 'No'),
            ),
            _DetailRow(
              label: 'Has error',
              child: Text(details.hasError ? 'Yes' : 'No'),
            ),
            _DetailRow(
              label: 'Error',
              child: Text(details.error?.toString() ?? '--'),
            ),
            _DetailRow(
              label: 'Last packet',
              child: Text(_formatDateTime(details.lastPacketAt)),
            ),
            _DetailRow(
              label: 'Recording',
              child: Text(details.isRecording ? 'Active' : 'Off'),
            ),
            _DetailRow(
              label: 'Recorded frames',
              child: Text(details.recordedFrames.toString()),
            ),
            _DetailRow(
              label: 'Last recorded',
              child: Text(_formatDateTime(details.lastRecordedAt)),
            ),
            if (details.mode == TelemetryMode.acc)
              _DetailRow(
                label: 'ACC UDP port',
                child: Text(details.accPort.toString()),
              ),
            if (details.mode == TelemetryMode.playback)
              _DetailRow(
                label: 'Playback interval',
                child: Text(
                  '${details.playbackInterval.inMilliseconds} ms',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
          Expanded(child: child),
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

String _formatDateTime(DateTime? value) {
  if (value == null) return '--';
  final local = value.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}
