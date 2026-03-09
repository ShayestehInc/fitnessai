import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/health_provider.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../../shared/widgets/adaptive/adaptive_refresh_indicator.dart';
import '../../../../shared/widgets/health_permission_sheet.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../../community/presentation/providers/announcement_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/dashboard_content.dart';
import '../widgets/dashboard_shimmer.dart';
import '../../../../core/l10n/l10n_extension.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isRefreshing = false;

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
    if (wasAsked || !mounted) return;

    final userWantsToConnect = await showHealthPermissionSheet(context);
    if (userWantsToConnect) {
      await healthNotifier.requestOsPermission();
    } else {
      await healthNotifier.declinePermission();
    }
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      await ref.read(homeStateProvider.notifier).loadDashboardData();
      final healthState = ref.read(healthDataProvider);
      if (healthState is HealthDataLoaded || healthState is HealthDataLoading) {
        ref.read(healthDataProvider.notifier).fetchHealthData(isRefresh: true);
      }
    } finally {
      _isRefreshing = false;
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

    final showShimmer = homeState.isLoading && homeState.activeProgram == null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: AdaptiveRefreshIndicator(
                onRefresh: _onRefresh,
                child: showShimmer
                    ? const DashboardShimmer()
                    : DashboardContent(
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
