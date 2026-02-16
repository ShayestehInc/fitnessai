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
  bool _pendingRestart = false;
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
      if (_isSyncing) {
        _pendingRestart = true;
      } else {
        _processQueue();
      }
    }
  }

  /// Process all pending items in the queue sequentially (FIFO).
  Future<void> _processQueue() async {
    if (_isSyncing || _disposed) return;
    _isSyncing = true;
    _pendingRestart = false;

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
        final failedItems =
            await _db.syncQueueDao.getFailedItems(_userId);
        final pendingCount =
            await _db.syncQueueDao.getPendingCount(_userId);

        if (pendingCount == 0 && failedItems.isEmpty && processedCount > 0) {
          _statusController.add(const SyncStatus(
            state: SyncState.allSynced,
          ));
        } else if (failedItems.isNotEmpty) {
          _statusController.add(SyncStatus(
            state: SyncState.hasFailed,
            failedCount: failedItems.length,
          ));
        } else {
          _emitIdle();
        }
      }
    } finally {
      _isSyncing = false;
      // If new items were queued or connectivity changed while we were syncing,
      // re-process the queue to pick them up. Scheduled via Future.microtask
      // to avoid recursive stack growth if _processQueue completes
      // synchronously and _pendingRestart is set repeatedly.
      if (_pendingRestart && !_disposed && _connectivityService.isOnline) {
        _pendingRestart = false;
        Future.microtask(_processQueue);
      }
    }
  }

  /// Process a single sync queue item.
  Future<void> _processItem(SyncQueueItem item) async {
    await _db.syncQueueDao.markSyncing(item.id);

    try {
      final payload =
          jsonDecode(item.payloadJson) as Map<String, dynamic>;
      final operationType = SyncOperationType.fromString(item.operationType);

      switch (operationType) {
        case SyncOperationType.workoutLog:
          await _syncWorkoutLog(payload, item.clientId);
        case SyncOperationType.nutritionLog:
          await _syncNutritionLog(payload, item.clientId);
        case SyncOperationType.weightCheckin:
          await _syncWeightCheckin(payload, item.clientId);
        case SyncOperationType.readinessSurvey:
          await _syncReadinessSurvey(payload);
      }

      // Success: mark synced and clean up local pending data
      await _db.syncQueueDao.markSynced(item.id);
      await _cleanupLocalData(
        SyncOperationType.fromString(item.operationType),
        item.clientId,
      );
    } on DioException catch (e) {
      await _handleSyncError(item, e);
    } on FormatException {
      // Corrupt payload JSON -- mark permanently failed, no retry.
      await _db.syncQueueDao.markFailed(
        item.id,
        'Data is corrupted and cannot be synced.',
        _maxRetries,
      );
    } on ArgumentError {
      // Unknown operation type -- mark permanently failed, no retry.
      await _db.syncQueueDao.markFailed(
        item.id,
        'Unknown operation type. This item cannot be synced.',
        _maxRetries,
      );
    } catch (e) {
      // Any other unexpected error -- mark permanently failed.
      await _db.syncQueueDao.markFailed(
        item.id,
        'An unexpected error occurred. Please try again later.',
        _maxRetries,
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

    if (isRetryable && item.retryCount + 1 < _maxRetries) {
      // markFailed increments retryCount by 1, so the stored value becomes
      // item.retryCount + 1. We check item.retryCount + 1 < _maxRetries
      // to allow exactly 3 retry attempts (retryCount 0, 1, 2).
      await _db.syncQueueDao.markFailed(
        item.id,
        _getUserFriendlyNetworkError(e),
        item.retryCount,
      );
      // Reset to pending so it gets picked up again.
      // Use requeueForRetry (not retryItem) to preserve retryCount.
      await _db.syncQueueDao.requeueForRetry(item.id);

      // Wait with exponential backoff before continuing
      final delayIndex =
          item.retryCount.clamp(0, _retryDelays.length - 1);
      await Future.delayed(_retryDelays[delayIndex]);
    } else {
      // Max retries reached, mark as permanently failed
      final errorMsg = _getUserFriendlyErrorMessage(e);
      await _db.syncQueueDao.markFailed(item.id, errorMsg, item.retryCount);
    }
  }

  /// Map a DioException to a user-friendly network error message.
  String _getUserFriendlyNetworkError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Will retry automatically.';
      case DioExceptionType.connectionError:
        return 'Unable to reach the server. Will retry automatically.';
      default:
        return 'Network error. Will retry automatically.';
    }
  }

  /// Map a DioException to a user-friendly final error message.
  String _getUserFriendlyErrorMessage(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return 'Server error. Please try again later.';
    }
    if (statusCode == 400) {
      return 'Invalid data. Please review and try again.';
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out after multiple attempts.';
      case DioExceptionType.connectionError:
        return 'Unable to reach the server after multiple attempts.';
      default:
        return 'Sync failed after $_maxRetries attempts.';
    }
  }

  String _getConflictMessage(String operationType) {
    try {
      final type = SyncOperationType.fromString(operationType);
      switch (type) {
        case SyncOperationType.workoutLog:
          return 'Program was updated by your trainer. Please review.';
        case SyncOperationType.nutritionLog:
          return 'Nutrition data was updated. Please review.';
        case SyncOperationType.weightCheckin:
        case SyncOperationType.readinessSurvey:
          return 'Data conflict detected. Please review.';
      }
    } on ArgumentError {
      return 'Data conflict detected. Please review.';
    }
  }

  /// Clean up local pending data after successful sync.
  Future<void> _cleanupLocalData(
    SyncOperationType operationType,
    String clientId,
  ) async {
    switch (operationType) {
      case SyncOperationType.workoutLog:
        await _db.workoutCacheDao.deleteByClientId(clientId);
      case SyncOperationType.nutritionLog:
        await _db.nutritionCacheDao.deleteNutritionByClientId(clientId);
      case SyncOperationType.weightCheckin:
        await _db.nutritionCacheDao.deleteWeightByClientId(clientId);
      case SyncOperationType.readinessSurvey:
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
      if (_isSyncing) {
        _pendingRestart = true;
      } else {
        await _processQueue();
      }
    }
  }

  /// Dispose all resources.
  Future<void> dispose() async {
    _disposed = true;
    await _connectivitySubscription?.cancel();
    await _statusController.close();
  }
}
