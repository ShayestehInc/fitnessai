/// Data model for a messaging conversation.
class ConversationModel {
  final int id;
  final ConversationParticipant trainer;
  final ConversationParticipant trainee;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;
  final bool isArchived;
  final DateTime createdAt;

  const ConversationModel({
    required this.id,
    required this.trainer,
    required this.trainee,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.unreadCount = 0,
    this.isArchived = false,
    required this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as int,
      trainer: ConversationParticipant.fromJson(
        json['trainer'] as Map<String, dynamic>,
      ),
      trainee: ConversationParticipant.fromJson(
        json['trainee'] as Map<String, dynamic>,
      ),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessagePreview: json['last_message_preview'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  ConversationModel copyWith({
    int? unreadCount,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
  }) {
    return ConversationModel(
      id: id,
      trainer: trainer,
      trainee: trainee,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      isArchived: isArchived,
      createdAt: createdAt,
    );
  }
}

/// Participant info in a conversation.
class ConversationParticipant {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? profileImage;

  const ConversationParticipant({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profileImage,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileImage: json['profile_image'] as String?,
    );
  }

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : email;
  }

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    final result = '$first$last'.toUpperCase();
    return result.isNotEmpty ? result : '?';
  }
}
