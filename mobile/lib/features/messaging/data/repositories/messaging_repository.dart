import 'package:dio/dio.dart';

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
  /// Supports text-only, image-only, or text+image messages.
  Future<MessageModel> sendMessage({
    required int conversationId,
    String content = '',
    String? imagePath,
  }) async {
    if (imagePath != null) {
      return _sendMessageWithImage(
        url: ApiConstants.messagingConversationSend(conversationId),
        content: content,
        imagePath: imagePath,
      );
    }
    final response = await _apiClient.dio.post(
      ApiConstants.messagingConversationSend(conversationId),
      data: {'content': content},
    );
    return MessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Start a new conversation with a trainee.
  /// Supports text-only, image-only, or text+image messages.
  Future<StartConversationResponse> startConversation({
    required int traineeId,
    String content = '',
    String? imagePath,
  }) async {
    if (imagePath != null) {
      final formData = FormData.fromMap({
        'trainee_id': traineeId,
        if (content.isNotEmpty) 'content': content,
        'image': await MultipartFile.fromFile(imagePath),
      });
      final response = await _apiClient.dio.post(
        ApiConstants.messagingStartConversation,
        data: formData,
      );
      return StartConversationResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
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

  /// Send a message with an image attachment via multipart form data.
  Future<MessageModel> _sendMessageWithImage({
    required String url,
    required String content,
    required String imagePath,
  }) async {
    final formData = FormData.fromMap({
      if (content.isNotEmpty) 'content': content,
      'image': await MultipartFile.fromFile(imagePath),
    });
    final response = await _apiClient.dio.post(url, data: formData);
    return MessageModel.fromJson(response.data as Map<String, dynamic>);
  }
}
