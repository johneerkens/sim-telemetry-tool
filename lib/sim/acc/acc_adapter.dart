import 'dart:async';

import '../adapters/sim_adapter.dart';
import '../../core/models/sim_capabilities.dart';
import '../../core/models/telemetry_frame.dart';

class AccAdapter implements SimAdapter {
  final StreamController<TelemetryFrame> _telemetryController =
      StreamController<TelemetryFrame>.broadcast();

  bool _connected = false;

  @override
  String get simName => 'Assetto Corsa Competizione';

  @override
  String get simId => 'acc';

  @override
  SimCapabilities get capabilities => const SimCapabilities(
        liveTelemetry: true,
        replayTelemetry: false,
        setupEditing: SetupEditLevel.full,
        setupImport: true,
      );

  @override
  Future<void> connect() async {
    if (_connected) return;
    _connected = true;
    // Telemetry source will be wired here later (UDP).
  }

  @override
  Future<void> disconnect() async {
    if (!_connected) return;
    _connected = false;
    await _telemetryController.close();
  }

  @override
  Stream<TelemetryFrame> telemetryStream() {
    return _telemetryController.stream;
  }
}
