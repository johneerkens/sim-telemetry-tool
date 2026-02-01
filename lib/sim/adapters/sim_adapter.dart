import '../../core/models/sim_capabilities.dart';
import '../../core/models/telemetry_frame.dart';

abstract class SimAdapter {
  String get simName;
  String get simId;

  SimCapabilities get capabilities;

  Future<void> connect();
  Future<void> disconnect();

  Stream<TelemetryFrame> telemetryStream();
}
