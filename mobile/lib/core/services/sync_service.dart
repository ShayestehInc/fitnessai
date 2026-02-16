import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../database/app_database.dart';
import 'connectivity_service.dart';
import 'sync_status.dart';

/// Maximum number of retry attempts before marking an item as permanently failed.
const int _maxRetries = 3;

/// Backoff delays between retries: 5s, 15s, 45s.
const List<Duration> _retryDelays = [
  Duration(seconds: 5),
  Duration(seconds: 15),
  Duration(seconds: 45),
];

/// Orchestrates the sync queue: listens for connectivity changes,
/// processes pending items sequentially, handles retries with backoff.
class SyncService {
  final AppDatabase _db;
  final ApiClient _apiClient;
  final ConnectivityService _connectivityService;
  final int _userId;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  bool _isSyncing = false;
  bool _disposed = false;

  SyncService({
    required AppDatabase db,
    required ApiClient apiClient,
    required ConnectivityService connectivityService,
    required int userId,
  })  : _db = db,
        _apiClient = apiClient,
        _connectivityService = connectivityService,
        _userId = userId;

  /// Stream of sync status updates for the UI banner.
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Start listening for connectivity changes and process queue.
  void start() {
    _connectivitySubscription =
        _connectivityService.statusStream.listen(_onConnectivityChanged);

    // If already online, attempt to process queue immediately.
    if (_connectivityService.isOnline) {
      _processQueue();
    }
  }

  void _onConnectivityChanged(ConnectivityStatus status) {
    if (_disposed) return;
    if (status == ConnectivityStatus.online) {
      _processQueue();
    }
  }

