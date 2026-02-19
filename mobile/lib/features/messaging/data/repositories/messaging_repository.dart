import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Repository for messaging API calls.
class MessagingRepository {
  final ApiClient _apiClient;

  MessagingRepository(this._apiClient);

  /// Fetch all conversations for the current user.
  Future<List<ConversationModel>> getConversations() async {
    final response = await _apiClient.dio.get(
      ApiConstants.messagingConversations,
    );
    final data = response.data;
    final List<dynamic> results;
    if (data is List) {
      results = data;
    } else if (data is Map<String, dynamic> && data.containsKey('results')) {
      results = data['results'] as List<dynamic>;
    } else {
      results = [];
    }
    return results
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch paginated messages for a conversation.
  Future<MessagesResponse> getMessages({
    required int conversationId,
    int page = 1,
  }) async {
    final response = await _apiClient.dio.get(
      '${ApiConstants.messagingConversationMessages(conversationId)}?page=$page',
    );
    return MessagesResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Send a message in an existing conversation.
  Future<MessageModel> sendMessage({
    required int conversationId,
    required String content,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.messagingConversationSend(conversationId),
      data: {'content': content},
    );
    return MessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Start a new conversation with a trainee.
  Future<StartConversationResponse> startConversation({
    required int traineeId,
    required String content,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.messagingStartConversation,
      data: {
        'trainee_id': traineeId,
        'content': content,
      },
    );
    return StartConversationResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Mark a conversation as read.
  Future<void> markRead(int conversationId) async {
    await _apiClient.dio.post(
      ApiConstants.messagingMarkRead(conversationId),
    );
  }

  /// Get total unread count.
  Future<int> getUnreadCount() async {
    final response = await _apiClient.dio.get(
      ApiConstants.messagingUnreadCount,
    );
    final data = response.data as Map<String, dynamic>;
    return data['unread_count'] as int? ?? 0;
  }
}
