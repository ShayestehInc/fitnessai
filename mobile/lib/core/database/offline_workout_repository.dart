import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../features/workout_log/data/models/workout_models.dart';
import '../../features/workout_log/data/repositories/workout_repository.dart';
import '../services/connectivity_service.dart';
import 'app_database.dart';

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
  /// Returns a map with 'success', 'offline' (bool), and optionally 'error'.
  Future<Map<String, dynamic>> submitPostWorkoutSurvey({
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
          return {'success': true, 'offline': false};
        }
        // If it failed for a non-network reason, return the error
        return {'success': false, 'offline': false, 'error': result['error']};
      } on DioException catch (e) {
        if (_isNetworkError(e)) {
          return _saveWorkoutLocally(
            workoutSummary: workoutSummary,
            surveyData: surveyData,
            readinessSurvey: readinessSurvey,
          );
        }
        return {'success': false, 'offline': false, 'error': e.message};
      }
    }

    return _saveWorkoutLocally(
      workoutSummary: workoutSummary,
      surveyData: surveyData,
      readinessSurvey: readinessSurvey,
    );
  }

  Future<Map<String, dynamic>> _saveWorkoutLocally({
    required Map<String, dynamic> workoutSummary,
    required Map<String, dynamic> surveyData,
    Map<String, dynamic>? readinessSurvey,
  }) async {
    final clientId = _uuid.v4();

    // Check for duplicate
    final alreadyExists =
        await _db.syncQueueDao.existsByClientId(clientId);
    if (alreadyExists) {
      return {'success': true, 'offline': true};
    }

    final payload = {
      'workout_summary': workoutSummary,
      'survey_data': surveyData,
      'readiness_survey': readinessSurvey,
    };

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
      operationType: 'workout_log',
      payloadJson: jsonEncode(payload),
    );

    return {'success': true, 'offline': true};
  }

  /// Submit a readiness survey. Falls back to local queue if offline.
  Future<Map<String, dynamic>> submitReadinessSurvey({
    required String workoutName,
    required Map<String, dynamic> surveyData,
  }) async {
    if (_connectivityService.isOnline) {
      try {
        return await _onlineRepo.submitReadinessSurvey(
          workoutName: workoutName,
          surveyData: surveyData,
        );
      } on DioException catch (e) {
        if (_isNetworkError(e)) {
          return _saveReadinessSurveyLocally(
            workoutName: workoutName,
            surveyData: surveyData,
          );
        }
        return {'success': false, 'error': e.message};
      }
    }

    return _saveReadinessSurveyLocally(
      workoutName: workoutName,
      surveyData: surveyData,
    );
  }

  Future<Map<String, dynamic>> _saveReadinessSurveyLocally({
    required String workoutName,
    required Map<String, dynamic> surveyData,
  }) async {
    final clientId = _uuid.v4();
    final payload = {
      'workout_name': workoutName,
      'survey_data': surveyData,
    };

    await _db.syncQueueDao.insertItem(
      clientId: clientId,
      userId: _userId,
      operationType: 'readiness_survey',
      payloadJson: jsonEncode(payload),
    );

    return {'success': true, 'offline': true};
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
        e.type == DioExceptionType.unknown;
  }
}
