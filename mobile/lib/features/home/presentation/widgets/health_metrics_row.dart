import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/health_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../constants/dashboard_colors.dart';

/// Side-by-side Heart Rate and Sleep cards.
class HealthMetricsRow extends ConsumerWidget {
  const HealthMetricsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthDataProvider);
    final metrics = healthState is HealthDataLoaded ? healthState.metrics : null;

    return Row(
      children: [
        Expanded(child: _HeartRateCard(bpm: metrics?.heartRate)),
        const SizedBox(width: 12),
        const Expanded(child: _SleepCard()),
      ],
    );
  }
}

class _HeartRateCard extends StatelessWidget {
  final int? bpm;
  const _HeartRateCard({this.bpm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: DashboardColors.heartRate, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Heart',
                style: TextStyle(
                  color: AppTheme.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                bpm != null ? '$bpm' : '--',
                style: const TextStyle(
                  color: AppTheme.foreground,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'BPM',
              style: TextStyle(color: AppTheme.mutedForeground, fontSize: 11),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 30,
            width: double.infinity,
            child: CustomPaint(
              painter: _HeartWavePainter(
                color: DashboardColors.heartRate.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepCard extends StatelessWidget {
  const _SleepCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.nightlight_round, color: DashboardColors.sleepAccent, size: 16),
              SizedBox(width: 6),
              Text(
                'Sleep',
                style: TextStyle(
                  color: AppTheme.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Spacer(),
              Text(
                '-- h -- m',
                style: TextStyle(
                  color: AppTheme.zinc500,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Placeholder colored bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(height: 8, color: DashboardColors.sleepAccent.withValues(alpha: 0.4)),
                ),
                Expanded(
                  flex: 2,
                  child: Container(height: 8, color: const Color(0xFFEAB308).withValues(alpha: 0.4)),
                ),
                Expanded(
                  flex: 2,
                  child: Container(height: 8, color: DashboardColors.activityRing.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Coming Soon',
              style: TextStyle(
                color: AppTheme.zinc500,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple sine wave painter for heart rate decoration.
class _HeartWavePainter extends CustomPainter {
  final Color color;
  _HeartWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final midY = size.height / 2;
    const amplitude = 10.0;
    const frequency = 3.0;

    path.moveTo(0, midY);
    for (double x = 0; x <= size.width; x += 1) {
      final y = midY + amplitude * math.sin((x / size.width) * frequency * 2 * math.pi);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HeartWavePainter old) => old.color != color;
}
