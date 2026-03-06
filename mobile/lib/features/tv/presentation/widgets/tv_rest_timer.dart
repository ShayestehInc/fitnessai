import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/tv_mode_provider.dart';

/// Large countdown timer displayed during rest periods.
///
/// Shows remaining seconds in huge text with a circular progress
/// indicator. Designed to be visible from 10+ feet away.
class TvRestTimer extends StatelessWidget {
  final int secondsRemaining;
  final int totalSeconds;
  final VoidCallback onSkip;
  final ValueChanged<int> onChangeDuration;

  const TvRestTimer({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
    required this.onSkip,
    required this.onChangeDuration,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        totalSeconds > 0 ? secondsRemaining / totalSeconds : 0.0;
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final timeStr = minutes > 0
        ? '$minutes:${seconds.toString().padLeft(2, '0')}'
        : '$seconds';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'REST',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 24),
        // Circular countdown
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.zinc700,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _timerColor(secondsRemaining),
                  ),
                ),
              ),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: _timerColor(secondsRemaining),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Skip button
        SizedBox(
          width: 200,
          height: 56,
          child: ElevatedButton(
            onPressed: onSkip,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.zinc700,
              foregroundColor: AppTheme.foreground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'SKIP REST',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Duration selector
        _buildDurationSelector(),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: kRestDurationOptions.map((duration) {
        final isSelected = duration == totalSeconds;
        final label = duration >= 60
            ? '${duration ~/ 60}:${(duration % 60).toString().padLeft(2, '0')}'
            : '${duration}s';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => onChangeDuration(duration),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : AppTheme.zinc800,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.zinc700,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppTheme.primary : AppTheme.zinc400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _timerColor(int seconds) {
    if (seconds <= 5) return const Color(0xFFEF4444);
    if (seconds <= 10) return const Color(0xFFF59E0B);
    return AppTheme.primary;
  }
}
