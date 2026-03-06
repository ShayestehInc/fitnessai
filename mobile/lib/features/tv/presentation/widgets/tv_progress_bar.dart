import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Horizontal progress bar showing workout completion.
///
/// Displays fraction of completed sets and a percentage label.
/// Designed for TV-distance readability.
class TvProgressBar extends StatelessWidget {
  final double fraction;
  final int completedExercises;
  final int totalExercises;

  const TvProgressBar({
    super.key,
    required this.fraction,
    required this.completedExercises,
    required this.totalExercises,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (fraction * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$completedExercises / $totalExercises exercises',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.zinc300,
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.foreground,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 12,
            backgroundColor: AppTheme.zinc700,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      ],
    );
  }
}
