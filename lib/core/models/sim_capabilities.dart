enum SetupEditLevel {
  none,
  partial,
  full,
}

class SimCapabilities {
  final bool liveTelemetry;
  final bool replayTelemetry;
  final SetupEditLevel setupEditing;
  final bool setupImport;

  const SimCapabilities({
    required this.liveTelemetry,
    required this.replayTelemetry,
    required this.setupEditing,
    required this.setupImport,
  });
}
