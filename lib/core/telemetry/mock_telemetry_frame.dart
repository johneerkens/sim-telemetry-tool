import 'dart:async';
import '../models/telemetry_frame.dart';

class MockTelemetrySource {
  Stream<TelemetryFrame> stream({Duration interval = const Duration(milliseconds: 100)}) async* {
    double throttle = 0.0;
    double brake = 0.0;

    while (true) {
      throttle = (throttle + 0.05) % 1.0;
      brake = (1.0 - throttle).clamp(0.0, 1.0);

      yield TelemetryFrame(
        timestamp: DateTime.now(),
        speedKph: throttle * 280,
        rpm: (throttle * 8000).toInt(),
        gear: (throttle * 7).clamp(1, 7).toInt(),
        throttle: throttle,
        brake: brake,
        steering: 0.0,
      );

      await Future.delayed(interval);
    }
  }
}
