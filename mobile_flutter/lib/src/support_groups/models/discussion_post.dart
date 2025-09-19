/// Discussion Post model representing user-generated content in support groups
class DiscussionPost {
  /// A unique identifier for the post
  final String postId;
  
  /// The group this post belongs to
  final String groupId;
  
  /// The author's ID
  final String userId;
  
  /// The author's display name
  final String userDisplayName;
  
  /// The post's title/subject
  final String title;
  
  /// The main body of the post
  final String content;
  
  /// When the post was created
  final DateTime timestamp;
  
  /// If the post is pinned by a moderator (e.g., for welcome messages)
  final bool isPinned;
  
  /// Flag indicating if the post has been modified
  final bool isEdited;
  
  /// List of user IDs who have "liked" the post
  final List<String> likes;
  
  /// The number of comments on the post
  final int commentCount;
  
  /// Constructor for the DiscussionPost class
  DiscussionPost({
    required this.postId,
    required this.groupId,
    required this.userId,
    required this.userDisplayName,
    required this.title,
    required this.content,
    required this.timestamp,
    this.isPinned = false,
    this.isEdited = false,
    this.likes = const [],
    this.commentCount = 0,
  });
  
  /// Create a DiscussionPost from JSON
  factory DiscussionPost.fromJson(Map<String, dynamic> json) {
    return DiscussionPost(
      postId: json['postId'] as String,
      groupId: json['groupId'] as String,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      isEdited: json['isEdited'] as bool? ?? false,
      likes: List<String>.from(json['likes'] ?? []),
      commentCount: json['commentCount'] as int? ?? 0,
    );
  }
  
  /// Convert DiscussionPost to JSON
  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'groupId': groupId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isPinned': isPinned,
      'isEdited': isEdited,
      'likes': likes,
      'commentCount': commentCount,
    };
  }
  
  /// Create a copy of this post with updated fields
  DiscussionPost copyWith({
    String? postId,
    String? groupId,
    String? userId,
    String? userDisplayName,
    String? title,
    String? content,
    DateTime? timestamp,
    bool? isPinned,
    bool? isEdited,
    List<String>? likes,
    int? commentCount,
  }) {
    return DiscussionPost(
      postId: postId ?? this.postId,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      title: title ?? this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isPinned: isPinned ?? this.isPinned,
      isEdited: isEdited ?? this.isEdited,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
    );
  }
  
  /// Check if a specific user has liked this post
  bool isLikedBy(String userId) {
    return likes.contains(userId);
  }
  
  /// Check if the current user is the author of this post
  bool isAuthor(String userId) {
    return this.userId == userId;
  }
  
  @override
  String toString() {
    return 'DiscussionPost{postId: $postId, title: $title, userDisplayName: $userDisplayName}';
  }
}