  /// Process all pending items in the queue sequentially (FIFO).
  Future<void> _processQueue() async {
    if (_isSyncing || _disposed) return;
    _isSyncing = true;

    try {
      // Count total pending items for progress display
      final totalPending =
          await _db.syncQueueDao.getPendingCount(_userId);
      if (totalPending == 0) {
        _emitIdle();
        return;
      }

      int processedCount = 0;

      while (!_disposed) {
        if (!_connectivityService.isOnline) break;

        final nextItem =
            await _db.syncQueueDao.getNextPending(_userId);
        if (nextItem == null) break;

        processedCount++;
        _statusController.add(SyncStatus(
          state: SyncState.syncing,
          progress: SyncProgress(
            currentItem: processedCount,
            totalItems: totalPending,
          ),
        ));

        await _processItem(nextItem);
      }

      // After processing, check for failures
      if (!_disposed) {
        final failedCount =
            await _db.syncQueueDao.getUnsyncedCount(_userId);
        final pendingCount =
            await _db.syncQueueDao.getPendingCount(_userId);

        if (pendingCount == 0 && failedCount == 0 && processedCount > 0) {
          _statusController.add(const SyncStatus(
            state: SyncState.allSynced,
          ));
        } else if (failedCount > 0) {
          _statusController.add(SyncStatus(
            state: SyncState.hasFailed,
            failedCount: failedCount,
          ));
        } else {
          _emitIdle();
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Process a single sync queue item.
  Future<void> _processItem(SyncQueueItem item) async {
    await _db.syncQueueDao.markSyncing(item.id);

    try {
      final payload =
          jsonDecode(item.payloadJson) as Map<String, dynamic>;

      switch (item.operationType) {
        case 'workout_log':
          await _syncWorkoutLog(payload, item.clientId);
        case 'nutrition_log':
          await _syncNutritionLog(payload, item.clientId);
        case 'weight_checkin':
          await _syncWeightCheckin(payload, item.clientId);
        case 'readiness_survey':
          await _syncReadinessSurvey(payload);
        default:
          throw StateError(
              'Unknown operation type: ${item.operationType}');
      }

      // Success: mark synced and clean up local pending data
      await _db.syncQueueDao.markSynced(item.id);
      await _cleanupLocalData(item.operationType, item.clientId);
    } on DioException catch (e) {
      await _handleSyncError(item, e);
    } catch (e) {
      await _db.syncQueueDao.markFailed(
        item.id,
        e.toString(),
        item.retryCount,
      );
    }
  }

  Future<void> _syncWorkoutLog(
    Map<String, dynamic> payload,
    String clientId,
  ) async {
    await _apiClient.dio.post(
      ApiConstants.workoutPostSurvey,
      data: {
        'workout_summary': payload['workout_summary'],
        'survey_data': payload['survey_data'],
        'readiness_survey': payload['readiness_survey'],
        'survey_type': 'post_workout',
        'client_id': clientId,
      },
    );
  }

  Future<void> _syncNutritionLog(
    Map<String, dynamic> payload,
    String clientId,
  ) async {
    await _apiClient.dio.post(
      ApiConstants.confirmAndSaveLog,
      data: {
        'parsed_data': payload['parsed_data'],
        'confirm': true,
        'date': payload['date'],
        'client_id': clientId,
      },
    );
  }

  Future<void> _syncWeightCheckin(
    Map<String, dynamic> payload,
    String clientId,
  ) async {
    await _apiClient.dio.post(
      ApiConstants.weightCheckIns,
      data: {
        'date': payload['date'],
        'weight_kg': payload['weight_kg'],
        'notes': payload['notes'] ?? '',
        'client_id': clientId,
      },
    );
  }

  Future<void> _syncReadinessSurvey(Map<String, dynamic> payload) async {
    await _apiClient.dio.post(
      ApiConstants.workoutReadinessSurvey,
      data: {
        'workout_name': payload['workout_name'],
        'survey_data': payload['survey_data'],
        'survey_type': 'readiness',
      },
    );
  }

  /// Handle sync errors with retry logic and conflict detection.
  Future<void> _handleSyncError(SyncQueueItem item, DioException e) async {
    final statusCode = e.response?.statusCode;

    // 409 Conflict: don't retry, mark as permanently failed
    if (statusCode == 409) {
      final message = _getConflictMessage(item.operationType);
      await _db.syncQueueDao.markFailed(item.id, message, _maxRetries);
      return;
    }

    // 401 Unauthorized: token expired, pause sync (handled by Dio interceptor)
    if (statusCode == 401) {
      await _db.syncQueueDao.markFailed(
        item.id,
        'Authentication expired. Please log in again.',
        item.retryCount,
      );
      return;
    }

    // Server errors (5xx) or network errors: retry with backoff
    final isRetryable = statusCode == null ||
        statusCode >= 500 ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;

    if (isRetryable && item.retryCount < _maxRetries - 1) {
      // Set back to pending with incremented retry count
      await _db.syncQueueDao.markFailed(
        item.id,
        e.message ?? 'Network error',
        item.retryCount,
      );
      // Reset to pending so it gets picked up again
      await _db.syncQueueDao.retryItem(item.id);

      // Wait with exponential backoff before continuing
      final delayIndex =
          item.retryCount.clamp(0, _retryDelays.length - 1);
      await Future.delayed(_retryDelays[delayIndex]);
    } else {
      // Max retries reached, mark as permanently failed
      final errorMsg = e.response?.data?['error']?.toString() ??
          e.message ??
          'Sync failed after $_maxRetries attempts';
      await _db.syncQueueDao.markFailed(item.id, errorMsg, item.retryCount);
    }
  }

  String _getConflictMessage(String operationType) {
    switch (operationType) {
      case 'workout_log':
        return 'Program was updated by your trainer. Please review.';
      case 'nutrition_log':
        return 'Nutrition data was updated. Please review.';
      default:
        return 'Data conflict detected. Please review.';
    }
  }

  /// Clean up local pending data after successful sync.
  Future<void> _cleanupLocalData(
    String operationType,
    String clientId,
  ) async {
    switch (operationType) {
      case 'workout_log':
        await _db.workoutCacheDao.deleteByClientId(clientId);
      case 'nutrition_log':
        await _db.nutritionCacheDao.deleteNutritionByClientId(clientId);
      case 'weight_checkin':
        await _db.nutritionCacheDao.deleteWeightByClientId(clientId);
      case 'readiness_survey':
        // No local data to clean up for readiness surveys
        break;
    }
  }

  void _emitIdle() {
    if (!_disposed) {
      _statusController.add(const SyncStatus.idle());
    }
  }

  /// Manually trigger a sync attempt (e.g., from pull-to-refresh).
  Future<void> triggerSync() async {
    if (_connectivityService.isOnline) {
      await _processQueue();
    }
  }

  /// Dispose all resources.
  Future<void> dispose() async {
    _disposed = true;
    await _connectivitySubscription?.cancel();
    await _statusController.close();
  }
}
