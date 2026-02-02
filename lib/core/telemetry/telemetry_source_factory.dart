import '../models/telemetry_frame.dart';
import 'mock_telemetry_source.dart';
import 'telemetry_mode.dart';
import '../../sim/acc/acc_adapter.dart';
import 'telemetry_manager.dart';

TelemetryMode telemetryMode = TelemetryMode.mock;

Stream<TelemetryFrame> createTelemetryStream() {
  switch (telemetryMode) {
    case TelemetryMode.acc:
      final manager = TelemetryManager(AccAdapter());
      manager.start();
      return manager.stream;
    case TelemetryMode.mock:
      return MockTelemetrySource().stream();
  }
}
