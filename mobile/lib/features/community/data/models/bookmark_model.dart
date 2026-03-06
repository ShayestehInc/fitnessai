/// Data model for a bookmarked post.
class BookmarkModel {
  final int id;
  final int postId;
  final String postContent;
  final String postAuthorName;
  final String? collectionName;
  final DateTime createdAt;

  const BookmarkModel({
    required this.id,
    required this.postId,
    required this.postContent,
    required this.postAuthorName,
    this.collectionName,
    required this.createdAt,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      postContent: json['post_content'] as String? ?? '',
      postAuthorName: json['post_author_name'] as String? ?? 'Anonymous',
      collectionName: json['collection_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Data model for a bookmark collection.
class BookmarkCollectionModel {
  final int id;
  final String name;
  final DateTime createdAt;
  final int bookmarkCount;

  const BookmarkCollectionModel({
    required this.id,
    required this.name,
    required this.createdAt,
    this.bookmarkCount = 0,
  });

  factory BookmarkCollectionModel.fromJson(Map<String, dynamic> json) {
    return BookmarkCollectionModel(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      bookmarkCount: json['bookmark_count'] as int? ?? 0,
    );
  }
}
