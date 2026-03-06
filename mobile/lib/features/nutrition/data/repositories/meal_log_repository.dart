import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/nutrition_models.dart';

class MealLogRepository {
  final ApiClient _apiClient;

  const MealLogRepository(this._apiClient);

  /// Get all meal logs for a given date.
  Future<Map<String, dynamic>> getMeals(String date) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.mealLogs,
        queryParameters: {'date': date},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data as List<dynamic>
            : (response.data as Map<String, dynamic>)['results'] as List<dynamic>? ?? [];
        final meals = data
            .map((e) => MealLogModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'meals': meals};
      }
      return {'success': false, 'error': 'Failed to load meals'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error']?.toString() ?? 'Failed to load meals',
      };
    }
  }

  /// Get aggregated daily macro summary.
  Future<Map<String, dynamic>> getSummary(String date) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.mealLogSummary,
        queryParameters: {'date': date},
      );

      if (response.statusCode == 200) {
        final summary =
            MealLogSummaryModel.fromJson(response.data as Map<String, dynamic>);
        return {'success': true, 'summary': summary};
      }
      return {'success': false, 'error': 'Failed to load summary'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error']?.toString() ?? 'Failed to load summary',
      };
    }
  }

  /// Quick-add a food entry. Auto-creates MealLog if needed.
  Future<Map<String, dynamic>> quickAdd({
    required String date,
    required int mealNumber,
    String mealName = '',
    int? foodItemId,
    String customName = '',
    double quantity = 1.0,
    String servingUnit = 'serving',
    int calories = 0,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
    String fatMode = 'total_fat',
  }) async {
    try {
      final body = <String, dynamic>{
        'date': date,
        'meal_number': mealNumber,
        'meal_name': mealName,
        'quantity': quantity,
        'serving_unit': servingUnit,
        'fat_mode': fatMode,
      };

      if (foodItemId != null) {
        body['food_item_id'] = foodItemId;
      } else {
        body['custom_name'] = customName;
        body['calories'] = calories;
        body['protein'] = protein;
        body['carbs'] = carbs;
        body['fat'] = fat;
      }

      final response = await _apiClient.dio.post(
        ApiConstants.mealLogQuickAdd,
        data: body,
      );

      if (response.statusCode == 201) {
        final mealLog =
            MealLogModel.fromJson(response.data as Map<String, dynamic>);
        return {'success': true, 'meal': mealLog};
      }
      return {'success': false, 'error': 'Failed to add food entry'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error']?.toString() ?? 'Failed to add food entry',
      };
    }
  }

  /// Delete a single meal log entry.
  Future<Map<String, dynamic>> deleteEntry(int entryId) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiConstants.mealLogEntryDelete(entryId),
      );

      if (response.statusCode == 204) {
        return {'success': true};
      }
      return {'success': false, 'error': 'Failed to delete entry'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error']?.toString() ?? 'Failed to delete entry',
      };
    }
  }

  /// Get the trainee's active nutrition template assignment (includes fat_mode).
  Future<Map<String, dynamic>> getActiveAssignment() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.activeNutritionAssignment,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data as Map<String, dynamic>};
      }
      return {'success': false, 'error': 'No active assignment'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'success': false, 'error': 'No active nutrition template assignment.'};
      }
      return {
        'success': false,
        'error': e.response?.data?['error']?.toString() ?? 'Failed to load assignment',
      };
    }
  }
}
