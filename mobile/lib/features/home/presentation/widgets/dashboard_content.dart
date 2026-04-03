import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/adaptive/adaptive_scroll_physics.dart';
import '../../../workout_log/data/models/workout_models.dart';
import '../providers/home_provider.dart';
import 'activity_rings_card.dart';
import 'dashboard_error_banner.dart';
import 'dashboard_header.dart';
import 'habits_summary_card.dart';
import 'health_metrics_row.dart';
import 'leaderboard_teaser_card.dart';
import 'pending_checkin_banner.dart';
import 'progression_alert_card.dart';
import 'quick_log_card.dart';
import 'todays_workouts_section.dart';
import 'week_calendar_strip.dart';
import 'v65_feature_cards.dart';
import 'weight_log_card.dart';
import '../../../anatomy/presentation/widgets/weekly_coverage_card.dart';

/// Main scrollable dashboard content composed of section widgets.
class DashboardContent extends StatelessWidget {
  final HomeState homeState;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onRetry;

  const DashboardContent({
    super.key,
    required this.homeState,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final workoutDays = _workoutWeekdays(homeState);

    return SingleChildScrollView(
      physics: adaptiveAlwaysScrollablePhysics(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DashboardHeader(),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: WeekCalendarStrip(
              selectedDate: selectedDate,
              workoutDays: workoutDays,
              onDayTapped: onDateChanged,
            ),
          ),
          const SizedBox(height: 8),

          // Conditional banners
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: PendingCheckinBanner(),
          ),
          if (homeState.activeProgram != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProgressionAlertCard(
                programId: homeState.activeProgram!.id,
              ),
            ),

          if (homeState.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: DashboardErrorBanner(
                message: homeState.error!,
                onRetry: onRetry,
              ),
            ),

          if (homeState.activeProgram != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ActiveProgramBanner(program: homeState.activeProgram!),
            ),
          ],

          const SizedBox(height: 16),
          TodaysWorkoutsSection(state: homeState),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: QuickLogCard(),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ActivityRingsCard(homeState: homeState),
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: WeeklyCoverageCard(),
          ),

          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: HabitsSummaryCard(),
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: HealthMetricsRow(),
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: WeightLogCard(),
          ),

          // v6.5 Feature Cards (Performance + AI Tools)
          const V65FeatureSection(),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LeaderboardTeaserCard(),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Set<int> _workoutWeekdays(HomeState state) {
    final days = <int>{};
    for (final w in state.recentWorkouts) {
      try {
        final d = DateTime.parse(w.date);
        days.add(d.weekday);
      } catch (_) {}
    }
    return days;
  }
}

class _ActiveProgramBanner extends StatelessWidget {
  final ProgramModel program;

  const _ActiveProgramBanner({required this.program});

  @override
  Widget build(BuildContext context) {
    final weekNum = program.currentWeekNumber;
    final totalWeeks = program.durationWeeks ?? 0;
    final progress = totalWeeks > 0 ? (weekNum / totalWeeks).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => context.push('/logbook'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fitness_center, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.name,
                    style: const TextStyle(
                      color: AppTheme.foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (program.goalDisplay.isNotEmpty) ...[
                        Text(
                          program.goalDisplay,
                          style: const TextStyle(fontSize: 12, color: AppTheme.zinc400),
                        ),
                        const Text(' · ', style: TextStyle(color: AppTheme.zinc500)),
                      ],
                      Text(
                        program.difficultyDisplay,
                        style: const TextStyle(fontSize: 12, color: AppTheme.zinc400),
                      ),
                      if (totalWeeks > 0) ...[
                        const Text(' · ', style: TextStyle(color: AppTheme.zinc500)),
                        Text(
                          'Week $weekNum of $totalWeeks',
                          style: const TextStyle(fontSize: 12, color: AppTheme.primary),
                        ),
                      ],
                    ],
                  ),
                  if (totalWeeks > 0) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppTheme.zinc700,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppTheme.zinc500, size: 20),
          ],
        ),
      ),
    );
  }
}

