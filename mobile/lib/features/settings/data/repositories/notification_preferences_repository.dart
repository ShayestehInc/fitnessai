import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';

class NotificationPreferencesRepository {
  final ApiClient _apiClient;

  NotificationPreferencesRepository(this._apiClient);

  Future<Map<String, bool>> getPreferences() async {
    final response = await _apiClient.dio.get(ApiConstants.notificationPreferences);
    return Map<String, bool>.from(response.data as Map);
  }

  Future<Map<String, bool>> updatePreference(String category, bool enabled) async {
    final response = await _apiClient.dio.patch(
      ApiConstants.notificationPreferences,
      data: {category: enabled},
    );
    return Map<String, bool>.from(response.data as Map);
  }
}
