/// Data model for a community Space (sub-community).
class SpaceModel {
  final int id;
  final String name;
  final String description;
  final String? coverImageUrl;
  final String emoji;
  final String visibility;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;
  final int memberCount;
  final bool isMember;

  const SpaceModel({
    required this.id,
    required this.name,
    this.description = '',
    this.coverImageUrl,
    this.emoji = '💬',
    this.visibility = 'public',
    this.isDefault = false,
    this.sortOrder = 0,
    required this.createdAt,
    this.memberCount = 0,
    this.isMember = false,
  });

  factory SpaceModel.fromJson(Map<String, dynamic> json) {
    return SpaceModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      coverImageUrl: json['cover_image_url'] as String?,
      emoji: json['emoji'] as String? ?? '💬',
      visibility: json['visibility'] as String? ?? 'public',
      isDefault: json['is_default'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      memberCount: json['member_count'] as int? ?? 0,
      isMember: json['is_member'] as bool? ?? false,
    );
  }

  SpaceModel copyWith({
    bool? isMember,
    int? memberCount,
  }) {
    return SpaceModel(
      id: id,
      name: name,
      description: description,
      coverImageUrl: coverImageUrl,
      emoji: emoji,
      visibility: visibility,
      isDefault: isDefault,
      sortOrder: sortOrder,
      createdAt: createdAt,
      memberCount: memberCount ?? this.memberCount,
      isMember: isMember ?? this.isMember,
    );
  }

  bool get isPublic => visibility == 'public';
  bool get isPrivate => visibility == 'private';
}

/// Data model for a space membership.
class SpaceMembershipModel {
  final int userId;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final String role;
  final DateTime joinedAt;
  final bool isMuted;

  const SpaceMembershipModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    this.role = 'member',
    required this.joinedAt,
    this.isMuted = false,
  });

  factory SpaceMembershipModel.fromJson(Map<String, dynamic> json) {
    return SpaceMembershipModel(
      userId: json['user_id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      profileImage: json['profile_image'] as String?,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
      isMuted: json['is_muted'] as bool? ?? false,
    );
  }

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : 'Anonymous';
  }

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    final result = '$first$last'.toUpperCase();
    return result.isNotEmpty ? result : '?';
  }
}
