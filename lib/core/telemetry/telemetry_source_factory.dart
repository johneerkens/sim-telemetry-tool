import 'dart:async';

import '../models/telemetry_frame.dart';
import 'mock_telemetry_source.dart';
import 'telemetry_mode.dart';
import '../../sim/acc/acc_adapter.dart';
import 'telemetry_manager.dart';

class TelemetryStreamHandle {
  TelemetryStreamHandle({required this.stream, this.dispose});

  final Stream<TelemetryFrame> stream;
  final Future<void> Function()? dispose;
}

TelemetryStreamHandle createTelemetryStream(
  TelemetryMode mode, {
  List<TelemetryFrame> playbackFrames = const [],
  Duration playbackInterval = const Duration(milliseconds: 100),
}) {
  switch (mode) {
    case TelemetryMode.acc:
      final manager = TelemetryManager(AccAdapter());
      unawaited(manager.start());
      return TelemetryStreamHandle(
        stream: manager.stream,
        dispose: manager.stop,
      );
    case TelemetryMode.mock:
      return TelemetryStreamHandle(
        stream: MockTelemetrySource().stream(),
      );
    case TelemetryMode.playback:
      if (playbackFrames.isEmpty) {
        return TelemetryStreamHandle(stream: Stream<TelemetryFrame>.empty());
      }

      final stream = Stream<TelemetryFrame>.periodic(
        playbackInterval,
        (index) {
          final frame = playbackFrames[index % playbackFrames.length];
          return TelemetryFrame(
            timestamp: DateTime.now(),
            speedKph: frame.speedKph,
            rpm: frame.rpm,
            gear: frame.gear,
            throttle: frame.throttle,
            brake: frame.brake,
            steering: frame.steering,
          );
        },
      ).asBroadcastStream();

      return TelemetryStreamHandle(stream: stream);
  }
}
