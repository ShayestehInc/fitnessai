import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/event_model.dart';
import '../providers/event_provider.dart';
import '../widgets/event_type_badge.dart';
import '../widgets/rsvp_button.dart';

class EventDetailScreen extends ConsumerWidget {
  final int eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Try in-memory provider first
    final state = ref.watch(traineeEventProvider);
    final cachedEvent =
        state.events.where((e) => e.id == eventId).firstOrNull;

    if (cachedEvent != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: _EventDetailBody(event: cachedEvent),
      );
    }

    // Fallback to API fetch (deep links, stale provider state)
    final detailAsync = ref.watch(eventDetailProvider(eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              const Text('Event not found or no longer available'),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
        data: (event) => _EventDetailBody(event: event),
      ),
    );
  }
}

class _EventDetailBody extends ConsumerWidget {
  final CommunityEventModel event;

  const _EventDetailBody({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    // Show snackbar on RSVP errors
    ref.listen<EventListState>(traineeEventProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Badges
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            EventTypeBadge(eventType: event.eventType),
            if (event.isHappeningNow)
              const EventStatusBadge(status: 'live'),
            if (event.isCancelled)
              const EventStatusBadge(status: 'cancelled'),
            if (event.isAtCapacity && !event.isCancelled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Full',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          event.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // Date & Time
        _DetailRow(
          icon: Icons.calendar_today,
          title: 'Date & Time',
          value: _formatFullDateRange(
            event.startsAt.toLocal(),
            event.endsAt.toLocal(),
          ),
        ),
        const Divider(height: 24),

        // Location
        _DetailRow(
          icon: event.isVirtual
              ? Icons.videocam_outlined
              : Icons.location_on_outlined,
          title: event.isVirtual ? 'Virtual Event' : 'Location',
          value: event.isVirtual ? 'Online' : 'In Person',
        ),
        if (event.canJoinVirtual) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Semantics(
              label: 'Join virtual meeting',
              child: FilledButton.icon(
                onPressed: () => _launchUrl(context, event.meetingUrl),
                icon: const Icon(Icons.videocam, size: 18),
                label: const Text('Join Meeting'),
              ),
            ),
          ),
        ],
        const Divider(height: 24),

        // Attendees
        _DetailRow(
          icon: Icons.people_outline,
          title: 'Attendees',
          value: '${event.goingCount} going'
              '${event.maybeCount > 0 ? ", ${event.maybeCount} interested" : ""}'
              '${event.maxAttendees != null ? " (max ${event.maxAttendees})" : ""}',
        ),
        const Divider(height: 24),

        // Description
        if (event.description.isNotEmpty) ...[
          Text(
            'About',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.description,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: 24),
        ],

        // RSVP
        if (!event.isPast) ...[
          Text(
            'Your Response',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: event.isCancelled ? 0.5 : 1.0,
            child: RsvpButton(
              currentRsvp: event.myRsvp,
              isAtCapacity: event.isAtCapacity,
              disabled: event.isCancelled,
              onChanged: (status) {
                ref.read(traineeEventProvider.notifier).rsvp(event.id, status);
              },
            ),
          ),
        ],
        if (event.isCancelled) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.red.withValues(alpha: 0.06),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('This event has been cancelled.'),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (event.isPast && !event.isCancelled) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.history, color: muted, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This event has ended.',
                      style: TextStyle(color: muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatFullDateRange(DateTime start, DateTime end) {
    final dateFmt = DateFormat.yMMMEd();
    final timeFmt = DateFormat.jm();
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    if (sameDay) {
      return '${dateFmt.format(start)}\n${timeFmt.format(start)} - ${timeFmt.format(end)}';
    }
    return '${dateFmt.format(start)} ${timeFmt.format(start)}\nto ${dateFmt.format(end)} ${timeFmt.format(end)}';
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open meeting link')),
        );
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
