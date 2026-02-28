import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/calendar_connection_model.dart';
import '../providers/calendar_provider.dart';
import '../widgets/calendar_event_tile.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calendarProvider.notifier).loadEvents();
    });
  }

  Future<void> _syncAndReload() async {
    final state = ref.read(calendarProvider);
    // Sync all connected providers
    if (state.hasGoogleConnected) {
      await ref.read(calendarProvider.notifier).syncCalendar('google');
    }
    if (state.hasMicrosoftConnected) {
      await ref.read(calendarProvider.notifier).syncCalendar('microsoft');
    }
    await ref.read(calendarProvider.notifier).loadEvents(provider: _providerFilter);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarProvider);
    final theme = Theme.of(context);

    // Listen for error/success messages
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

    if (!state.hasAnyConnection && !state.isLoading) {
      return _buildNoConnection(context, theme);
    }

    final events = state.events;
    final grouped = _groupByDate(events);

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
          // Provider filter chips
          if (state.hasGoogleConnected && state.hasMicrosoftConnected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _providerFilter == null,
                    onSelected: () => _setFilter(null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Google',
                    selected: _providerFilter == 'google',
                    onSelected: () => _setFilter('google'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Microsoft',
                    selected: _providerFilter == 'microsoft',
                    onSelected: () => _setFilter('microsoft'),
                  ),
                ],
              ),
            ),
          // Content
          Expanded(
            child: state.isLoading && events.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : events.isEmpty
                    ? _buildEmpty(theme)
                    : RefreshIndicator(
                        onRefresh: _syncAndReload,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: grouped.length,
                          itemBuilder: (context, index) {
                            final date = grouped.keys.elementAt(index);
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

  void _setFilter(String? provider) {
    setState(() => _providerFilter = provider);
    ref.read(calendarProvider.notifier).loadEvents(provider: provider);
  }

  Map<String, List<CalendarEventModel>> _groupByDate(
      List<CalendarEventModel> events) {
    final map = <String, List<CalendarEventModel>>{};  // insertion-ordered
    for (final event in events) {
      final key = DateFormat('yyyy-MM-dd').format(event.startTime);
      map.putIfAbsent(key, () => []).add(event);
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No upcoming events', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Pull down to sync your calendar',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Scaffold _buildNoConnection(BuildContext context, ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Events'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Connect a calendar first', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go to Calendar Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withOpacity(0.15)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected ? theme.colorScheme.primary : null,
            fontWeight: selected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }
}
