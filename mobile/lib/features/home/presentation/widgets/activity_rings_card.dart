import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/health_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../constants/dashboard_colors.dart';
import '../providers/home_provider.dart';
import 'activity_ring_painter.dart';

/// Apple Watch-style triple concentric activity rings card.
class ActivityRingsCard extends ConsumerWidget {
  final HomeState homeState;
  const ActivityRingsCard({super.key, required this.homeState});

  static final _fmt = NumberFormat('#,###');
  static const _stepsGoal = 10000;
  static const _activityGoal = 60;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthDataProvider);
    final metrics = healthState is HealthDataLoaded ? healthState.metrics : null;

    final caloriesConsumed = homeState.caloriesConsumed;
    final caloriesGoal = homeState.caloriesGoal;
    final steps = metrics?.steps ?? 0;
    // Rough conversion: ~7 active calories per active minute
    static const _calsPerMinute = 7;
    final activeMinutes = ((metrics?.activeCalories ?? 0) / _calsPerMinute).round();

    final calProgress = caloriesGoal > 0 ? caloriesConsumed / caloriesGoal : 0.0;
    final stepProgress = steps / _stepsGoal;
    final actProgress = activeMinutes / _activityGoal;

    final hasHealthData = metrics != null;
    final hasNutritionGoals = caloriesGoal > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (!hasNutritionGoals)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Nutrition goals not set',
                style: TextStyle(color: AppTheme.zinc500, fontSize: 12),
              ),
            ),
          // Rings
          RepaintBoundary(
            child: SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: ActivityRingPainter(
                  outerProgress: calProgress.clamp(0.0, 1.0),
                  middleProgress: hasHealthData ? stepProgress.clamp(0.0, 1.0) : 0.0,
                  innerProgress: hasHealthData ? actProgress.clamp(0.0, 1.0) : 0.0,
                  outerColor: DashboardColors.caloriesRing,
                  middleColor: DashboardColors.stepsRing,
                  innerColor: DashboardColors.activityRing,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Stat row
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  color: DashboardColors.caloriesRing,
                  value: _fmt.format(caloriesConsumed),
                  goal: '/ ${_fmt.format(caloriesGoal)} Cal',
                  label: 'Calories',
                ),
              ),
              Expanded(
                child: hasHealthData
                    ? _StatColumn(
                        color: DashboardColors.stepsRing,
                        value: _fmt.format(steps),
                        goal: '/ ${_fmt.format(_stepsGoal)}',
                        label: 'Steps',
                      )
                    : const _ConnectHealthPrompt(label: 'Steps'),
              ),
              Expanded(
                child: hasHealthData
                    ? _StatColumn(
                        color: DashboardColors.activityRing,
                        value: '$activeMinutes',
                        goal: '/ $_activityGoal min',
                        label: 'Activity',
                      )
                    : const _ConnectHealthPrompt(label: 'Activity'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final Color color;
  final String value;
  final String goal;
  final String label;

  const _StatColumn({
    required this.color,
    required this.value,
    required this.goal,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: AppTheme.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: ' $goal',
                style: const TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConnectHealthPrompt extends ConsumerWidget {
  final String label;
  const _ConnectHealthPrompt({required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(healthDataProvider.notifier).requestOsPermission(),
      child: Column(
        children: [
          const Text(
            '--',
            style: TextStyle(color: AppTheme.zinc500, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.zinc500, fontSize: 10),
          ),
          const SizedBox(height: 2),
          const Text(
            'Connect Health',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
