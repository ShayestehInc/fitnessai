/// Data model for trainer announcements.
class AnnouncementModel {
  final int id;
  final String title;
  final String body;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'is_pinned': isPinned,
    };
  }
}

/// Response model for unread announcement count.
class UnreadCountModel {
  final int unreadCount;

  const UnreadCountModel({required this.unreadCount});

  factory UnreadCountModel.fromJson(Map<String, dynamic> json) {
    return UnreadCountModel(
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}
