/// Data model for a direct message.
class MessageModel {
  final int id;
  final int conversationId;
  final MessageSender sender;
  final String content;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  /// Client-side only: whether this message failed to send.
  final bool isSendFailed;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.content,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.isSendFailed = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      sender: MessageSender.fromJson(json['sender'] as Map<String, dynamic>),
      content: json['content'] as String,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  MessageModel copyWith({
    bool? isRead,
    DateTime? readAt,
    bool? isSendFailed,
  }) {
    return MessageModel(
      id: id,
      conversationId: conversationId,
      sender: sender,
      content: content,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      isSendFailed: isSendFailed ?? this.isSendFailed,
    );
  }
}

/// Sender info nested in a message.
class MessageSender {
  final int id;
  final String firstName;
  final String lastName;
  final String? profileImage;

  const MessageSender({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileImage,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      profileImage: json['profile_image'] as String?,
    );
  }

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : 'Unknown';
  }
}

/// Paginated messages response.
class MessagesResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<MessageModel> results;

  const MessagesResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory MessagesResponse.fromJson(Map<String, dynamic> json) {
    return MessagesResponse(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Response when starting a new conversation.
class StartConversationResponse {
  final int conversationId;
  final MessageModel message;
  final bool isNewConversation;

  const StartConversationResponse({
    required this.conversationId,
    required this.message,
    required this.isNewConversation,
  });

  factory StartConversationResponse.fromJson(Map<String, dynamic> json) {
    return StartConversationResponse(
      conversationId: json['conversation_id'] as int,
      message: MessageModel.fromJson(json['message'] as Map<String, dynamic>),
      isNewConversation: json['is_new_conversation'] as bool? ?? false,
    );
  }
}
