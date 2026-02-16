import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:uuid/uuid.dart';

import '../../features/nutrition/data/repositories/nutrition_repository.dart';
import '../services/connectivity_service.dart';
import '../services/sync_status.dart';
import 'app_database.dart';
import 'offline_save_result.dart';

const _uuid = Uuid();

/// Wraps weight check-in operations with offline fallback.
class OfflineWeightRepository {
  final NutritionRepository _onlineRepo;
  final AppDatabase _db;
  final ConnectivityService _connectivityService;
  final int _userId;

  OfflineWeightRepository({
    required NutritionRepository onlineRepo,
    required AppDatabase db,
    required ConnectivityService connectivityService,
    required int userId,
  })  : _onlineRepo = onlineRepo,
        _db = db,
        _connectivityService = connectivityService,
        _userId = userId;

  /// Create a weight check-in. Falls back to local save when offline.
  Future<OfflineSaveResult> createWeightCheckIn({
    required String date,
    required double weightKg,
    String notes = '',
  }) async {
    if (_connectivityService.isOnline) {
      try {
        final result = await _onlineRepo.createWeightCheckIn(
          date: date,
          weightKg: weightKg,
          notes: notes,
        );
        if (result['success'] == true) {
          return OfflineSaveResult.onlineSuccess(data: result);
        }
        return OfflineSaveResult.failure(
          result['error']?.toString() ?? 'Failed to save weight',
        );
      } on DioException catch (e) {
        if (_isNetworkError(e)) {
          return _saveWeightLocally(
            date: date,
            weightKg: weightKg,
            notes: notes,
          );
        }
        return OfflineSaveResult.failure(e.message ?? 'Network error');
      }
    }

    return _saveWeightLocally(
      date: date,
      weightKg: weightKg,
      notes: notes,
    );
  }

  Future<OfflineSaveResult> _saveWeightLocally({
    required String date,
    required double weightKg,
    required String notes,
  }) async {
    final clientId = _uuid.v4();
    final payload = {
      'date': date,
      'weight_kg': weightKg,
      'notes': notes,
    };

    try {
      await _db.nutritionCacheDao.insertPendingWeight(
        clientId: clientId,
        userId: _userId,
        date: date,
        weightKg: weightKg,
        notes: notes,
      );

      await _db.syncQueueDao.insertItem(
        clientId: clientId,
        userId: _userId,
        operationType: SyncOperationType.weightCheckin.value,
        payloadJson: jsonEncode(payload),
      );

      return const OfflineSaveResult.offlineSuccess();
    } on SqliteException catch (e) {
      if (e.toString().contains('full')) {
        return const OfflineSaveResult.failure(
          'Device storage is full. Free up space to save your data.',
        );
      }
      rethrow;
    }
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.type == DioExceptionType.unknown && e.error is SocketException);
  }
}
