import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../community/data/models/announcement_model.dart';
import '../../../community/presentation/providers/announcement_provider.dart';

/// Trainer-facing announcement management screen.
class TrainerAnnouncementsScreen extends ConsumerStatefulWidget {
  const TrainerAnnouncementsScreen({super.key});

  @override
  ConsumerState<TrainerAnnouncementsScreen> createState() =>
      _TrainerAnnouncementsScreenState();
}

class _TrainerAnnouncementsScreenState
    extends ConsumerState<TrainerAnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainerAnnouncementProvider.notifier).loadAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(trainerAnnouncementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(trainerAnnouncementProvider.notifier).loadAnnouncements();
        },
        child: _buildBody(theme, state),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/trainer/announcements/create'),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, TrainerAnnouncementState state) {
    if (state.isLoading && state.announcements.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(state.error!),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () =>
                  ref.read(trainerAnnouncementProvider.notifier).loadAnnouncements(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined, size: 64, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text(
              'No announcements',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create your first announcement.',
              style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: state.announcements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final a = state.announcements[index];
        return _TrainerAnnouncementTile(
          announcement: a,
          onEdit: () => context.push(
            '/trainer/announcements/create',
            extra: a,
          ),
          onDelete: () => _confirmDelete(a.id),
        );
      },
    );
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await ref.read(trainerAnnouncementProvider.notifier).deleteAnnouncement(id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete announcement')),
        );
      }
    }
  }
}

class _TrainerAnnouncementTile extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TrainerAnnouncementTile({
    required this.announcement,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (announcement.isPinned) ...[
                Icon(Icons.push_pin, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  announcement.title,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.textTheme.bodySmall?.color, size: 20),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            announcement.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            dateFormat.format(announcement.createdAt),
            style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
