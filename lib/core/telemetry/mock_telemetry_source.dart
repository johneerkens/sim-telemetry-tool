import 'dart:async';
import 'dart:math';

import '../models/telemetry_frame.dart';

class MockTelemetrySource {
  Stream<TelemetryFrame> stream({
    Duration interval = const Duration(milliseconds: 100),
  }) {
    final rng = Random();
    final segments = <_SimSegment>[
      const _SimSegment(
        duration: 4.5,
        throttle: 0.95,
        brake: 0.0,
        steering: 0.05,
      ),
      const _SimSegment(
        duration: 2.2,
        throttle: 0.2,
        brake: 0.65,
        steering: 0.7,
      ),
      const _SimSegment(
        duration: 3.2,
        throttle: 0.7,
        brake: 0.0,
        steering: -0.45,
      ),
      const _SimSegment(
        duration: 4.0,
        throttle: 1.0,
        brake: 0.0,
        steering: 0.0,
      ),
      const _SimSegment(
        duration: 2.6,
        throttle: 0.15,
        brake: 0.85,
        steering: -0.75,
      ),
      const _SimSegment(
        duration: 3.4,
        throttle: 0.8,
        brake: 0.0,
        steering: 0.35,
      ),
    ];

    final dt = interval.inMilliseconds / 1000.0;
    final pedalSmoothing = (dt / 0.35).clamp(0.05, 0.35);
    final steeringSmoothing = (dt / 0.25).clamp(0.1, 0.5);

    var segmentIndex = 0;
    var segmentElapsed = 0.0;

    double throttle = 0.0;
    double brake = 0.0;
    double steering = 0.0;
    double speedKph = 0.0;

    TelemetryFrame nextFrame() {
      final segment = segments[segmentIndex];
      segmentElapsed += dt;

      var throttleTarget =
          (segment.throttle + _jitter(rng, 0.05)).clamp(0.0, 1.0);
      var brakeTarget =
          (segment.brake + _jitter(rng, 0.04)).clamp(0.0, 1.0);
      final steeringTarget =
          (segment.steering + _jitter(rng, 0.06)).clamp(-1.0, 1.0);

      if (brakeTarget > 0.1) {
        throttleTarget *= (1 - brakeTarget).clamp(0.0, 1.0);
      }

      throttle = _approach(throttle, throttleTarget, pedalSmoothing);
      brake = _approach(brake, brakeTarget, pedalSmoothing);
      steering = _approach(steering, steeringTarget, steeringSmoothing);

      final accelKphPerSecond =
          throttle * 38.0 - brake * 65.0 - speedKph * 0.08;
      speedKph = (speedKph + accelKphPerSecond * dt).clamp(0.0, 310.0);

      final gear = _gearForSpeed(speedKph);
      final rpm = _rpmForSpeed(speedKph, gear, rng);

      final frame = TelemetryFrame(
        timestamp: DateTime.now(),
        speedKph: speedKph,
        rpm: rpm,
        gear: gear,
        throttle: throttle,
        brake: brake,
        steering: steering,
      );

      if (segmentElapsed >= segment.duration) {
        segmentElapsed = 0.0;
        segmentIndex = (segmentIndex + 1) % segments.length;
      }

      return frame;
    }

    Timer? timer;
    late final StreamController<TelemetryFrame> controller;

    void emit() {
      controller.add(nextFrame());
    }

    controller = StreamController<TelemetryFrame>(
      onListen: () {
        emit();
        timer = Timer.periodic(interval, (_) => emit());
      },
      onCancel: () {
        timer?.cancel();
      },
    );

    return controller.stream;
  }
}

class _SimSegment {
  const _SimSegment({
    required this.duration,
    required this.throttle,
    required this.brake,
    required this.steering,
  });

  final double duration;
  final double throttle;
  final double brake;
  final double steering;
}

double _approach(double current, double target, double rate) {
  return current + (target - current) * rate;
}

double _jitter(Random rng, double amplitude) {
  return (rng.nextDouble() * 2 - 1) * amplitude;
}

int _gearForSpeed(double speedKph) {
  if (speedKph < 35) return 1;
  if (speedKph < 70) return 2;
  if (speedKph < 110) return 3;
  if (speedKph < 150) return 4;
  if (speedKph < 200) return 5;
  if (speedKph < 245) return 6;
  return 7;
}

int _rpmForSpeed(double speedKph, int gear, Random rng) {
  const gearMaxSpeeds = <double>[35, 70, 110, 150, 200, 245, 295];
  final maxSpeed = gearMaxSpeeds[(gear - 1).clamp(0, gearMaxSpeeds.length - 1)];
  final minSpeed = gear <= 1 ? 0.0 : gearMaxSpeeds[gear - 2];
  final range = (maxSpeed - minSpeed).clamp(1.0, double.infinity);
  final ratio = ((speedKph - minSpeed) / range).clamp(0.0, 1.0);
  final baseRpm = 1200 + ratio * 7000;
  final noise = _jitter(rng, 120);
  return (baseRpm + noise).clamp(900, 9000).toInt();
}
