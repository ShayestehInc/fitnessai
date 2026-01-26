import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_profile_model.dart';

class OnboardingRepository {
  final ApiClient _apiClient;

  OnboardingRepository(this._apiClient);

  /// Get the current user's profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.profiles);

      if (response.statusCode == 200) {
        final profile = UserProfileModel.fromJson(response.data);
        return {'success': true, 'profile': profile};
      }

      return {'success': false, 'error': 'Failed to get profile'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to get profile',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update profile during onboarding (partial update)
  Future<Map<String, dynamic>> updateOnboardingStep(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.onboardingStep,
        data: data,
      );

      if (response.statusCode == 200) {
        final profile = UserProfileModel.fromJson(response.data);
        return {'success': true, 'profile': profile};
      }

      return {'success': false, 'error': 'Failed to update profile'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to update profile',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Complete onboarding and calculate nutrition goals
  Future<Map<String, dynamic>> completeOnboarding() async {
    try {
      final response = await _apiClient.dio.post(ApiConstants.completeOnboarding);

      if (response.statusCode == 200) {
        final result = OnboardingCompleteResponse.fromJson(response.data);
        return {
          'success': true,
          'profile': result.profile,
          'nutrition_goals': result.nutritionGoals,
        };
      }

      return {'success': false, 'error': 'Failed to complete onboarding'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to complete onboarding',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
