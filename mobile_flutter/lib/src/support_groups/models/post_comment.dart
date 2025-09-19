/// Post Comment model representing comments on discussion posts
class PostComment {
  /// A unique identifier for the comment
  final String commentId;
  
  /// The post this comment belongs to
  final String postId;
  
  /// The author's ID
  final String userId;
  
  /// The author's display name
  final String userDisplayName;
  
  /// The main body of the comment
  final String content;
  
  /// When the comment was created
  final DateTime timestamp;
  
  /// Flag indicating if the comment has been modified
  final bool isEdited;
  
  /// List of user IDs who have "liked" the comment
  final List<String> likes;
  
  /// Constructor for the PostComment class
  PostComment({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.userDisplayName,
    required this.content,
    required this.timestamp,
    this.isEdited = false,
    this.likes = const [],
  });
  
  /// Create a PostComment from JSON
  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      commentId: json['commentId'] as String,
      postId: json['postId'] as String,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isEdited: json['isEdited'] as bool? ?? false,
      likes: List<String>.from(json['likes'] ?? []),
    );
  }
  
  /// Convert PostComment to JSON
  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'postId': postId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isEdited': isEdited,
      'likes': likes,
    };
  }
  
  /// Create a copy of this comment with updated fields
  PostComment copyWith({
    String? commentId,
    String? postId,
    String? userId,
    String? userDisplayName,
    String? content,
    DateTime? timestamp,
    bool? isEdited,
    List<String>? likes,
  }) {
    return PostComment(
      commentId: commentId ?? this.commentId,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isEdited: isEdited ?? this.isEdited,
      likes: likes ?? this.likes,
    );
  }
  
  /// Check if a specific user has liked this comment
  bool isLikedBy(String userId) {
    return likes.contains(userId);
  }
  
  /// Check if the current user is the author of this comment
  bool isAuthor(String userId) {
    return this.userId == userId;
  }
  
  @override
  String toString() {
    return 'PostComment{commentId: $commentId, userDisplayName: $userDisplayName}';
  }
}