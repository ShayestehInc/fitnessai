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
}
