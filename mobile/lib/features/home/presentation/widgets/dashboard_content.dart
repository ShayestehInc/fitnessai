import 'package:flutter/material.dart';
import '../../../../shared/widgets/adaptive/adaptive_scroll_physics.dart';
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
import 'weight_log_card.dart';

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
      } catch (_) {
        // Date parsing is best-effort for dot indicators
      }
    }
    return days;
  }
}
