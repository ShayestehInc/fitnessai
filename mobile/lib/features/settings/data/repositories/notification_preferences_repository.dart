import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';

class NotificationPreferencesRepository {
  final ApiClient _apiClient;

  NotificationPreferencesRepository(this._apiClient);

  Future<Map<String, bool>> getPreferences() async {
    final response = await _apiClient.dio.get(ApiConstants.notificationPreferences);
    final data = response.data;
    if (data is! Map) {
      throw FormatException(
        'Unexpected response format for notification preferences: ${data.runtimeType}',
      );
    }
    return Map<String, bool>.from(data);
  }

  Future<Map<String, bool>> updatePreference(String category, bool enabled) async {
    final response = await _apiClient.dio.patch(
      ApiConstants.notificationPreferences,
      data: {category: enabled},
    );
    final data = response.data;
    if (data is! Map) {
      throw FormatException(
        'Unexpected response format for notification preferences: ${data.runtimeType}',
      );
    }
    return Map<String, bool>.from(data);
  }
}
