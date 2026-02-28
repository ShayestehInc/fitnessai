import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Actions section shown when at least one calendar is connected.
/// Shows links to events and availability management.
class CalendarActionsSection extends StatelessWidget {
  const CalendarActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Synced Events',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => context.push('/trainer/calendar/events'),
              icon: const Icon(Icons.event, size: 18),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Your calendar events are synced automatically. You can also set your availability for clients.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => context.push('/trainer/calendar/availability'),
          icon: const Icon(Icons.access_time),
          label: const Text('Manage Availability'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}
