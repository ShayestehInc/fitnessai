import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Header bar for TV mode showing program name, day name,
/// elapsed time, and an exit button.
class TvWorkoutHeader extends StatelessWidget {
  final String programName;
  final String dayName;
  final Duration elapsed;
  final VoidCallback onExit;

  const TvWorkoutHeader({
    super.key,
    required this.programName,
    required this.dayName,
    required this.elapsed,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Exit button
        IconButton(
          onPressed: onExit,
          icon: const Icon(Icons.arrow_back_rounded, size: 32),
          color: AppTheme.zinc300,
          tooltip: 'Exit TV Mode',
        ),
        const SizedBox(width: 8),
        // Program + day info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                programName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.foreground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                dayName,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.zinc400,
                ),
              ),
            ],
          ),
        ),
        // Elapsed time
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.zinc800,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, size: 24, color: AppTheme.zinc300),
              const SizedBox(width: 8),
              Text(
                _formatDuration(elapsed),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.foreground,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
