import 'dart:math' as math;
import 'package:flutter/material.dart';

/// CustomPainter for Apple Watch-style triple concentric activity rings.
class ActivityRingPainter extends CustomPainter {
  final double outerProgress;
  final double middleProgress;
  final double innerProgress;
  final Color outerColor;
  final Color middleColor;
  final Color innerColor;

  ActivityRingPainter({
    required this.outerProgress,
    required this.middleProgress,
    required this.innerProgress,
    required this.outerColor,
    required this.middleColor,
    required this.innerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 12.0;
    const gap = 8.0;
    final outerRadius = (size.width / 2) - strokeWidth / 2;
    final middleRadius = outerRadius - strokeWidth - gap;
    final innerRadius = middleRadius - strokeWidth - gap;

    // Start angle: 12 o'clock = -π/2
    const startAngle = -math.pi / 2;

    _drawRing(canvas, center, outerRadius, outerColor, outerProgress, strokeWidth, startAngle);
    _drawRing(canvas, center, middleRadius, middleColor, middleProgress, strokeWidth, startAngle);
    _drawRing(canvas, center, innerRadius, innerColor, innerProgress, strokeWidth, startAngle);
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double progress,
    double strokeWidth,
    double startAngle,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track (dimmed)
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(ActivityRingPainter old) =>
      old.outerProgress != outerProgress ||
      old.middleProgress != middleProgress ||
      old.innerProgress != innerProgress;
}
