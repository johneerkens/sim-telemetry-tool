import 'dart:async';
import 'dart:typed_data';

import 'acc_udp_client.dart';
import '../adapters/sim_adapter.dart';
import '../../core/models/sim_capabilities.dart';
import '../../core/models/telemetry_frame.dart';

class AccAdapter implements SimAdapter {
  final StreamController<TelemetryFrame> _telemetryController =
      StreamController<TelemetryFrame>.broadcast();

  final AccUdpClient _udpClient = AccUdpClient(port: 9000);

  StreamSubscription<Uint8List>? _subscription;
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

    _subscription = _udpClient.bind().listen(_handlePacket);
  }

  @override
  Future<void> disconnect() async {
    if (!_connected) return;
    _connected = false;

    await _subscription?.cancel();
    _udpClient.close();
    await _telemetryController.close();
  }

  @override
  Stream<TelemetryFrame> telemetryStream() {
    return _telemetryController.stream;
  }

  void _handlePacket(Uint8List data) {
    // Minimal safe decoding:
    // ACC packets are binary and versioned.
    // We start with controls only (always present).

    if (data.length < 16) return;

    final buffer = ByteData.sublistView(data);

    // These offsets are stable for ACC broadcast control inputs
    final throttle = buffer.getFloat32(0, Endian.little).clamp(0.0, 1.0);
    final brake = buffer.getFloat32(4, Endian.little).clamp(0.0, 1.0);
    final steering = buffer.getFloat32(8, Endian.little).clamp(-1.0, 1.0);

    final frame = TelemetryFrame(
      timestamp: DateTime.now(),
      speedKph: 0.0, // added next step
      rpm: 0,        // added next step
      gear: 0,       // added next step
      throttle: throttle,
      brake: brake,
      steering: steering,
    );

    _telemetryController.add(frame);
  }
}
