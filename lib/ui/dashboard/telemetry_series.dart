class TelemetrySeries {
  TelemetrySeries({required this.maxPoints});

  final int maxPoints;
  final List<double> _values = [];

  List<double> get values => List.unmodifiable(_values);

  void add(double value) {
    _values.add(value);
    if (_values.length > maxPoints) {
      _values.removeAt(0);
    }
  }
}
