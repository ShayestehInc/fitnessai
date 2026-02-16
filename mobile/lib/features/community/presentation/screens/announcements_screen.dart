import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/announcement_provider.dart';
import '../../data/models/announcement_model.dart';

/// Full-screen announcements list for trainees.
class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(announcementProvider.notifier).loadAnnouncements();
      ref.read(announcementProvider.notifier).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(announcementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(announcementProvider.notifier).loadAnnouncements();
        },
        child: _buildBody(theme, state),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AnnouncementState state) {
    if (state.isLoading && state.announcements.isEmpty) {
      return _buildLoadingSkeleton(theme);
    }

    if (state.error != null && state.announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(state.error!, style: TextStyle(color: theme.textTheme.bodySmall?.color)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.read(announcementProvider.notifier).loadAnnouncements(),
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
              'No announcements yet',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Your trainer will post updates here.',
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
        return _AnnouncementTile(announcement: state.announcements[index]);
      },
    );
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Semantics(
      label: 'Loading announcements',
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date row skeleton
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(width: 80, height: 10, color: theme.dividerColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title skeleton
                  Container(width: 180, height: 14, color: theme.dividerColor),
                  const SizedBox(height: 6),
                  // Body skeleton (2 lines)
                  Container(width: double.infinity, height: 12, color: theme.dividerColor),
                  const SizedBox(height: 4),
                  Container(width: 220, height: 12, color: theme.dividerColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final AnnouncementModel announcement;

  const _AnnouncementTile({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: announcement.isPinned
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (announcement.isPinned) ...[
                Icon(Icons.push_pin, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Pinned',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  dateFormat.format(announcement.createdAt),
                  textAlign: announcement.isPinned ? TextAlign.left : TextAlign.right,
                  style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            announcement.title,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            announcement.body,
            style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}
