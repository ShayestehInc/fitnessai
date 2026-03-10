import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Visual form score gauge (0-10) with a colored arc.
class FormScoreGauge extends StatelessWidget {
  final double score;
  final double size;

  const FormScoreGauge({
    super.key,
    required this.score,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _scoreColor(score);
    final label = _scoreLabel(score);

    return SizedBox(
      width: size,
      height: size * 0.65,
      child: CustomPaint(
        painter: _GaugePainter(
          score: score,
          maxScore: 10,
          activeColor: color,
          trackColor: theme.dividerColor,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(1),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _scoreColor(double score) {
    if (score >= 8) return const Color(0xFF22C55E);
    if (score >= 6) return const Color(0xFF3B82F6);
    if (score >= 4) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  static String _scoreLabel(double score) {
    if (score >= 8) return 'Excellent';
    if (score >= 6) return 'Good';
    if (score >= 4) return 'Fair';
    return 'Needs Work';
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final double maxScore;
  final Color activeColor;
  final Color trackColor;

  _GaugePainter({
    required this.score,
    required this.maxScore,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 12;
    const strokeWidth = 12.0;
    const startAngle = math.pi;
    const sweepAngle = math.pi;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active arc
    final fraction = (score / maxScore).clamp(0.0, 1.0);
    final activeSweep = sweepAngle * fraction;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweep,
      false,
      activePaint,
    );

    // Thumb dot
    final thumbAngle = startAngle + activeSweep;
    final thumbX = center.dx + radius * math.cos(thumbAngle);
    final thumbY = center.dy + radius * math.sin(thumbAngle);

    final thumbPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(thumbX, thumbY), 8, thumbPaint);

    final thumbBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset(thumbX, thumbY), 8, thumbBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      score != oldDelegate.score ||
      activeColor != oldDelegate.activeColor;
}
