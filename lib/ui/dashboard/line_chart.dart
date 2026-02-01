import 'package:flutter/material.dart';

class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.values,
    required this.min,
    required this.max,
    required this.color,
  });

  final List<double> values;
  final double min;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(values, min, max, color),
      size: const Size(double.infinity, 120),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.values, this.min, this.max, this.color);

  final List<double> values;
  final double min;
  final double max;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final dx = size.width / (values.length - 1);

    for (var i = 0; i < values.length; i++) {
      final norm = ((values[i] - min) / (max - min)).clamp(0.0, 1.0);
      final x = i * dx;
      final y = size.height * (1 - norm);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
