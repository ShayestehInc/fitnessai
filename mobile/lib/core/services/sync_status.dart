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

/// Type-safe enum for sync queue operation types.
enum SyncOperationType {
  workoutLog('workout_log'),
  nutritionLog('nutrition_log'),
  weightCheckin('weight_checkin'),
  readinessSurvey('readiness_survey');

  final String value;
  const SyncOperationType(this.value);

  /// Parse a raw string into a [SyncOperationType].
  /// Throws [ArgumentError] if the string is not a valid operation type.
  static SyncOperationType fromString(String raw) {
    for (final type in values) {
      if (type.value == raw) return type;
    }
    throw ArgumentError('Unknown SyncOperationType: $raw');
  }
}

/// Type-safe enum for sync queue item status.
enum SyncItemStatus {
  pending('pending'),
  syncing('syncing'),
  synced('synced'),
  failed('failed');

  final String value;
  const SyncItemStatus(this.value);

  /// Parse a raw string into a [SyncItemStatus].
  /// Throws [ArgumentError] if the string is not a valid status.
  static SyncItemStatus fromString(String raw) {
    for (final status in values) {
      if (status.value == raw) return status;
    }
    throw ArgumentError('Unknown SyncItemStatus: $raw');
  }
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncProgress &&
          runtimeType == other.runtimeType &&
          currentItem == other.currentItem &&
          totalItems == other.totalItems;

  @override
  int get hashCode => Object.hash(currentItem, totalItems);
}

/// Represents a single failed sync item for the bottom sheet UI.
class FailedSyncItem {
  final int id;
  final SyncOperationType operationType;
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatus &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          progress == other.progress &&
          failedCount == other.failedCount;

  @override
  int get hashCode => Object.hash(state, progress, failedCount);
}
