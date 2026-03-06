import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/adaptive/adaptive_icons.dart';
import '../../../../shared/widgets/adaptive/adaptive_refresh_indicator.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../data/models/calendar_connection_model.dart';
import '../providers/calendar_provider.dart';
import '../widgets/calendar_event_tile.dart';
import '../widgets/calendar_no_connection_view.dart';
import '../widgets/calendar_provider_filter.dart';
import '../../../../core/l10n/l10n_extension.dart';

class CalendarEventsScreen extends ConsumerStatefulWidget {
  const CalendarEventsScreen({super.key});

  @override
  ConsumerState<CalendarEventsScreen> createState() => _CalendarEventsScreenState();
}

class _CalendarEventsScreenState extends ConsumerState<CalendarEventsScreen> {
  String? _providerFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(calendarProvider.notifier).loadConnections();
      final state = ref.read(calendarProvider);
      if (state.hasAnyConnection) {
        ref.read(calendarProvider.notifier).loadEvents();
      }
    });
  }

  Future<void> _syncAndReload() async {
    final state = ref.read(calendarProvider);
    final notifier = ref.read(calendarProvider.notifier);
    // Run syncs sequentially to avoid concurrent state mutations
    // that cause isLoading flickering.
    if (state.hasGoogleConnected) {
      await notifier.syncCalendar('google');
    }
    if (state.hasMicrosoftConnected) {
      await notifier.syncCalendar('microsoft');
    }
    await notifier.loadEvents(provider: _providerFilter);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarProvider);
    final theme = Theme.of(context);

    ref.listen<CalendarState>(calendarProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        showAdaptiveToast(context, message: next.error!, type: ToastType.error);
        ref.read(calendarProvider.notifier).clearMessages();
      }
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        showAdaptiveToast(context, message: next.successMessage!, type: ToastType.success);
        ref.read(calendarProvider.notifier).clearMessages();
      }
    });

    if (state.connectionsLoaded && !state.hasAnyConnection) {
      return CalendarNoConnectionView(onGoBack: () => context.pop());
    }

    final events = state.events;
    final grouped = _groupByDate(events);
    final dateKeys = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.calendarCalendarEvents),
        leading: IconButton(
          icon: Icon(AdaptiveIcons.back),
          onPressed: () => context.pop(),
          tooltip: context.l10n.calendarBackToCalendarSettings,
        ),
      ),
      body: Column(
        children: [
          if (state.hasGoogleConnected && state.hasMicrosoftConnected)
            CalendarProviderFilter(
              selected: _providerFilter,
              onChanged: _setFilter,
            ),
          Expanded(
            child: state.isLoading && events.isEmpty
                ? _buildLoadingShimmer()
                : AdaptiveRefreshIndicator(
                    onRefresh: _syncAndReload,
                    child: events.isEmpty
                        ? _buildEmpty(theme)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: dateKeys.length,
                            itemBuilder: (context, index) {
                              final date = dateKeys[index];
                              final dayEvents = grouped[date]!;
                              return _buildDateSection(theme, date, dayEvents);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _setFilter(String? provider) async {
    final previous = _providerFilter;
    final previousEvents = ref.read(calendarProvider).events;
    setState(() => _providerFilter = provider);
    await ref.read(calendarProvider.notifier).loadEvents(provider: provider);
    if (!mounted) return;
    // If events didn't change and there were events before, the load likely
    // failed (the listener already showed the error toast). Revert the filter.
    final currentState = ref.read(calendarProvider);
    if (identical(currentState.events, previousEvents) &&
        previousEvents.isNotEmpty &&
        provider != previous) {
      setState(() => _providerFilter = previous);
    }
  }

  Map<String, List<CalendarEventModel>> _groupByDate(
      List<CalendarEventModel> events) {
    final map = <String, List<CalendarEventModel>>{};
    for (final event in events) {
      final key = DateFormat('yyyy-MM-dd').format(event.startTime);
      map.putIfAbsent(key, () => []).add(event);
    }
    // Sort events within each group by start time
    for (final list in map.values) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    return map;
  }

  Widget _buildDateSection(
      ThemeData theme, String dateKey, List<CalendarEventModel> events) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final label = isToday ? 'Today' : DateFormat('EEEE, MMM d').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isToday ? theme.colorScheme.primary : null,
            ),
          ),
        ),
        ...events.map((e) => CalendarEventTile(event: e)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Semantics(
            label: context.l10n.calendarNoUpcomingEventsPullDownToSyncYourCalendar,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    semanticLabel: context.l10n.calendarNoEvents),
                const SizedBox(height: 16),
                Text(context.l10n.calendarNoUpcomingEvents, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Pull down to sync your calendar',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingShimmer(width: 120, height: 16, borderRadius: 4),
          const SizedBox(height: 12),
          for (int i = 0; i < 3; i++) ...[
            const Row(
              children: [
                LoadingShimmer(width: 56, height: 36, borderRadius: 6),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingShimmer(height: 16, borderRadius: 4),
                      SizedBox(height: 6),
                      LoadingShimmer(width: 100, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 20),
          const LoadingShimmer(width: 140, height: 16, borderRadius: 4),
          const SizedBox(height: 12),
          for (int i = 0; i < 2; i++) ...[
            const Row(
              children: [
                LoadingShimmer(width: 56, height: 36, borderRadius: 6),
                SizedBox(width: 12),
                Expanded(
                  child: LoadingShimmer(height: 16, borderRadius: 4),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
