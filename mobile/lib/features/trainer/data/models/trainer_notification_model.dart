/// Data model for trainer notifications.
class TrainerNotificationModel {
  final int id;
  final String notificationType;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final String? readAt;
  final String createdAt;

  const TrainerNotificationModel({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.message,
    required this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory TrainerNotificationModel.fromJson(Map<String, dynamic> json) {
    return TrainerNotificationModel(
      id: json['id'] as int,
      notificationType: json['notification_type'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  /// Returns the trainee_id from the notification data, if present.
  int? get traineeId {
    final id = data['trainee_id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  /// Returns the trainee name from the notification data, if present.
  String? get traineeName => data['trainee_name'] as String?;

  /// Creates a copy with updated fields.
  TrainerNotificationModel copyWith({
    bool? isRead,
    String? readAt,
  }) {
    return TrainerNotificationModel(
      id: id,
      notificationType: notificationType,
      title: title,
      message: message,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}
