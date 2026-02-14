import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/trainer_notification_model.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';

class TrainerNotificationsScreen extends ConsumerStatefulWidget {
  const TrainerNotificationsScreen({super.key});

  @override
  ConsumerState<TrainerNotificationsScreen> createState() =>
      _TrainerNotificationsScreenState();
}

class _TrainerNotificationsScreenState
    extends ConsumerState<TrainerNotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(context),
            child: const Text('Mark All Read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState(theme);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationCountProvider);
            },
            child: _buildNotificationList(notifications),
          );
        },
        loading: () => _buildSkeletonLoader(theme),
        error: (error, _) => _buildErrorState(theme, error),
      ),
    );
  }

  Widget _buildNotificationList(List<TrainerNotificationModel> notifications) {
    final grouped = _groupByDate(notifications);

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped[index];
        if (entry is String) {
          // Date header
          return _buildDateHeader(context, entry);
        }
        final notification = entry as TrainerNotificationModel;
        return NotificationCard(
          notification: notification,
          onTap: () => _onNotificationTap(notification),
          onDismiss: () => _confirmAndDeleteNotification(notification),
        );
      },
    );
  }

  List<dynamic> _groupByDate(List<TrainerNotificationModel> notifications) {
    final items = <dynamic>[];
    String? lastGroup;

    for (final notification in notifications) {
      final group = _dateGroupLabel(notification.createdAt);
      if (group != lastGroup) {
        items.add(group);
        lastGroup = group;
      }
      items.add(notification);
    }

    return items;
  }

  String _dateGroupLabel(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final notifDate = DateTime(dt.year, dt.month, dt.day);

      if (notifDate == today) return 'Today';
      if (notifDate == today.subtract(const Duration(days: 1))) return 'Yesterday';

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return 'Earlier';
    }
  }

  Widget _buildDateHeader(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.hintColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _onNotificationTap(TrainerNotificationModel notification) {
    ref.read(notificationsProvider.notifier).markRead(notification.id);

    final traineeId = notification.traineeId;
    if (traineeId != null) {
      context.push('/trainer/trainees/$traineeId');
    }
  }

  Future<bool> _confirmAndDeleteNotification(TrainerNotificationModel notification) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref
        .read(notificationsProvider.notifier)
        .deleteNotification(notification.id);
    if (!success && mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to delete notification')),
      );
    }
    return success;
  }

  void _markAllRead(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark All as Read'),
        content: const Text('Mark all notifications as read?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success =
        await ref.read(notificationsProvider.notifier).markAllRead();
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success ? 'All notifications marked as read' : 'Failed to mark all as read',
          ),
          backgroundColor: success ? theme.colorScheme.primary : theme.colorScheme.error,
        ),
      );
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 72,
              color: theme.hintColor,
            ),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Trainee activity notifications will appear here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(ThemeData theme) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 180,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              "Couldn't load notifications",
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(notificationsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
