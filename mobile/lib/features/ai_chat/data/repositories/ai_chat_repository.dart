import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/chat_models.dart';

class AIChatRepository {
  final ApiClient _apiClient;

  AIChatRepository(this._apiClient);

  /// Send a message to the AI assistant
  Future<ChatResponse> sendMessage({
    required String message,
    List<ChatMessage>? conversationHistory,
    int? traineeId,
  }) async {
    try {
      final data = <String, dynamic>{
        'message': message,
      };

      if (traineeId != null) {
        data['trainee_id'] = traineeId;
      }

      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        data['conversation_history'] = conversationHistory
            .where((m) => !m.isLoading)
            .map((m) => m.toHistoryFormat())
            .toList();
      }

      final response = await _apiClient.dio.post(
        ApiConstants.trainerAiChat,
        data: data,
      );

      if (response.statusCode == 200) {
        return ChatResponse.fromJson(response.data);
      }

      return ChatResponse.error('Failed to get response');
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['error'] ?? 'Network error occurred';
      return ChatResponse.error(errorMessage);
    } catch (e) {
      return ChatResponse.error(e.toString());
    }
  }

  /// Get trainee context (for debugging/preview)
  Future<Map<String, dynamic>?> getTraineeContext(int traineeId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.trainerAiContext(traineeId),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get list of trainees for selection
  Future<List<TraineeOption>> getTrainees() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.trainerTrainees,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : response.data['results'] ?? [];
        return data.map((e) => TraineeOption.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
