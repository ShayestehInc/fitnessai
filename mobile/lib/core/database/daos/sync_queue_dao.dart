import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueueItems])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  /// Insert a new sync queue item. Returns the inserted row's ID.
  Future<int> insertItem({
    required String clientId,
    required int userId,
    required String operationType,
    required String payloadJson,
  }) {
    return into(syncQueueItems).insert(
      SyncQueueItemsCompanion.insert(
        clientId: clientId,
        userId: userId,
        operationType: operationType,
        payloadJson: payloadJson,
      ),
    );
  }

  /// Check if an item with the given clientId already exists.
  Future<bool> existsByClientId(String clientId) async {
    final query = select(syncQueueItems)
      ..where((t) => t.clientId.equals(clientId));
    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Get the next pending item (FIFO order) for a given user.
  Future<SyncQueueItem?> getNextPending(int userId) {
    final query = select(syncQueueItems)
      ..where((t) =>
          t.userId.equals(userId) & t.status.equals('pending'))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  /// Mark an item as syncing.
  Future<void> markSyncing(int id) {
    return (update(syncQueueItems)..where((t) => t.id.equals(id)))
        .write(const SyncQueueItemsCompanion(status: Value('syncing')));
  }

  /// Mark an item as synced with timestamp.
  Future<void> markSynced(int id) {
    return (update(syncQueueItems)..where((t) => t.id.equals(id))).write(
      SyncQueueItemsCompanion(
        status: const Value('synced'),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Mark an item as failed, increment retry count, record error.
  Future<void> markFailed(int id, String error, int currentRetryCount) {
    return (update(syncQueueItems)..where((t) => t.id.equals(id))).write(
      SyncQueueItemsCompanion(
        status: const Value('failed'),
        retryCount: Value(currentRetryCount + 1),
        lastError: Value(error),
      ),
    );
  }

  /// Get count of pending items for a user.
  Future<int> getPendingCount(int userId) async {
    final query = selectOnly(syncQueueItems)
      ..addColumns([syncQueueItems.id.count()])
      ..where(syncQueueItems.userId.equals(userId) &
          syncQueueItems.status.isIn(['pending', 'syncing']));
    final result = await query.getSingle();
    return result.read(syncQueueItems.id.count()) ?? 0;
  }

  /// Get count of pending + failed items for a user (for logout warning).
  Future<int> getUnsyncedCount(int userId) async {
    final query = selectOnly(syncQueueItems)
      ..addColumns([syncQueueItems.id.count()])
      ..where(syncQueueItems.userId.equals(userId) &
          syncQueueItems.status.isIn(['pending', 'syncing', 'failed']));
    final result = await query.getSingle();
    return result.read(syncQueueItems.id.count()) ?? 0;
  }

  /// Get all failed items for a user.
  Future<List<SyncQueueItem>> getFailedItems(int userId) {
    final query = select(syncQueueItems)
      ..where((t) =>
          t.userId.equals(userId) & t.status.equals('failed'))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.get();
  }

  /// Reset a failed item back to pending for user-initiated (manual) retry.
  /// Resets retryCount to 0 so the item gets a full set of retry attempts.
  Future<void> retryItem(int id) {
    return (update(syncQueueItems)..where((t) => t.id.equals(id))).write(
      const SyncQueueItemsCompanion(
        status: Value('pending'),
        lastError: Value(null),
        retryCount: Value(0),
      ),
    );
  }

  /// Requeue a failed item for automatic retry by the sync engine.
  /// Preserves retryCount so the exponential backoff and max-retry
  /// logic continue correctly.
  Future<void> requeueForRetry(int id) {
    return (update(syncQueueItems)..where((t) => t.id.equals(id))).write(
      const SyncQueueItemsCompanion(
        status: Value('pending'),
        lastError: Value(null),
      ),
    );
  }

  /// Delete a specific item.
  Future<void> deleteItem(int id) {
    return (delete(syncQueueItems)..where((t) => t.id.equals(id))).go();
  }

  /// Delete synced items older than a given duration.
  Future<int> deleteOldSynced(Duration maxAge) {
    final cutoff = DateTime.now().subtract(maxAge);
    return (delete(syncQueueItems)
          ..where((t) =>
              t.status.equals('synced') & t.syncedAt.isSmallerThanValue(cutoff)))
        .go();
  }

  /// Delete all items for a user (used on logout).
  Future<void> deleteAllForUser(int userId) {
    return (delete(syncQueueItems)
          ..where((t) => t.userId.equals(userId)))
        .go();
  }

  /// Watch the count of pending + syncing items for live UI updates.
  Stream<int> watchPendingCount(int userId) {
    final query = selectOnly(syncQueueItems)
      ..addColumns([syncQueueItems.id.count()])
      ..where(syncQueueItems.userId.equals(userId) &
          syncQueueItems.status.isIn(['pending', 'syncing']));
    return query.watchSingle().map(
          (row) => row.read(syncQueueItems.id.count()) ?? 0,
        );
  }

  /// Watch failed items count for the failed-sync banner.
  Stream<int> watchFailedCount(int userId) {
    final query = selectOnly(syncQueueItems)
      ..addColumns([syncQueueItems.id.count()])
      ..where(syncQueueItems.userId.equals(userId) &
          syncQueueItems.status.equals('failed'));
    return query.watchSingle().map(
          (row) => row.read(syncQueueItems.id.count()) ?? 0,
        );
  }
}
