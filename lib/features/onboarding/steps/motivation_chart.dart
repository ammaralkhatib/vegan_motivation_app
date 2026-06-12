import 'package:flutter/material.dart';

/// S17 — a simple two-curve chart: motivation rising "with veggie" vs sagging
/// "on willpower alone". Pure CustomPaint, no chart package.
class MotivationChart extends StatelessWidget {
  const MotivationChart({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 170,
          child: CustomPaint(
            size: Size.infinite,
            painter: _ChartPainter(
              withColor: theme.colorScheme.primary,
              willpowerColor: theme.colorScheme.outline,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Legend(
          color: theme.colorScheme.primary,
          label: 'with veggie',
        ),
        const SizedBox(height: 6),
        _Legend(
          color: theme.colorScheme.outline,
          label: 'on willpower alone',
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 18,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.withColor, required this.willpowerColor});

  final Color withColor;
  final Color willpowerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Baseline axis.
    final axis = Paint()
      ..color = willpowerColor.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, h - 1), Offset(w, h - 1), axis);

    Path curve(double Function(double t) yOf) {
      final path = Path();
      for (var i = 0; i <= 40; i++) {
        final t = i / 40;
        final x = t * w;
        final y = (1 - yOf(t)) * (h - 8) + 4;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      return path;
    }

    final withPaint = Paint()
      ..color = withColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Rising, with gentle waves — trends up to ~0.9.
    canvas.drawPath(
      curve((t) => 0.25 + 0.6 * t + 0.05 * _wave(t)),
      withPaint,
    );

    final willpowerPaint = Paint()
      ..color = willpowerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Sagging — starts hopeful, drifts down to ~0.2.
    canvas.drawPath(
      curve((t) => 0.55 - 0.35 * t - 0.08 * _wave(t * 1.3)),
      willpowerPaint,
    );
  }

  // Small bounded wiggle without importing dart:math.
  double _wave(double t) {
    final x = (t * 6) % 2 - 1; // -1..1 triangle
    return 1 - 2 * (x < 0 ? -x : x); // peak in the middle of each period
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) =>
      oldDelegate.withColor != withColor ||
      oldDelegate.willpowerColor != willpowerColor;
}
