class CarSetup {
  final String id;
  final String carId;
  final String trackId;
  final String name;
  final DateTime createdAt;
  final Map<String, dynamic> parameters;

  CarSetup({
    required this.id,
    required this.carId,
    required this.trackId,
    required this.name,
    required this.createdAt,
    required this.parameters,
  });
}
