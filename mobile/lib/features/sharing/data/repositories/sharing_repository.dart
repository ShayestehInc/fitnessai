import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/share_card_model.dart';

class SharingRepository {
  final ApiClient _apiClient;

  SharingRepository(this._apiClient);

  /// Fetches share card data for a specific workout log.
  ///
  /// Returns a map with 'success' boolean and either 'data' (ShareCardModel)
  /// on success or 'error' message on failure.
  Future<Map<String, dynamic>> fetchShareCard(int logId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.shareCard(logId),
      );

      if (response.statusCode == 200) {
        final shareCard = ShareCardModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'data': shareCard};
      }

      return {'success': false, 'error': 'Failed to load share card'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'success': false, 'error': 'Workout not found'};
      }
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load share card',
      };
    }
  }
}
