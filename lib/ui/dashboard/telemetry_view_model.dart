import '../../core/models/telemetry_frame.dart';

class TelemetryViewModel {
  final double speedKph;
  final int rpm;
  final int gear;
  final double throttle;
  final double brake;

  TelemetryViewModel.fromFrame(TelemetryFrame f)
      : speedKph = f.speedKph,
        rpm = f.rpm,
        gear = f.gear,
        throttle = f.throttle,
        brake = f.brake;
}
