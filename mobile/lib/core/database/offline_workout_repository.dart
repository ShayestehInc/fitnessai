import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:uuid/uuid.dart';

import '../../features/workout_log/data/models/workout_models.dart';
import '../../features/workout_log/data/repositories/workout_repository.dart';
import '../services/connectivity_service.dart';
import '../services/sync_status.dart';
import 'app_database.dart';
import 'offline_save_result.dart';

const _uuid = Uuid();

/// Wraps [WorkoutRepository] with offline fallback behavior.
/// When online: delegates to the real API via [WorkoutRepository].
/// When offline: saves to Drift and queues for later sync.
class OfflineWorkoutRepository {
  final WorkoutRepository _onlineRepo;
  final AppDatabase _db;
  final ConnectivityService _connectivityService;
  final int _userId;

  OfflineWorkoutRepository({
    required WorkoutRepository onlineRepo,
    required AppDatabase db,
    required ConnectivityService connectivityService,
    required int userId,
  })  : _onlineRepo = onlineRepo,
        _db = db,
        _connectivityService = connectivityService,
        _userId = userId;

  /// Submit a post-workout survey. Falls back to local save if offline.
  ///
  /// [clientId] must be generated once at the call site and reused on retry.
  /// This enables idempotency: if the same workout submission is attempted
  /// twice (e.g., connectivity flickers), the duplicate is caught.
  Future<OfflineSaveResult> submitPostWorkoutSurvey({
    required String clientId,
    required Map<String, dynamic> workoutSummary,
    required Map<String, dynamic> surveyData,
    Map<String, dynamic>? readinessSurvey,
  }) async {
    if (_connectivityService.isOnline) {
      try {
        final result = await _onlineRepo.submitPostWorkoutSurvey(
          workoutSummary: workoutSummary,
          surveyData: surveyData,
          readinessSurvey: readinessSurvey,
        );
        if (result['success'] == true) {
          return const OfflineSaveResult.onlineSuccess();
        }
        return OfflineSaveResult.failure(
          result['error']?.toString() ?? 'Failed to save workout',
        );
      } on DioException catch (e) {
        if (_isNetworkError(e)) {
          return _saveWorkoutLocally(
            clientId: clientId,
            workoutSummary: workoutSummary,
            surveyData: surveyData,
            readinessSurvey: readinessSurvey,
          );
        }
        return OfflineSaveResult.failure(e.message ?? 'Network error');
      }
    }

    return _saveWorkoutLocally(
      clientId: clientId,
      workoutSummary: workoutSummary,
      surveyData: surveyData,
      readinessSurvey: readinessSurvey,
    );
  }

  Future<OfflineSaveResult> _saveWorkoutLocally({
    required String clientId,
    required Map<String, dynamic> workoutSummary,
    required Map<String, dynamic> surveyData,
    Map<String, dynamic>? readinessSurvey,
  }) async {
    // Idempotency check: if this clientId already exists, it's a duplicate
    final alreadyExists =
        await _db.syncQueueDao.existsByClientId(clientId);
    if (alreadyExists) {
      return const OfflineSaveResult.offlineSuccess();
    }

    final payload = {
      'workout_summary': workoutSummary,
      'survey_data': surveyData,
      'readiness_survey': readinessSurvey,
    };

    try {
      await _db.workoutCacheDao.insertPendingWorkout(
        clientId: clientId,
        userId: _userId,
        workoutSummaryJson: jsonEncode(workoutSummary),
        surveyDataJson: jsonEncode(surveyData),
        readinessSurveyJson:
            readinessSurvey != null ? jsonEncode(readinessSurvey) : null,
      );

      await _db.syncQueueDao.insertItem(
        clientId: clientId,
        userId: _userId,
        operationType: SyncOperationType.workoutLog.value,
        payloadJson: jsonEncode(payload),
      );

      return const OfflineSaveResult.offlineSuccess();
    } on SqliteException catch (e) {
      if (e.toString().contains('full')) {
        return const OfflineSaveResult.failure(
          'Device storage is full. Free up space to save workout data.',
        );
      }
      rethrow;
    }
  }

