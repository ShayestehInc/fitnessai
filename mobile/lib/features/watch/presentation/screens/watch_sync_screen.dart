import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/watch_provider.dart';

/// Settings screen showing Apple Watch pairing status and sync controls.
class WatchSyncScreen extends ConsumerWidget {
  const WatchSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pairedAsync = ref.watch(isWatchPairedProvider);
    final reachableAsync = ref.watch(isWatchReachableProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Apple Watch')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.watch,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Apple Watch',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatusRow(
                    label: 'Paired',
                    asyncValue: pairedAsync,
                  ),
                  const SizedBox(height: 8),
                  _StatusRow(
                    label: 'Connected',
                    asyncValue: reachableAsync,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Info section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How it works',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.sync,
                    title: 'Auto Sync',
                    subtitle:
                        "Your workout plan syncs to your watch automatically when you open the app.",
                  ),
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.fitness_center,
                    title: 'Log from your wrist',
                    subtitle:
                        'Complete sets directly on your watch during workouts.',
                  ),
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.timer,
                    title: 'Rest timers',
                    subtitle:
                        'Haptic alerts when your rest period is over.',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Manual sync button
          pairedAsync.when(
            data: (paired) => paired
                ? FilledButton.icon(
                    onPressed: () async {
                      final repo = ref.read(watchRepositoryProvider);
                      await repo.requestPendingCompletions();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sync requested')),
                        );
                      }
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync Now'),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final AsyncValue<bool> asyncValue;

  const _StatusRow({required this.label, required this.asyncValue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyLarge),
        asyncValue.when(
          data: (value) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                value ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: value
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                value ? 'Yes' : 'No',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: value
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          loading: () => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => Text(
            'Unknown',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
