import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/event_model.dart';
import '../providers/event_provider.dart';
import '../widgets/event_card.dart';
import '../../../../core/l10n/l10n_extension.dart';

class TrainerEventListScreen extends ConsumerStatefulWidget {
  const TrainerEventListScreen({super.key});

  @override
  ConsumerState<TrainerEventListScreen> createState() =>
      _TrainerEventListScreenState();
}

class _TrainerEventListScreenState
    extends ConsumerState<TrainerEventListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainerEventProvider.notifier).loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainerEventProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.communityEvents)),
      floatingActionButton: Semantics(
        label: context.l10n.communityCreateANewEvent,
        button: true,
        child: FloatingActionButton(
          onPressed: () async {
            final result = await context.push<String>(
              '/trainer/events/create',
            );
            if (result == 'created') {
              ref.read(trainerEventProvider.notifier).loadEvents();
            }
          },
          tooltip: context.l10n.communityCreateEvent,
          child: const Icon(Icons.add),
        ),
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, EventListState state) {
    if (state.isLoading && state.events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(state.error!),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () =>
                  ref.read(trainerEventProvider.notifier).loadEvents(),
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (state.events.isEmpty) {
      return _TrainerEmptyView(
        onRefresh: () =>
            ref.read(trainerEventProvider.notifier).loadEvents(),
        onCreateFirst: () async {
          final result = await context.push<String>(
            '/trainer/events/create',
          );
          if (result == 'created') {
            ref.read(trainerEventProvider.notifier).loadEvents();
          }
        },
      );
    }

    final upcoming = state.upcoming;
    final cancelled = state.cancelled;
    final past = state.past;

    return RefreshIndicator(
      onRefresh: () => ref.read(trainerEventProvider.notifier).loadEvents(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (upcoming.isNotEmpty) ...[
            _label(context, 'Upcoming'),
            ...upcoming.map((e) => _buildCard(e)),
          ],
          if (cancelled.isNotEmpty) ...[
            _label(context, 'Cancelled'),
            ...cancelled.map((e) => _buildCard(e)),
          ],
          if (past.isNotEmpty) ...[
            _label(context, 'Past'),
            ...past.map((e) => _buildCard(e)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        text,
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

  Widget _buildCard(CommunityEventModel event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: EventCard(
        event: event,
        showRsvpIndicator: false,
        onTap: () async {
          final result = await context.push<String>(
            '/trainer/events/${event.id}/edit',
          );
          if (result == 'deleted' || result == 'updated') {
            ref.read(trainerEventProvider.notifier).loadEvents();
          }
        },
      ),
    );
  }
}

class _TrainerEmptyView extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onCreateFirst;

  const _TrainerEmptyView({
    required this.onRefresh,
    required this.onCreateFirst,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
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
            'No events yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first event to engage your trainees.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 24),
          Center(
            child: FilledButton.icon(
              onPressed: onCreateFirst,
              icon: const Icon(Icons.add),
              label: Text(context.l10n.communityCreateEvent2),
            ),
          ),
        ],
      ),
    );
  }
}
