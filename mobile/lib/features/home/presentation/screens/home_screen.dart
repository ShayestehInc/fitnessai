import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/health_provider.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../../shared/widgets/adaptive/adaptive_refresh_indicator.dart';
import '../../../../shared/widgets/adaptive/adaptive_scroll_physics.dart';
import '../../../../shared/widgets/health_permission_sheet.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../../community/presentation/providers/announcement_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/activity_rings_card.dart';
import '../widgets/dashboard_error_banner.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_shimmer.dart';
import '../widgets/habits_summary_card.dart';
import '../widgets/health_metrics_row.dart';
import '../widgets/leaderboard_teaser_card.dart';
import '../widgets/pending_checkin_banner.dart';
import '../widgets/progression_alert_card.dart';
import '../widgets/quick_log_card.dart';
import '../widgets/todays_workouts_section.dart';
import '../widgets/week_calendar_strip.dart';
import '../widgets/weight_log_card.dart';
import '../../../../core/l10n/l10n_extension.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeStateProvider.notifier).loadDashboardData();
      ref.read(announcementProvider.notifier).loadUnreadCount();
      _initHealthData();
    });
  }

  Future<void> _initHealthData() async {
    final healthNotifier = ref.read(healthDataProvider.notifier);
    final alreadyGranted = await healthNotifier.checkAndRequestPermission();
    if (alreadyGranted) return;

    final wasAsked = await healthNotifier.wasPermissionAsked();
    if (wasAsked) return;

    if (!mounted) return;
    final userWantsToConnect = await showHealthPermissionSheet(context);
    if (userWantsToConnect) {
      await healthNotifier.requestOsPermission();
    } else {
      await healthNotifier.declinePermission();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(homeStateProvider.notifier).loadDashboardData();
    final healthState = ref.read(healthDataProvider);
    if (healthState is HealthDataLoaded || healthState is HealthDataLoading) {
      ref.read(healthDataProvider.notifier).fetchHealthData(isRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeStateProvider);

    ref.listen(syncCompletionProvider, (_, next) {
      if (next.valueOrNull == true) {
        ref.read(homeStateProvider.notifier).loadDashboardData();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: AdaptiveRefreshIndicator(
                onRefresh: _onRefresh,
                child: homeState.isLoading && homeState.activeProgram == null
                    ? const DashboardShimmer()
                    : _DashboardContent(
                        homeState: homeState,
                        selectedDate: _selectedDate,
                        onDateChanged: (d) => setState(() => _selectedDate = d),
                        onRetry: _onRefresh,
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Theme.of(context).platform == TargetPlatform.iOS
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/ai-command'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              icon: const Icon(Icons.mic),
              label: Text(context.l10n.homeLog),
            ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final HomeState homeState;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onRetry;

  const _DashboardContent({
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

          // Today's Workouts (full-bleed horizontal scroll)
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

          const SizedBox(height: 80), // FAB clearance
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
        // Ignore invalid dates
      }
    }
    return days;
  }
}
