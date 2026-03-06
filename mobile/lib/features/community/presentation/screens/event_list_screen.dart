import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/event_model.dart';
import '../providers/event_provider.dart';
import '../widgets/event_card.dart';

class EventListScreen extends ConsumerStatefulWidget {
  const EventListScreen({super.key});

  @override
  ConsumerState<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends ConsumerState<EventListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(traineeEventProvider.notifier).loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(traineeEventProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, EventListState state) {
    if (state.isLoading && state.events.isEmpty) {
      return _buildLoadingSkeleton(context);
    }

    if (state.error != null && state.events.isEmpty) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => ref.read(traineeEventProvider.notifier).loadEvents(),
      );
    }

    final upcoming = state.upcoming;
    final cancelled = state.cancelled;
    final past = state.past;

    if (upcoming.isEmpty && past.isEmpty && cancelled.isEmpty) {
      return _EmptyView(
        onRefresh: () => ref.read(traineeEventProvider.notifier).loadEvents(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(traineeEventProvider.notifier).loadEvents(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.error != null)
            _InlineError(message: state.error!),
          if (upcoming.isNotEmpty) ...[
            ..._buildGroupedEvents(context, upcoming),
          ],
          if (cancelled.isNotEmpty) ...[
            const _SectionHeader(title: 'Cancelled'),
            ...cancelled.map((e) => _buildEventCard(e)),
          ],
          if (past.isNotEmpty) ...[
            const _SectionHeader(title: 'Past Events'),
            ...past.map((e) => _buildEventCard(e)),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildGroupedEvents(
    BuildContext context,
    List<CommunityEventModel> events,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    // Monday-based: days until next Monday (handles Sunday correctly)
    final daysUntilNextMonday = (8 - today.weekday) % 7;
    final endOfWeek = today.add(Duration(
      days: daysUntilNextMonday == 0 ? 7 : daysUntilNextMonday,
    ));
    final endOfNextWeek = endOfWeek.add(const Duration(days: 7));

    final groups = <String, List<CommunityEventModel>>{};
    for (final event in events) {
      final day = DateTime(
        event.startsAt.toLocal().year,
        event.startsAt.toLocal().month,
        event.startsAt.toLocal().day,
      );

      String group;
      if (day == today || event.isHappeningNow) {
        group = 'Today';
      } else if (day == tomorrow) {
        group = 'Tomorrow';
      } else if (day.isBefore(endOfWeek)) {
        group = 'This Week';
      } else if (day.isBefore(endOfNextWeek)) {
        group = 'Next Week';
      } else {
        group = 'Later';
      }
      (groups[group] ??= []).add(event);
    }

    final widgets = <Widget>[];
    for (final label
        in ['Today', 'Tomorrow', 'This Week', 'Next Week', 'Later']) {
      final group = groups[label];
      if (group == null || group.isEmpty) continue;
      widgets.add(_SectionHeader(title: label));
      widgets.addAll(group.map((e) => _buildEventCard(e)));
    }
    return widgets;
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Loading events',
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 80, height: 18, decoration: BoxDecoration(
                  color: theme.dividerColor, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 10),
                Container(width: 200, height: 16, color: theme.dividerColor),
                const SizedBox(height: 10),
                Container(width: 150, height: 12, color: theme.dividerColor),
                const SizedBox(height: 6),
                Container(width: 120, height: 12, color: theme.dividerColor),
                const SizedBox(height: 6),
                Container(width: 100, height: 12, color: theme.dividerColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(CommunityEventModel event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: EventCard(
        event: event,
        onTap: () => context.push('/community/events/${event.id}'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Icon(
            Icons.event_outlined,
            size: 64,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No upcoming events',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Your trainer hasn\'t scheduled any events yet.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.warning_amber, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
