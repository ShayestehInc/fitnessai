import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../constants/dashboard_colors.dart';

/// Single workout card for Today's Workouts horizontal scroll.
class WorkoutCard extends StatelessWidget {
  final String workoutName;
  final String programName;
  final String difficulty;
  final int? durationMinutes;
  final VoidCallback? onTap;

  const WorkoutCard({
    super.key,
    required this.workoutName,
    required this.programName,
    required this.difficulty,
    this.durationMinutes,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = _badgeColor(difficulty);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 240,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background pattern with difficulty accent
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: _PatternPainter(accentColor: badgeColor),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Difficulty badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      difficulty,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Workout name
                  Text(
                    workoutName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Program name
                  Text(
                    programName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Duration circle
            if (durationMinutes != null)
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$durationMinutes\nmin',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _badgeColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return DashboardColors.beginnerBadge;
      case 'advanced':
        return DashboardColors.advancedBadge;
      default:
        return DashboardColors.intermediateBadge;
    }
  }
}

/// Draws a subtle geometric grid pattern over the card background.
class _PatternPainter extends CustomPainter {
  final Color accentColor;
  _PatternPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) => old.accentColor != accentColor;
}
