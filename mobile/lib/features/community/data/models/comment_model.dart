/// Data model for a comment on a community post.
/// Supports one level of threading via parentCommentId and replies.
class CommentModel {
  final int id;
  final int postId;
  final int? parentCommentId;
  final int authorId;
  final String authorFirstName;
  final String authorLastName;
  final String? authorProfileImage;
  final String content;
  final DateTime createdAt;
  final List<CommentModel> replies;

  const CommentModel({
    required this.id,
    required this.postId,
    this.parentCommentId,
    required this.authorId,
    required this.authorFirstName,
    required this.authorLastName,
    this.authorProfileImage,
    required this.content,
    required this.createdAt,
    this.replies = const [],
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      parentCommentId: json['parent_comment_id'] as int?,
      authorId: json['author_id'] as int,
      authorFirstName: json['author_first_name'] as String? ?? '',
      authorLastName: json['author_last_name'] as String? ?? '',
      authorProfileImage: json['author_profile_image'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      replies: (json['replies'] as List<dynamic>?)
              ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get isReply => parentCommentId != null;
  bool get hasReplies => replies.isNotEmpty;

  String get authorDisplayName {
    final full = '$authorFirstName $authorLastName'.trim();
    return full.isNotEmpty ? full : 'Anonymous';
  }

  String get authorInitials {
    final first = authorFirstName.isNotEmpty ? authorFirstName[0] : '';
    final last = authorLastName.isNotEmpty ? authorLastName[0] : '';
    final result = '$first$last'.toUpperCase();
    return result.isNotEmpty ? result : '?';
  }
}
