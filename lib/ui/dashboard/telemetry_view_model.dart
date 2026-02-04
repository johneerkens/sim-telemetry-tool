import '../../core/models/telemetry_frame.dart';

class TelemetryViewModel {
  final DateTime timestamp;
  final double speedKph;
  final int rpm;
  final int gear;
  final double throttle;
  final double brake;
  final double steering;

  TelemetryViewModel.fromFrame(TelemetryFrame f)
      : timestamp = f.timestamp,
        speedKph = f.speedKph,
        rpm = f.rpm,
        gear = f.gear,
        throttle = f.throttle,
        brake = f.brake,
        steering = f.steering;
}
