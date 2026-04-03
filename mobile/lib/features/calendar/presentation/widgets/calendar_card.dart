import 'package:flutter/material.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../data/models/calendar_connection_model.dart';
import '../../../../core/l10n/l10n_extension.dart';

class CalendarCard extends StatelessWidget {
  final String provider;
  final String title;
  final IconData icon;
  final Color iconColor;
  final CalendarConnectionModel? connection;
  final VoidCallback onConnect;
  final VoidCallback? onDisconnect;
  final VoidCallback? onSync;
  final bool isLoading;

  const CalendarCard({
    super.key,
    required this.provider,
    required this.title,
    required this.icon,
    required this.iconColor,
    this.connection,
    required this.onConnect,
    this.onDisconnect,
    this.onSync,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected = connection != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isConnected
              ? Colors.green.withValues(alpha:0.5)
              : theme.colorScheme.outline.withValues(alpha:0.3),
          width: isConnected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isConnected && connection!.calendarEmail != null)
                        Text(
                          connection!.calendarEmail!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Connected',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (isConnected) ...[
              const SizedBox(height: 16),
              if (connection!.lastSyncedAt != null)
                Text(
                  'Last synced: ${_formatDate(connection!.lastSyncedAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha:0.5),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : onSync,
                      icon: isLoading
                          ? const AdaptiveSpinner.small()
                          : const Icon(Icons.sync, size: 18),
                      label: Text(context.l10n.calendarSyncNow),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: isLoading ? null : onDisconnect,
                    icon: const Icon(Icons.link_off),
                    tooltip: context.l10n.calendarDisconnect,
                    style: IconButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isLoading ? null : onConnect,
                icon: isLoading
                    ? const AdaptiveSpinner.small()
                    : const Icon(Icons.add_link),
                label: Text('${context.l10n.calendarConnect} $title'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}
