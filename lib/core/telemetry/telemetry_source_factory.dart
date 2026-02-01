import 'dart:async';

import '../models/telemetry_frame.dart';
import 'mock_telemetry_source.dart';

Stream<TelemetryFrame> createTelemetryStream() {
  // OFFLINE MODE (current)
  return MockTelemetrySource().stream();

  // ONLINE MODE (later)
  // final manager = TelemetryManager(AccAdapter());
  // await manager.start();
  // return manager.stream;
}
