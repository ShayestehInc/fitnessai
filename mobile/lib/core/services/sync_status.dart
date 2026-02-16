/// Represents the overall sync engine state for UI rendering.
enum SyncState {
  /// No active sync and no pending items.
  idle,

  /// Currently syncing items to the server.
  syncing,

  /// All items have been synced successfully.
  allSynced,

  /// One or more items failed to sync.
  hasFailed,
}

/// Detailed sync progress for the syncing banner.
class SyncProgress {
  final int currentItem;
  final int totalItems;

  const SyncProgress({
    required this.currentItem,
    required this.totalItems,
  });

  String get displayText => 'Syncing $currentItem of $totalItems...';
}

/// Represents a single failed sync item for the bottom sheet UI.
class FailedSyncItem {
  final int id;
  final String operationType;
  final String description;
  final String errorMessage;
  final DateTime createdAt;

  const FailedSyncItem({
    required this.id,
    required this.operationType,
    required this.description,
    required this.errorMessage,
    required this.createdAt,
  });
}

/// The complete sync status emitted to the UI.
class SyncStatus {
  final SyncState state;
  final SyncProgress? progress;
  final int failedCount;

  const SyncStatus({
    required this.state,
    this.progress,
    this.failedCount = 0,
  });

  const SyncStatus.idle()
      : state = SyncState.idle,
        progress = null,
        failedCount = 0;
}
