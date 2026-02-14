import 'package:flutter/material.dart';
import '../../data/models/trainer_notification_model.dart';

/// Individual notification card with type-based icon, unread indicator,
/// relative timestamp, and swipe-to-dismiss support.
class NotificationCard extends StatelessWidget {
  final TrainerNotificationModel notification;
  final VoidCallback onTap;
  final Future<bool> Function() onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final relativeTime = _formatRelativeTime(notification.createdAt);

    return Semantics(
      label: _buildSemanticLabel(relativeTime),
      button: true,
      child: Dismissible(
        key: ValueKey(notification.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => onDismiss(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: theme.colorScheme.error,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Delete',
                style: TextStyle(
                  color: theme.colorScheme.onError,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.delete_outline, color: theme.colorScheme.onError),
            ],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: notification.isRead
                  ? Colors.transparent
                  : theme.colorScheme.primary.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(color: theme.dividerColor, width: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTypeIcon(theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            relativeTime,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.labelLarge?.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.labelLarge?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Unread indicator dot
                if (!notification.isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a descriptive label for screen readers combining the notification
  /// status, type, title, message preview, and time.
  String _buildSemanticLabel(String relativeTime) {
    final readStatus = notification.isRead ? 'Read' : 'Unread';
    final type = _notificationTypeLabel(notification.notificationType);
    return '$readStatus $type notification: ${notification.title}. '
        '${notification.message}. $relativeTime';
  }

  String _notificationTypeLabel(String type) {
    return switch (type) {
      'trainee_readiness' => 'readiness survey',
      'workout_completed' => 'workout completed',
      'workout_missed' => 'workout missed',
      'goal_hit' => 'goal achieved',
      'check_in' => 'weight check-in',
      'message' => 'message',
      _ => 'general',
    };
  }

  Widget _buildTypeIcon(ThemeData theme) {
    final (IconData icon, Color color) =
        switch (notification.notificationType) {
      'trainee_readiness' => (Icons.favorite_outline, Colors.green),
      'workout_completed' => (Icons.check_circle_outline, Colors.blue),
      'workout_missed' => (Icons.warning_amber_outlined, Colors.orange),
      'goal_hit' => (Icons.star_outline, Colors.amber),
      'check_in' => (Icons.monitor_weight_outlined, Colors.purple),
      'message' => (Icons.chat_bubble_outline, Colors.grey),
      _ => (Icons.info_outline, Colors.grey),
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatRelativeTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return '';
    }
  }
}
