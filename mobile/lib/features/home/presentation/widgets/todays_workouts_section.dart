import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/home_provider.dart';
import 'dashboard_section_header.dart';
import 'workout_card.dart';

/// Horizontal scrollable section showing today's scheduled workouts.
class TodaysWorkoutsSection extends StatelessWidget {
  final HomeState state;

  const TodaysWorkoutsSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DashboardSectionHeader(
            title: "Today's Workouts",
            actionLabel: state.activeProgram != null ? 'View All' : null,
            onAction: state.activeProgram != null
                ? () => context.push('/logbook')
                : null,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: _buildContent(context),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (state.activeProgram == null) {
      return _buildEmptyState(context);
    }

    final workouts = _extractTodaysWorkouts();
    if (workouts.isEmpty) {
      return _buildRestDay();
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: workouts.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, i) {
        final w = workouts[i];
        return WorkoutCard(
          workoutName: w.name,
          programName: state.activeProgram!.name,
          difficulty: w.difficulty,
          durationMinutes: w.estimatedMinutes,
          onTap: () => context.push('/logbook'),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border, width: 1),
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.card,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, color: AppTheme.mutedForeground, size: 40),
            SizedBox(height: 12),
            Text(
              'No program assigned',
              style: TextStyle(
                color: AppTheme.foreground,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Your trainer will assign one soon',
              style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestDay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.card,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.self_improvement, color: AppTheme.primary, size: 48),
            SizedBox(height: 12),
            Text(
              'Rest Day',
              style: TextStyle(
                color: AppTheme.foreground,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Recovery is part of the process',
              style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  List<_WorkoutInfo> _extractTodaysWorkouts() {
    final program = state.activeProgram;
    if (program == null) return [];

    final schedule = program.schedule;
    if (schedule == null) return [];

    final now = DateTime.now();
    final dayNames = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
    ];
    final todayName = dayNames[now.weekday - 1];

    final workouts = <_WorkoutInfo>[];
    try {
      final weeks = schedule is List ? schedule : (schedule['weeks'] as List?) ?? [];
      for (final week in weeks) {
        final days = (week is Map ? week['days'] : null) as List? ?? [];
        for (final day in days) {
          if (day is Map && (day['day'] as String?)?.toLowerCase() == todayName) {
            final exercises = (day['exercises'] as List?) ?? [];
            final name = (day['name'] as String?) ?? todayName.substring(0, 1).toUpperCase() + todayName.substring(1);
            workouts.add(_WorkoutInfo(
              name: name,
              difficulty: 'Intermediate',
              estimatedMinutes: exercises.length * 5,
            ));
          }
        }
      }
    } catch (_) {
      // Gracefully handle malformed schedule JSON
    }

    if (workouts.isEmpty && !state.todayIsRestDay) {
      // Fallback: show next workout info if available
      if (state.nextWorkout != null) {
        workouts.add(_WorkoutInfo(
          name: state.nextWorkout!.dayName,
          difficulty: 'Intermediate',
          estimatedMinutes: state.nextWorkout!.exercises.length * 5,
        ));
      }
    }

    return workouts;
  }
}

class _WorkoutInfo {
  final String name;
  final String difficulty;
  final int? estimatedMinutes;
  const _WorkoutInfo({
    required this.name,
    required this.difficulty,
    this.estimatedMinutes,
  });
}
