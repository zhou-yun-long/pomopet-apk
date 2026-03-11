import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A simple tomato-style progress ring.
///
/// Feed [progress] in [0..1].
class TomatoProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double stroke;
  final Color trackColor;
  final List<Color> gradient;

  const TomatoProgressRing({
    super.key,
    required this.progress,
    this.size = 220,
    this.stroke = 18,
    this.trackColor = const Color(0xFFFFE2DD),
    this.gradient = const [Color(0xFFFF4D3A), Color(0xFFFF8A5B)],
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _RingPainter(
        progress: progress.clamp(0.0, 1.0),
        stroke: stroke,
        trackColor: trackColor,
        gradient: gradient,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double stroke;
  final Color trackColor;
  final List<Color> gradient;

  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.trackColor,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);

    final sweep = math.pi * 2 * progress;
    final shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + sweep,
      colors: gradient,
    ).createShader(rect);

    final progPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = shader;

    canvas.drawArc(rect, -math.pi / 2, sweep, false, progPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.stroke != stroke ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.gradient != gradient;
  }
}
