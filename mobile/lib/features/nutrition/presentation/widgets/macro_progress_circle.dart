import 'package:flutter/material.dart';
import 'dart:math' as math;

class MacroProgressCircle extends StatelessWidget {
  final String label;
  final int current;
  final int goal;
  final int remaining;
  final Color color;
  final double size;
  final bool showRemaining;

  const MacroProgressCircle({
    super.key,
    required this.label,
    required this.current,
    required this.goal,
    required this.remaining,
    required this.color,
    this.size = 100,
    this.showRemaining = true,
  });

  double get progress {
    if (goal == 0) return 0;
    return (current / goal).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CircleProgressPainter(
              progress: progress,
              color: color,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              strokeWidth: size * 0.1,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    showRemaining ? '$remaining' : '$current',
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    showRemaining ? 'left' : 'g',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: size * 0.12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '$current / $goal g',
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _CircleProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class CalorieProgressCircle extends StatelessWidget {
  final int consumed;
  final int goal;
  final double size;

  const CalorieProgressCircle({
    super.key,
    required this.consumed,
    required this.goal,
    this.size = 180,
  });

  int get remaining => (goal - consumed).clamp(0, goal);
  double get progress => goal == 0 ? 0 : (consumed / goal).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CircleProgressPainter(
          progress: progress,
          color: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          strokeWidth: size * 0.08,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$remaining',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: size * 0.25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'calories left',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: size * 0.08,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$consumed / $goal',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: size * 0.07,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
