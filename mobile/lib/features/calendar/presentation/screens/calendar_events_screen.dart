import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/calendar_connection_model.dart';
import '../providers/calendar_provider.dart';
import '../widgets/calendar_event_tile.dart';
import '../widgets/calendar_no_connection_view.dart';
import '../widgets/calendar_provider_filter.dart';

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
      ref.read(calendarProvider.notifier).loadEvents();
    });
  }

  Future<void> _syncAndReload() async {
    final state = ref.read(calendarProvider);
    final futures = <Future<void>>[];
    if (state.hasGoogleConnected) {
      futures.add(ref.read(calendarProvider.notifier).syncCalendar('google'));
    }
    if (state.hasMicrosoftConnected) {
      futures.add(ref.read(calendarProvider.notifier).syncCalendar('microsoft'));
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
    await ref.read(calendarProvider.notifier).loadEvents(provider: _providerFilter);
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
        title: const Text('Calendar Events'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
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
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
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
    setState(() => _providerFilter = provider);
    await ref.read(calendarProvider.notifier).loadEvents(provider: provider);
    final state = ref.read(calendarProvider);
    if (state.error != null && mounted) {
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('No upcoming events', style: theme.textTheme.titleMedium),
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
    );
  }
}
