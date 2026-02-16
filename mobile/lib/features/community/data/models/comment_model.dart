/// Data model for a comment on a community post.
class CommentModel {
  final int id;
  final int postId;
  final int authorId;
  final String authorFirstName;
  final String authorLastName;
  final String? authorProfileImage;
  final String content;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorFirstName,
    required this.authorLastName,
    this.authorProfileImage,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      authorId: json['author_id'] as int,
      authorFirstName: json['author_first_name'] as String? ?? '',
      authorLastName: json['author_last_name'] as String? ?? '',
      authorProfileImage: json['author_profile_image'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

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
