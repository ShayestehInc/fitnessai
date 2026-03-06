import 'post_video_model.dart';

/// Data model for a community feed post.
class CommunityPostModel {
  final int id;
  final PostAuthor author;
  final String content;
  final String postType;
  final String contentFormat;
  final String? imageUrl;
  final List<PostImageModel> images;
  final List<PostVideoModel> videos;
  final PostSpaceInfo? space;
  final bool isPinned;
  final bool isBookmarked;
  final Map<String, dynamic> metadata;
  final int commentCount;
  final DateTime createdAt;
  final ReactionCounts reactions;
  final List<String> userReactions;

  const CommunityPostModel({
    required this.id,
    required this.author,
    required this.content,
    required this.postType,
    this.contentFormat = 'plain',
    this.imageUrl,
    this.images = const [],
    this.videos = const [],
    this.space,
    this.isPinned = false,
    this.isBookmarked = false,
    required this.metadata,
    this.commentCount = 0,
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
      contentFormat: json['content_format'] as String? ?? 'plain',
      imageUrl: json['image_url'] as String?,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => PostImageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      videos: (json['videos'] as List<dynamic>?)
              ?.map((e) => PostVideoModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      space: json['space'] != null
          ? PostSpaceInfo.fromJson(json['space'] as Map<String, dynamic>)
          : null,
      isPinned: json['is_pinned'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      commentCount: json['comment_count'] as int? ?? 0,
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

  /// Whether this post has markdown content.
  bool get isMarkdown => contentFormat == 'markdown';

  /// Whether this post has any image attachments.
  bool get hasImage => images.isNotEmpty || (imageUrl != null && imageUrl!.isNotEmpty);

  /// Whether this post has multiple images.
  bool get hasMultipleImages => images.length > 1;

  /// Whether this post has any video attachments.
  bool get hasVideo => videos.isNotEmpty;

  /// Total reaction count across all types.
  int get totalReactions =>
      reactions.fire + reactions.thumbsUp + reactions.heart;

  CommunityPostModel copyWith({
    ReactionCounts? reactions,
    List<String>? userReactions,
    int? commentCount,
    bool? isBookmarked,
    bool? isPinned,
  }) {
    return CommunityPostModel(
      id: id,
      author: author,
      content: content,
      postType: postType,
      contentFormat: contentFormat,
      imageUrl: imageUrl,
      images: images,
      videos: videos,
      space: space,
      isPinned: isPinned ?? this.isPinned,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      metadata: metadata,
      commentCount: commentCount ?? this.commentCount,
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

/// Image attached to a post (multi-image support).
class PostImageModel {
  final int? id;
  final String url;
  final int sortOrder;

  const PostImageModel({
    this.id,
    required this.url,
    this.sortOrder = 0,
  });

  factory PostImageModel.fromJson(Map<String, dynamic> json) {
    return PostImageModel(
      id: json['id'] as int?,
      url: json['url'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

/// Minimal space info nested in a post.
class PostSpaceInfo {
  final int id;
  final String name;
  final String emoji;

  const PostSpaceInfo({
    required this.id,
    required this.name,
    this.emoji = '💬',
  });

  factory PostSpaceInfo.fromJson(Map<String, dynamic> json) {
    return PostSpaceInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '💬',
    );
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
