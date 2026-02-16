import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../services/sync_service.dart';
import '../services/sync_status.dart';
import 'connectivity_provider.dart';
import 'database_provider.dart';

/// Provides the SyncService for the current authenticated user.
/// Automatically starts syncing when the user is logged in.
final syncServiceProvider = Provider<SyncService?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;
  if (user == null) return null;

  final db = ref.watch(databaseProvider);
  final apiClient = ref.watch(apiClientProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  final syncService = SyncService(
    db: db,
    apiClient: apiClient,
    connectivityService: connectivityService,
    userId: user.id,
  );

  syncService.start();
  ref.onDispose(() => syncService.dispose());

  return syncService;
});

/// Streams the sync status for the UI banner.
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  if (syncService == null) {
    return Stream.value(const SyncStatus.idle());
  }
  return syncService.statusStream;
});

/// Watch count of pending sync items for badges.
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;
  if (user == null) return Stream.value(0);

  final db = ref.watch(databaseProvider);
  return db.syncQueueDao.watchPendingCount(user.id);
});

/// Watch count of failed sync items for the failed banner.
final failedSyncCountProvider = StreamProvider<int>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;
  if (user == null) return Stream.value(0);

  final db = ref.watch(databaseProvider);
  return db.syncQueueDao.watchFailedCount(user.id);
});

/// Get the count of unsynced items (pending + failed) for logout warning.
final unsyncedCountProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;
  if (user == null) return 0;

  final db = ref.watch(databaseProvider);
  return db.syncQueueDao.getUnsyncedCount(user.id);
});
