import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';
import 'event_type_badge.dart';

class EventCard extends StatelessWidget {
  final CommunityEventModel event;
  final VoidCallback onTap;
  final bool showRsvpIndicator;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.showRsvpIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimmed = event.isPast || event.isCancelled;

    return Semantics(
      label: '${event.title}, ${event.eventTypeLabel}, '
          '${DateFormat.MMMd().format(event.startsAt.toLocal())}',
      button: true,
      child: Opacity(
        opacity: dimmed ? 0.55 : 1.0,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 8),
                  _buildTitle(theme),
                  const SizedBox(height: 8),
                  _buildDetails(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        EventTypeBadge(eventType: event.eventType),
        if (event.isHappeningNow || event.isCancelled) ...[
          const SizedBox(width: 6),
          EventStatusBadge(status: event.isCancelled ? 'cancelled' : 'live'),
        ],
        if (event.isAtCapacity && !event.isCancelled) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Full',
              style: TextStyle(
                color: Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (showRsvpIndicator && event.myRsvp != null)
          _RsvpIndicator(rsvp: event.myRsvp!),
      ],
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      event.title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDetails(ThemeData theme) {
    final dateStr = _formatDateRange(event.startsAt.toLocal(), event.endsAt.toLocal());
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Column(
      children: [
        _detailRow(Icons.calendar_today, dateStr, muted),
        const SizedBox(height: 4),
        _detailRow(
          event.isVirtual ? Icons.videocam_outlined : Icons.location_on_outlined,
          event.isVirtual
              ? 'Virtual'
              : (event.hasLocation ? event.locationAddress : 'In Person'),
          muted,
        ),
        const SizedBox(height: 4),
        _detailRow(
          Icons.people_outline,
          '${event.goingCount} going'
              '${event.maybeCount > 0 ? ", ${event.maybeCount} interested" : ""}'
              '${event.maxAttendees != null ? " / ${event.maxAttendees} max" : ""}',
          muted,
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final timeFmt = DateFormat.jm();

    String prefix;
    if (startDay == today) {
      prefix = 'Today';
    } else if (startDay == today.add(const Duration(days: 1))) {
      prefix = 'Tomorrow';
    } else {
      prefix = DateFormat.MMMd().format(start);
    }

    return '$prefix, ${timeFmt.format(start)} - ${timeFmt.format(end)}';
  }
}

class _RsvpIndicator extends StatelessWidget {
  final String rsvp;

  const _RsvpIndicator({required this.rsvp});

  @override
  Widget build(BuildContext context) {
    final status = RsvpStatus.fromApi(rsvp);
    if (status == null) return const SizedBox.shrink();

    final (color, icon) = switch (status) {
      RsvpStatus.going => (Colors.green, Icons.check_circle),
      RsvpStatus.maybe => (Colors.amber.shade700, Icons.star),
      RsvpStatus.notGoing => (Colors.grey, Icons.remove_circle_outline),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          status.label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
