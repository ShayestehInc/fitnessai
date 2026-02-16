import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/services/sync_status.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Bottom sheet showing failed sync items with individual retry/delete actions.
/// AC-27: Lists failed items with operation type, date, error message,
/// and per-item Retry/Delete buttons.
class FailedSyncSheet extends ConsumerStatefulWidget {
  const FailedSyncSheet({super.key});

  @override
  ConsumerState<FailedSyncSheet> createState() => _FailedSyncSheetState();
}

class _FailedSyncSheetState extends ConsumerState<FailedSyncSheet> {
  List<SyncQueueItem> _failedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFailedItems();
  }

  Future<void> _loadFailedItems() async {
    final db = ref.read(databaseProvider);
    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) return;

    final items = await db.syncQueueDao.getFailedItems(userId);
    if (mounted) {
      setState(() {
        _failedItems = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _retryItem(SyncQueueItem item) async {
    final db = ref.read(databaseProvider);
    await db.syncQueueDao.retryItem(item.id);

    // Remove from local list with animation
    setState(() {
      _failedItems.removeWhere((i) => i.id == item.id);
    });

    // Auto-close if no items left
    if (_failedItems.isEmpty && mounted) {
      Navigator.of(context).pop();
    }

    // Trigger sync to process the retried item
    ref.read(syncServiceProvider)?.triggerSync();
  }

  Future<void> _deleteItem(SyncQueueItem item) async {
    final db = ref.read(databaseProvider);
    await db.syncQueueDao.deleteItem(item.id);

    // Also clean up any associated pending data
    try {
      final opType = SyncOperationType.fromString(item.operationType);
      switch (opType) {
        case SyncOperationType.workoutLog:
          await db.workoutCacheDao.deleteByClientId(item.clientId);
        case SyncOperationType.nutritionLog:
          await db.nutritionCacheDao.deleteNutritionByClientId(item.clientId);
        case SyncOperationType.weightCheckin:
          await db.nutritionCacheDao.deleteWeightByClientId(item.clientId);
        case SyncOperationType.readinessSurvey:
          break;
      }
    } on ArgumentError {
      // Unknown operation type, just delete the queue item
    }

    setState(() {
      _failedItems.removeWhere((i) => i.id == item.id);
    });

    // Auto-close if no items left
    if (_failedItems.isEmpty && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Failed Sync Items',
                      style: theme.textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: _failedItems.isEmpty
                          ? null
                          : () {
                              _retryAll();
                            },
                      child: const Text('Retry All'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _failedItems.isEmpty
                        ? _buildEmptyState(theme)
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _failedItems.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _FailedSyncItemCard(
                                item: _failedItems[index],
                                onRetry: () =>
                                    _retryItem(_failedItems[index]),
                                onDelete: () =>
                                    _deleteItem(_failedItems[index]),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'No failed items',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Future<void> _retryAll() async {
    final db = ref.read(databaseProvider);
    final itemsCopy = List<SyncQueueItem>.from(_failedItems);
    for (final item in itemsCopy) {
      await db.syncQueueDao.retryItem(item.id);
    }

    setState(() => _failedItems.clear());

    ref.read(syncServiceProvider)?.triggerSync();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Card displaying a single failed sync item with retry/delete actions.
class _FailedSyncItemCard extends StatelessWidget {
  final SyncQueueItem item;
  final VoidCallback onRetry;
  final VoidCallback onDelete;

  const _FailedSyncItemCard({
    required this.item,
    required this.onRetry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type icon + description
          Row(
            children: [
              Icon(
                _getOperationIcon(),
                size: 20,
                color: _getOperationColor(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getDescription(),
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Date
          Text(
            _formatDate(item.createdAt),
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
          // Error message
          if (item.lastError != null) ...[
            const SizedBox(height: 8),
            Text(
              item.lastError!,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                ),
                child: const Text('Delete'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3B82F6),
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getOperationIcon() {
    try {
      final opType = SyncOperationType.fromString(item.operationType);
      switch (opType) {
        case SyncOperationType.workoutLog:
          return Icons.fitness_center;
        case SyncOperationType.nutritionLog:
          return Icons.restaurant;
        case SyncOperationType.weightCheckin:
          return Icons.monitor_weight;
        case SyncOperationType.readinessSurvey:
          return Icons.assignment;
      }
    } on ArgumentError {
      return Icons.help_outline;
    }
  }

  Color _getOperationColor() {
    try {
      final opType = SyncOperationType.fromString(item.operationType);
      switch (opType) {
        case SyncOperationType.workoutLog:
          return const Color(0xFF3B82F6);
        case SyncOperationType.nutritionLog:
          return const Color(0xFF22C55E);
        case SyncOperationType.weightCheckin:
          return const Color(0xFFF59E0B);
        case SyncOperationType.readinessSurvey:
          return const Color(0xFF8B5CF6);
      }
    } on ArgumentError {
      return const Color(0xFF6B7280);
    }
  }

  String _getDescription() {
    try {
      final opType = SyncOperationType.fromString(item.operationType);
      // Try to extract a name from the payload
      final payloadName = _extractNameFromPayload();

      switch (opType) {
        case SyncOperationType.workoutLog:
          return payloadName != null
              ? '$payloadName workout'
              : 'Workout log';
        case SyncOperationType.nutritionLog:
          return 'Nutrition entry';
        case SyncOperationType.weightCheckin:
          return 'Weight check-in';
        case SyncOperationType.readinessSurvey:
          return payloadName != null
              ? 'Readiness survey for $payloadName'
              : 'Readiness survey';
      }
    } on ArgumentError {
      return 'Unknown item';
    }
  }

  String? _extractNameFromPayload() {
    try {
      final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
      final summary =
          payload['workout_summary'] as Map<String, dynamic>?;
      return summary?['workout_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
