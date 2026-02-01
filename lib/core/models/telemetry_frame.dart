class TelemetryFrame {
  final DateTime timestamp;

  final double speedKph;
  final int rpm;
  final int gear;

  final double throttle;
  final double brake;
  final double steering;

  TelemetryFrame({
    required this.timestamp,
    required this.speedKph,
    required this.rpm,
    required this.gear,
    required this.throttle,
    required this.brake,
    required this.steering,
  });
}
