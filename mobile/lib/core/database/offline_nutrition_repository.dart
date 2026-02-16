import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../features/logging/data/repositories/logging_repository.dart';
import '../services/connectivity_service.dart';
import 'app_database.dart';

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
  Future<Map<String, dynamic>> confirmAndSave(
    Map<String, dynamic> parsedData, {
    String? date,
  }) async {
    if (_connectivityService.isOnline) {
      try {
        final result =
            await _onlineRepo.confirmAndSave(parsedData, date: date);
        if (result['success'] == true) {
          return {'success': true, 'offline': false};
        }
        return {
          'success': false,
          'offline': false,
          'error': result['error'],
        };
      } on DioException catch (e) {
        if (_isNetworkError(e)) {
          return _saveNutritionLocally(parsedData, date);
        }
        return {'success': false, 'offline': false, 'error': e.message};
      }
    }

    return _saveNutritionLocally(parsedData, date);
  }

  Future<Map<String, dynamic>> _saveNutritionLocally(
    Map<String, dynamic> parsedData,
    String? date,
  ) async {
    final clientId = _uuid.v4();
    final targetDate = date ?? _todayDate();

    final payload = {
      'parsed_data': parsedData,
      'date': targetDate,
    };

    await _db.nutritionCacheDao.insertPendingNutrition(
      clientId: clientId,
      userId: _userId,
      parsedDataJson: jsonEncode(parsedData),
      targetDate: targetDate,
    );

    await _db.syncQueueDao.insertItem(
      clientId: clientId,
      userId: _userId,
      operationType: 'nutrition_log',
      payloadJson: jsonEncode(payload),
    );

    return {'success': true, 'offline': true};
  }

  String _todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown;
  }
}
