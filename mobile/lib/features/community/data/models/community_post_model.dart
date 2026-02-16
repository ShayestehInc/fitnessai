/// Data model for a community feed post.
class CommunityPostModel {
  final int id;
  final PostAuthor author;
  final String content;
  final String postType;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final ReactionCounts reactions;
  final List<String> userReactions;

  const CommunityPostModel({
    required this.id,
    required this.author,
    required this.content,
    required this.postType,
    required this.metadata,
    required this.createdAt,
    required this.reactions,
    required this.userReactions,
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    return CommunityPostModel(
      id: json['id'] as int,
      author: PostAuthor.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'] as String,
      postType: json['post_type'] as String? ?? 'text',
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      reactions: ReactionCounts.fromJson(
        (json['reactions'] as Map<String, dynamic>?) ?? {},
      ),
      userReactions: (json['user_reactions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Whether this is an auto-generated post (workout, achievement, milestone).
  bool get isAutoPost => postType != 'text';

  /// Total reaction count across all types.
  int get totalReactions =>
      reactions.fire + reactions.thumbsUp + reactions.heart;

  CommunityPostModel copyWith({
    ReactionCounts? reactions,
    List<String>? userReactions,
  }) {
    return CommunityPostModel(
      id: id,
      author: author,
      content: content,
      postType: postType,
      metadata: metadata,
      createdAt: createdAt,
      reactions: reactions ?? this.reactions,
      userReactions: userReactions ?? this.userReactions,
    );
  }
}

/// Author info nested in a community post.
class PostAuthor {
  final int id;
  final String firstName;
  final String lastName;
  final String? profileImage;

  const PostAuthor({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileImage,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      profileImage: json['profile_image'] as String?,
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

/// Reaction counts by type.
class ReactionCounts {
  final int fire;
  final int thumbsUp;
  final int heart;

  const ReactionCounts({
    this.fire = 0,
    this.thumbsUp = 0,
    this.heart = 0,
  });

  factory ReactionCounts.fromJson(Map<String, dynamic> json) {
    return ReactionCounts(
      fire: json['fire'] as int? ?? 0,
      thumbsUp: json['thumbs_up'] as int? ?? 0,
      heart: json['heart'] as int? ?? 0,
    );
  }
}

/// Paginated feed response.
class CommunityFeedResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<CommunityPostModel> results;

  const CommunityFeedResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory CommunityFeedResponse.fromJson(Map<String, dynamic> json) {
    return CommunityFeedResponse(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => CommunityPostModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Response after toggling a reaction.
class ReactionToggleResponse {
  final ReactionCounts reactions;
  final List<String> userReactions;

  const ReactionToggleResponse({
    required this.reactions,
    required this.userReactions,
  });

  factory ReactionToggleResponse.fromJson(Map<String, dynamic> json) {
    return ReactionToggleResponse(
      reactions: ReactionCounts.fromJson(
        (json['reactions'] as Map<String, dynamic>?) ?? {},
      ),
      userReactions: (json['user_reactions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
