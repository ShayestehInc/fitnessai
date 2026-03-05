import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/habit_model.dart';

class HabitRepository {
  final ApiClient _apiClient;

  HabitRepository(this._apiClient);

  /// Fetches all habits for the current user (or trainer's trainee).
  Future<Map<String, dynamic>> fetchHabits() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.habits);
      final List<dynamic> results =
          response.data['results'] ?? response.data;
      final habits = results
          .map((e) => HabitModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return {
        'success': true,
        'data': habits,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load habits',
      };
    }
  }

  /// Fetches daily habits with completion status for a given date.
  ///
  /// [date] should be formatted as 'YYYY-MM-DD'.
  Future<Map<String, dynamic>> fetchDailyHabits(String date) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.habitDaily,
        queryParameters: {'date': date},
      );
      final List<dynamic> results =
          response.data['results'] ?? response.data;
      final dailyHabits = results
          .map((e) => DailyHabitModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return {
        'success': true,
        'data': dailyHabits,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to load daily habits',
      };
    }
  }

  /// Toggles the completion status of a habit for a given date.
  ///
  /// [habitId] is the id of the habit to toggle.
  /// [date] should be formatted as 'YYYY-MM-DD'.
  Future<Map<String, dynamic>> toggleHabit({
    required int habitId,
    required String date,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.habitToggle,
        data: {
          'habit_id': habitId,
          'date': date,
        },
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to toggle habit',
      };
    }
  }

  /// Fetches streak data for all habits.
  Future<Map<String, dynamic>> fetchStreaks() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.habitStreaks);
      final List<dynamic> results =
          response.data['results'] ?? response.data;
      final streaks = results
          .map(
              (e) => HabitStreakModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return {
        'success': true,
        'data': streaks,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load streaks',
      };
    }
  }

  /// Creates a new habit (trainer-facing).
  Future<Map<String, dynamic>> createHabit({
    required int traineeId,
    required String name,
    String description = '',
    String icon = 'check_circle',
    String frequency = 'daily',
    List<String> customDays = const [],
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.habits,
        data: {
          'trainee_id': traineeId,
          'name': name,
          'description': description,
          'icon': icon,
          'frequency': frequency,
          'custom_days': customDays,
        },
      );
      return {
        'success': true,
        'data': HabitModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to create habit',
      };
    }
  }

  /// Updates an existing habit.
  Future<Map<String, dynamic>> updateHabit({
    required int habitId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '${ApiConstants.habits}$habitId/',
        data: data,
      );
      return {
        'success': true,
        'data': HabitModel.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to update habit',
      };
    }
  }

  /// Deletes a habit.
  Future<Map<String, dynamic>> deleteHabit(int habitId) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.habits}$habitId/');
      return {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to delete habit',
      };
    }
  }
}
