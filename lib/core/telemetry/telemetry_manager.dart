import 'dart:async';

import '../models/telemetry_frame.dart';
import '../../sim/adapters/sim_adapter.dart';

class TelemetryManager {
  TelemetryManager(this._adapter);

  final SimAdapter _adapter;

  StreamSubscription<TelemetryFrame>? _subscription;
  final StreamController<TelemetryFrame> _controller =
      StreamController<TelemetryFrame>.broadcast();

  Stream<TelemetryFrame> get stream => _controller.stream;

  Future<void> start() async {
    await _adapter.connect();

    _subscription = _adapter.telemetryStream().listen(
      _controller.add,
      onError: _controller.addError,
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    await _adapter.disconnect();
    await _controller.close();
  }
}