  /// Submit a readiness survey. Falls back to local queue if offline.
  Future<OfflineSaveResult> submitReadinessSurvey({
    required String workoutName,
    required Map<String, dynamic> surveyData,
  }) async {
    if (_connectivityService.isOnline) {
      try {
        final result = await _onlineRepo.submitReadinessSurvey(
          workoutName: workoutName,
          surveyData: surveyData,
        );
        if (result['success'] == true) {
          return const OfflineSaveResult.onlineSuccess();
        }
        return OfflineSaveResult.failure(
          result['error']?.toString() ?? 'Failed to save survey',
        );
      } on DioException catch (e) {
        if (_isNetworkError(e)) {
          return _saveReadinessSurveyLocally(
            workoutName: workoutName,
            surveyData: surveyData,
          );
        }
        return OfflineSaveResult.failure(e.message ?? 'Network error');
      }
    }

    return _saveReadinessSurveyLocally(
      workoutName: workoutName,
      surveyData: surveyData,
    );
  }

  Future<OfflineSaveResult> _saveReadinessSurveyLocally({
    required String workoutName,
    required Map<String, dynamic> surveyData,
  }) async {
    final clientId = _uuid.v4();
    final payload = {
      'workout_name': workoutName,
      'survey_data': surveyData,
    };

    try {
      await _db.syncQueueDao.insertItem(
        clientId: clientId,
        userId: _userId,
        operationType: SyncOperationType.readinessSurvey.value,
        payloadJson: jsonEncode(payload),
      );

      return const OfflineSaveResult.offlineSuccess();
    } on SqliteException catch (e) {
      if (e.toString().contains('full')) {
        return const OfflineSaveResult.failure(
          'Device storage is full. Free up space to save data.',
        );
      }
      rethrow;
    }
  }

  /// Get programs with offline cache fallback.
  Future<Map<String, dynamic>> getPrograms() async {
    if (_connectivityService.isOnline) {
      try {
        final result = await _onlineRepo.getPrograms();
        if (result['success'] == true) {
          // Cache the programs
          final programs = result['programs'] as List<ProgramModel>;
          final programsJson =
              jsonEncode(programs.map((p) => p.toJson()).toList());
          await _db.programCacheDao.cachePrograms(
            userId: _userId,
            programsJson: programsJson,
          );
          return result;
        }
        // Online but API error: try cache
        return _getProgramsFromCache();
      } on DioException catch (e) {
        if (_isNetworkError(e)) {
          return _getProgramsFromCache();
        }
        return {'success': false, 'error': e.message};
      }
    }

    return _getProgramsFromCache();
  }

  Future<Map<String, dynamic>> _getProgramsFromCache() async {
    final cached =
        await _db.programCacheDao.getCachedPrograms(_userId);
    if (cached == null) {
      return {
        'success': false,
        'error': 'No program data available. Connect to the internet '
            'to load your program.',
        'fromCache': true,
      };
    }

    final programsData =
        jsonDecode(cached.programsJson) as List<dynamic>;
    final programs =
        programsData.map((json) => ProgramModel.fromJson(json)).toList();

    return {
      'success': true,
      'programs': programs,
      'fromCache': true,
    };
  }

  /// Get active program with offline cache fallback.
  Future<Map<String, dynamic>> getActiveProgram() async {
    final result = await getPrograms();
    if (result['success'] != true) return result;

    final programs = result['programs'] as List<ProgramModel>;
    if (programs.isEmpty) {
      return {'success': false, 'error': 'No active program found'};
    }

    ProgramModel? activeProgram;
    for (final p in programs) {
      if (p.isActive) {
        activeProgram = p;
        break;
      }
    }
    activeProgram ??= programs.first;

    return {
      'success': true,
      'program': activeProgram,
      'fromCache': result['fromCache'] ?? false,
    };
  }

  /// Delegate: get daily workout summary (online only, no cache).
  Future<Map<String, dynamic>> getDailyWorkoutSummary(String date) {
    return _onlineRepo.getDailyWorkoutSummary(date);
  }

  /// Delegate: get workout history (online only).
  Future<Map<String, dynamic>> getWorkoutHistory({
    int page = 1,
    int pageSize = 20,
  }) {
    return _onlineRepo.getWorkoutHistory(page: page, pageSize: pageSize);
  }

  /// Delegate: get recent workouts (online only).
  Future<Map<String, dynamic>> getRecentWorkouts({int limit = 3}) {
    return _onlineRepo.getRecentWorkouts(limit: limit);
  }

  /// Delegate: get weekly progress (online only).
  Future<Map<String, dynamic>> getWeeklyProgress() {
    return _onlineRepo.getWeeklyProgress();
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.type == DioExceptionType.unknown && e.error is SocketException);
  }
}
