import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:uuid/uuid.dart';

import '../../features/logging/data/repositories/logging_repository.dart';
import '../services/connectivity_service.dart';
import '../services/network_error_utils.dart';
import '../services/sync_status.dart';
import 'app_database.dart';
import 'offline_save_result.dart';

const _uuid = Uuid();

/// Wraps nutrition confirm-and-save operations with offline fallback.
/// AI parsing still requires network -- only the final save step is cached.
class OfflineNutritionRepository {
  final LoggingRepository _onlineRepo;
  final AppDatabase _db;
  final ConnectivityService _connectivityService;
  final int _userId;

  OfflineNutritionRepository({
    required LoggingRepository onlineRepo,
    required AppDatabase db,
    required ConnectivityService connectivityService,
    required int userId,
  })  : _onlineRepo = onlineRepo,
        _db = db,
        _connectivityService = connectivityService,
        _userId = userId;

  /// Confirm and save parsed nutrition data.
  /// Falls back to local save when offline.
  Future<OfflineSaveResult> confirmAndSave(
    Map<String, dynamic> parsedData, {
    String? date,
  }) async {
    if (_connectivityService.isOnline) {
      try {
        final result =
            await _onlineRepo.confirmAndSave(parsedData, date: date);
        if (result['success'] == true) {
          return const OfflineSaveResult.onlineSuccess();
        }
        return OfflineSaveResult.failure(
          result['error']?.toString() ?? 'Failed to save nutrition',
        );
      } on DioException catch (e) {
        if (isNetworkError(e)) {
          return _saveNutritionLocally(parsedData, date);
        }
        return OfflineSaveResult.failure(e.message ?? 'Network error');
      }
    }

    return _saveNutritionLocally(parsedData, date);
  }

  Future<OfflineSaveResult> _saveNutritionLocally(
    Map<String, dynamic> parsedData,
    String? date,
  ) async {
    final clientId = _uuid.v4();
    final targetDate = date ?? _todayDate();

    final payload = {
      'parsed_data': parsedData,
      'date': targetDate,
    };

    try {
      await _db.transaction(() async {
        await _db.nutritionCacheDao.insertPendingNutrition(
          clientId: clientId,
          userId: _userId,
          parsedDataJson: jsonEncode(parsedData),
          targetDate: targetDate,
        );

        await _db.syncQueueDao.insertItem(
          clientId: clientId,
          userId: _userId,
          operationType: SyncOperationType.nutritionLog.value,
          payloadJson: jsonEncode(payload),
        );
      });

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

  String _todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

}
