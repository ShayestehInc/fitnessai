import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/nutrition_models.dart';

class NutritionRepository {
  final ApiClient _apiClient;

  NutritionRepository(this._apiClient);

  /// Get nutrition goals for current user
  Future<Map<String, dynamic>> getNutritionGoals() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.nutritionGoals);

      if (response.statusCode == 200) {
        final goals = NutritionGoalModel.fromJson(response.data);
        return {'success': true, 'goals': goals};
      }

      return {'success': false, 'error': 'Failed to get nutrition goals'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to get nutrition goals',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get daily nutrition summary
  Future<Map<String, dynamic>> getDailyNutritionSummary(String date) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.nutritionSummary,
        queryParameters: {'date': date},
      );

      if (response.statusCode == 200) {
        final summary = DailyNutritionSummary.fromJson(response.data);
        return {'success': true, 'summary': summary};
      }

      return {'success': false, 'error': 'Failed to get nutrition summary'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to get nutrition summary',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get latest weight check-in
  Future<Map<String, dynamic>> getLatestWeightCheckIn() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.latestWeightCheckIn);

      if (response.statusCode == 200) {
        final checkIn = WeightCheckInModel.fromJson(response.data);
        return {'success': true, 'checkIn': checkIn};
      }

      return {'success': false, 'error': 'No weight check-ins found'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'success': false, 'error': 'No weight check-ins found'};
      }
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to get weight check-in',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create a new weight check-in
  Future<Map<String, dynamic>> createWeightCheckIn({
    required String date,
    required double weightKg,
    String notes = '',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.weightCheckIns,
        data: {
          'date': date,
          'weight_kg': weightKg,
          'notes': notes,
        },
      );

      if (response.statusCode == 201) {
        final checkIn = WeightCheckInModel.fromJson(response.data);
        return {'success': true, 'checkIn': checkIn};
      }

      return {'success': false, 'error': 'Failed to create weight check-in'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to create weight check-in',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get weight check-in history
  Future<Map<String, dynamic>> getWeightCheckInHistory() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.weightCheckIns);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final checkIns =
            data.map((json) => WeightCheckInModel.fromJson(json)).toList();
        return {'success': true, 'checkIns': checkIns};
      }

      return {'success': false, 'error': 'Failed to get weight history'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to get weight history',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get macro presets for current trainee
  Future<Map<String, dynamic>> getMacroPresets() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.macroPresets);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final presets =
            data.map((json) => MacroPresetModel.fromJson(json)).toList();
        return {'success': true, 'presets': presets};
      }

      return {'success': false, 'error': 'Failed to get macro presets'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to get macro presets',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Edit a food entry in a daily log
  Future<Map<String, dynamic>> editMealEntry({
    required int logId,
    required int mealIndex,
    required int entryIndex,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        ApiConstants.editMealEntry(logId),
        data: {
          'meal_index': mealIndex,
          'entry_index': entryIndex,
          'data': data,
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }

      return {'success': false, 'error': 'Failed to edit food entry'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to edit food entry',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Delete a food entry from a daily log
  Future<Map<String, dynamic>> deleteMealEntry({
    required int logId,
    required int mealIndex,
    required int entryIndex,
  }) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiConstants.deleteMealEntry(logId),
        data: {
          'meal_index': mealIndex,
          'entry_index': entryIndex,
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }

      return {'success': false, 'error': 'Failed to delete food entry'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'success': false, 'error': 'Entry no longer exists'};
      }
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to delete food entry',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get weekly workout progress
  Future<Map<String, dynamic>> getWeeklyProgress() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.weeklyProgress);

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }

      return {'success': false, 'error': 'Failed to get weekly progress'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to get weekly progress',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get the daily log ID for a specific date
  Future<Map<String, dynamic>> getDailyLogForDate(String date) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.dailyLogs,
        queryParameters: {'date': date},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Response could be a list or paginated result
        final List<dynamic> results = data is List
            ? data
            : (data is Map && data.containsKey('results'))
                ? data['results'] as List
                : [];

        if (results.isNotEmpty) {
          final log = results.first as Map<String, dynamic>;
          return {'success': true, 'logId': log['id'] as int};
        }

        return {'success': false, 'error': 'No log found for date'};
      }

      return {'success': false, 'error': 'Failed to get daily log'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to get daily log',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Apply a macro preset as the current day's goals
  Future<Map<String, dynamic>> applyMacroPreset(int presetId) async {
    try {
      // First get the preset details
      final presetResponse = await _apiClient.dio.get(
        ApiConstants.macroPreset(presetId),
      );

      if (presetResponse.statusCode != 200) {
        return {'success': false, 'error': 'Failed to get preset'};
      }

      final preset = MacroPresetModel.fromJson(presetResponse.data);

      // Update nutrition goals with preset values
      final response = await _apiClient.dio.patch(
        ApiConstants.nutritionGoals,
        data: {
          'protein_goal': preset.protein,
          'carbs_goal': preset.carbs,
          'fat_goal': preset.fat,
          'calories_goal': preset.calories,
        },
      );

      if (response.statusCode == 200) {
        final goals = NutritionGoalModel.fromJson(response.data);
        return {'success': true, 'goals': goals};
      }

      return {'success': false, 'error': 'Failed to apply preset'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to apply preset',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
