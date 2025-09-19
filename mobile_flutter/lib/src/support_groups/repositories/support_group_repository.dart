import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/models.dart';

/// Repository for managing support groups data
class SupportGroupRepository {
  // For generating unique IDs
  final _uuid = const Uuid();
  
  // In-memory cache for support groups
  final Map<String, SupportGroup> _groupsCache = {};
  
  // In-memory cache for posts
  final Map<String, List<DiscussionPost>> _postsCache = {};
  
  // In-memory cache for comments
  final Map<String, List<PostComment>> _commentsCache = {};
  
  // Stream controllers for real-time updates
  final _groupsController = StreamController<List<SupportGroup>>.broadcast();
  final _postsControllers = <String, StreamController<List<DiscussionPost>>>{};
  final _commentsControllers = <String, StreamController<List<PostComment>>>{};
  
  /// Get a stream of all available support groups
  Stream<List<SupportGroup>> get groups => _groupsController.stream;
  
  /// Get a stream of posts for a specific group
  Stream<List<DiscussionPost>> getPostsStream(String groupId) {
    if (!_postsControllers.containsKey(groupId)) {
      _postsControllers[groupId] = StreamController<List<DiscussionPost>>.broadcast();
      // Initial fetch of posts would happen here in a real implementation
      // This would typically make a network request or read from a local database
    }
    return _postsControllers[groupId]!.stream;
  }
  
  /// Get a stream of comments for a specific post
  Stream<List<PostComment>> getCommentsStream(String postId) {
    if (!_commentsControllers.containsKey(postId)) {
      _commentsControllers[postId] = StreamController<List<PostComment>>.broadcast();
      // Initial fetch of comments would happen here in a real implementation
    }
    return _commentsControllers[postId]!.stream;
  }
  
  /// Fetch all support groups from the remote source
  Future<List<SupportGroup>> fetchGroups() async {
    // In a real implementation, this would make a network request
    // to fetch the groups from a remote source like Firebase.
    // For now, we'll return some example data.
    
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    final groups = _getExampleGroups();
    
    // Update the cache
    for (final group in groups) {
      _groupsCache[group.groupId] = group;
    }
    
    // Notify listeners
    _groupsController.add(groups);
    
    return groups;
  }
  
  /// Fetch posts for a specific group
  Future<List<DiscussionPost>> fetchPostsForGroup(String groupId) async {
    // In a real implementation, this would make a network request
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    
    // For now, return example posts if it's one of our example groups
    List<DiscussionPost> posts = [];
    
    if (groupId == 'diabetes_support') {
      posts = _getExampleDiabetesPosts();
    } else if (groupId == 'hypertension_community') {
      posts = _getExampleHypertensionPosts();
    } else if (groupId == 'kidney_health_forum') {
      posts = _getExampleKidneyPosts();
    }
    
    // Update the cache
    _postsCache[groupId] = posts;
    
    // Notify listeners
    if (_postsControllers.containsKey(groupId)) {
      _postsControllers[groupId]!.add(posts);
    }
    
    return posts;
  }
  
  /// Fetch comments for a specific post
  Future<List<PostComment>> fetchCommentsForPost(String postId) async {
    // In a real implementation, this would make a network request
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate network delay
    
    // For now, return example comments
    final comments = _getExampleComments(postId);
    
    // Update the cache
    _commentsCache[postId] = comments;
    
    // Notify listeners
    if (_commentsControllers.containsKey(postId)) {
      _commentsControllers[postId]!.add(comments);
    }
    
    return comments;
  }
  
  /// Create a new discussion post
  Future<DiscussionPost> createPost({
    required String groupId, 
    required String userId,
    required String userDisplayName,
    required String title,
    required String content,
  }) async {
    // Create a new post object
    final post = DiscussionPost(
      postId: _uuid.v4(),
      groupId: groupId,
      userId: userId,
      userDisplayName: userDisplayName,
      title: title,
      content: content,
      timestamp: DateTime.now(),
    );
    
    // In a real implementation, this would save the post to a remote source
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    
    // Update the local cache
    if (!_postsCache.containsKey(groupId)) {
      _postsCache[groupId] = [];
    }
    _postsCache[groupId]!.add(post);
    
    // Sort posts by pinned status and timestamp
    _postsCache[groupId]!.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.timestamp.compareTo(a.timestamp); // Newest first
    });
    
    // Notify listeners
    if (_postsControllers.containsKey(groupId)) {
      _postsControllers[groupId]!.add(_postsCache[groupId]!);
    }
    
    return post;
  }
  
  /// Add a comment to a post
  Future<PostComment> createComment({
    required String postId,
    required String userId,
    required String userDisplayName,
    required String content,
  }) async {
    // Find the post to update its comment count
    DiscussionPost? postToUpdate;
    String? groupId;
    
    for (final entry in _postsCache.entries) {
      final foundPost = entry.value.firstWhere(
        (post) => post.postId == postId,
        orElse: () => DiscussionPost(
          postId: '',
          groupId: '',
          userId: '',
          userDisplayName: '',
          title: '',
          content: '',
          timestamp: DateTime.now(),
        ),
      );
      
      if (foundPost.postId.isNotEmpty) {
        postToUpdate = foundPost;
        groupId = entry.key;
        break;
      }
    }
    
    // Create a new comment object
    final comment = PostComment(
      commentId: _uuid.v4(),
      postId: postId,
      userId: userId,
      userDisplayName: userDisplayName,
      content: content,
      timestamp: DateTime.now(),
    );
    
    // In a real implementation, this would save the comment to a remote source
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate network delay
    
    // Update the local cache for comments
    if (!_commentsCache.containsKey(postId)) {
      _commentsCache[postId] = [];
    }
    _commentsCache[postId]!.add(comment);
    
    // Sort comments by timestamp
    _commentsCache[postId]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Notify comments listeners
    if (_commentsControllers.containsKey(postId)) {
      _commentsControllers[postId]!.add(_commentsCache[postId]!);
    }
    
    // Update the post's comment count
    if (postToUpdate != null && groupId != null) {
      final updatedPost = postToUpdate.copyWith(
        commentCount: postToUpdate.commentCount + 1,
      );
      
      final postIndex = _postsCache[groupId]!.indexWhere(
        (post) => post.postId == postId,
      );
      
      if (postIndex >= 0) {
        _postsCache[groupId]![postIndex] = updatedPost;
        
        // Notify posts listeners
        if (_postsControllers.containsKey(groupId)) {
          _postsControllers[groupId]!.add(_postsCache[groupId]!);
        }
      }
    }
    
    return comment;
  }
  
  /// Toggle a like on a post
  Future<DiscussionPost> togglePostLike({
    required String postId,
    required String userId,
  }) async {
    // Find the post
    DiscussionPost? postToUpdate;
    String? groupId;
    int? postIndex;
    
    for (final entry in _postsCache.entries) {
      final index = entry.value.indexWhere(
        (post) => post.postId == postId,
      );
      
      if (index >= 0) {
        postToUpdate = entry.value[index];
        groupId = entry.key;
        postIndex = index;
        break;
      }
    }
    
    if (postToUpdate == null || groupId == null || postIndex == null) {
      throw Exception('Post not found');
    }
    
    // Toggle the like
    List<String> updatedLikes = List.from(postToUpdate.likes);
    if (updatedLikes.contains(userId)) {
      updatedLikes.remove(userId);
    } else {
      updatedLikes.add(userId);
    }
    
    // Create updated post
    final updatedPost = postToUpdate.copyWith(
      likes: updatedLikes,
    );
    
    // In a real implementation, this would update the post in a remote source
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    
    // Update the local cache
    _postsCache[groupId]![postIndex] = updatedPost;
    
    // Notify listeners
    if (_postsControllers.containsKey(groupId)) {
      _postsControllers[groupId]!.add(_postsCache[groupId]!);
    }
    
    return updatedPost;
  }
  
  /// Toggle a like on a comment
  Future<PostComment> toggleCommentLike({
    required String commentId,
    required String userId,
  }) async {
    // Find the comment
    PostComment? commentToUpdate;
    String? postId;
    int? commentIndex;
    
    for (final entry in _commentsCache.entries) {
      final index = entry.value.indexWhere(
        (comment) => comment.commentId == commentId,
      );
      
      if (index >= 0) {
        commentToUpdate = entry.value[index];
        postId = entry.key;
        commentIndex = index;
        break;
      }
    }
    
    if (commentToUpdate == null || postId == null || commentIndex == null) {
      throw Exception('Comment not found');
    }
    
    // Toggle the like
    List<String> updatedLikes = List.from(commentToUpdate.likes);
    if (updatedLikes.contains(userId)) {
      updatedLikes.remove(userId);
    } else {
      updatedLikes.add(userId);
    }
    
    // Create updated comment
    final updatedComment = commentToUpdate.copyWith(
      likes: updatedLikes,
    );
    
    // In a real implementation, this would update the comment in a remote source
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    
    // Update the local cache
    _commentsCache[postId]![commentIndex] = updatedComment;
    
    // Notify listeners
    if (_commentsControllers.containsKey(postId)) {
      _commentsControllers[postId]!.add(_commentsCache[postId]!);
    }
    
    return updatedComment;
  }
  
  /// Pin or unpin a post (moderator action)
  Future<DiscussionPost> togglePinPost({
    required String postId,
    required String userId,
  }) async {
    // Find the post
    DiscussionPost? postToUpdate;
    String? groupId;
    int? postIndex;
    
    for (final entry in _postsCache.entries) {
      final index = entry.value.indexWhere(
        (post) => post.postId == postId,
      );
      
      if (index >= 0) {
        postToUpdate = entry.value[index];
        groupId = entry.key;
        postIndex = index;
        break;
      }
    }
    
    if (postToUpdate == null || groupId == null || postIndex == null) {
      throw Exception('Post not found');
    }
    
    // Check if user is a moderator
    final group = _groupsCache[groupId];
    if (group == null || !group.moderatorIds.contains(userId)) {
      throw Exception('User is not a moderator');
    }
    
    // Toggle the pin status
    final updatedPost = postToUpdate.copyWith(
      isPinned: !postToUpdate.isPinned,
    );
    
    // In a real implementation, this would update the post in a remote source
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    
    // Update the local cache
    _postsCache[groupId]![postIndex] = updatedPost;
    
    // Re-sort the posts
    _postsCache[groupId]!.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.timestamp.compareTo(a.timestamp); // Newest first
    });
    
    // Notify listeners
    if (_postsControllers.containsKey(groupId)) {
      _postsControllers[groupId]!.add(_postsCache[groupId]!);
    }
    
    return updatedPost;
  }
  
  /// Edit a post (author or moderator action)
  Future<DiscussionPost> editPost({
    required String postId,
    required String userId,
    required String title,
    required String content,
  }) async {
    // Find the post
    DiscussionPost? postToUpdate;
    String? groupId;
    int? postIndex;
    
    for (final entry in _postsCache.entries) {
      final index = entry.value.indexWhere(
        (post) => post.postId == postId,
      );
      
      if (index >= 0) {
        postToUpdate = entry.value[index];
        groupId = entry.key;
        postIndex = index;
        break;
      }
    }
    
    if (postToUpdate == null || groupId == null || postIndex == null) {
      throw Exception('Post not found');
    }
    
    // Check if user is the author or a moderator
    final group = _groupsCache[groupId];
    if (postToUpdate.userId != userId && 
        (group == null || !group.moderatorIds.contains(userId))) {
      throw Exception('User does not have permission to edit this post');
    }
    
    // Create updated post
    final updatedPost = postToUpdate.copyWith(
      title: title,
      content: content,
      isEdited: true,
    );
    
    // In a real implementation, this would update the post in a remote source
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    
    // Update the local cache
    _postsCache[groupId]![postIndex] = updatedPost;
    
    // Notify listeners
    if (_postsControllers.containsKey(groupId)) {
      _postsControllers[groupId]!.add(_postsCache[groupId]!);
    }
    
    return updatedPost;
  }
  
  /// Edit a comment (author or moderator action)
  Future<PostComment> editComment({
    required String commentId,
    required String userId,
    required String content,
  }) async {
    // Find the comment
    PostComment? commentToUpdate;
    String? postId;
    int? commentIndex;
    DiscussionPost? parentPost;
    
    for (final entry in _commentsCache.entries) {
      final index = entry.value.indexWhere(
        (comment) => comment.commentId == commentId,
      );
      
      if (index >= 0) {
        commentToUpdate = entry.value[index];
        postId = entry.key;
        commentIndex = index;
        break;
      }
    }
    
    if (commentToUpdate == null || postId == null || commentIndex == null) {
      throw Exception('Comment not found');
    }
    
    // Find the parent post to get the group ID
    for (final entry in _postsCache.entries) {
      final post = entry.value.firstWhere(
        (post) => post.postId == postId,
        orElse: () => DiscussionPost(
          postId: '',
          groupId: '',
          userId: '',
          userDisplayName: '',
          title: '',
          content: '',
          timestamp: DateTime.now(),
        ),
      );
      
      if (post.postId.isNotEmpty) {
        parentPost = post;
        break;
      }
    }
    
    // Check if user is the author or a moderator
    if (commentToUpdate.userId != userId) {
      if (parentPost == null) {
        throw Exception('Parent post not found');
      }
      
      final group = _groupsCache[parentPost.groupId];
      if (group == null || !group.moderatorIds.contains(userId)) {
        throw Exception('User does not have permission to edit this comment');
      }
    }
    
    // Create updated comment
    final updatedComment = commentToUpdate.copyWith(
      content: content,
      isEdited: true,
    );
    
    // In a real implementation, this would update the comment in a remote source
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    
    // Update the local cache
    _commentsCache[postId]![commentIndex] = updatedComment;
    
    // Notify listeners
    if (_commentsControllers.containsKey(postId)) {
      _commentsControllers[postId]!.add(_commentsCache[postId]!);
    }
    
    return updatedComment;
  }
  
  /// Delete a post (author or moderator action)
  Future<void> deletePost({
    required String postId,
    required String userId,
  }) async {
    // Find the post
    DiscussionPost? postToDelete;
    String? groupId;
    int? postIndex;
    
    for (final entry in _postsCache.entries) {
      final index = entry.value.indexWhere(
        (post) => post.postId == postId,
      );
      
      if (index >= 0) {
        postToDelete = entry.value[index];
        groupId = entry.key;
        postIndex = index;
        break;
      }
    }
    
    if (postToDelete == null || groupId == null || postIndex == null) {
      throw Exception('Post not found');
    }
    
    // Check if user is the author or a moderator
    final group = _groupsCache[groupId];
    if (postToDelete.userId != userId && 
        (group == null || !group.moderatorIds.contains(userId))) {
      throw Exception('User does not have permission to delete this post');
    }
    
    // In a real implementation, this would delete the post from a remote source
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    
    // Update the local cache
    _postsCache[groupId]!.removeAt(postIndex);
    
    // Notify listeners
    if (_postsControllers.containsKey(groupId)) {
      _postsControllers[groupId]!.add(_postsCache[groupId]!);
    }
    
    // Also delete all comments for this post
    if (_commentsCache.containsKey(postId)) {
      _commentsCache.remove(postId);
      
      // Close and remove the comments controller
      if (_commentsControllers.containsKey(postId)) {
        _commentsControllers[postId]!.add([]);
      }
    }
  }
  
  /// Delete a comment (author or moderator action)
  Future<void> deleteComment({
    required String commentId,
    required String userId,
  }) async {
    // Find the comment
    PostComment? commentToDelete;
    String? postId;
    int? commentIndex;
    DiscussionPost? parentPost;
    
    for (final entry in _commentsCache.entries) {
      final index = entry.value.indexWhere(
        (comment) => comment.commentId == commentId,
      );
      
      if (index >= 0) {
        commentToDelete = entry.value[index];
        postId = entry.key;
        commentIndex = index;
        break;
      }
    }
    
    if (commentToDelete == null || postId == null || commentIndex == null) {
      throw Exception('Comment not found');
    }
    
    // Find the parent post to get the group ID and update comment count
    for (final entry in _postsCache.entries) {
      final post = entry.value.firstWhere(
        (post) => post.postId == postId,
        orElse: () => DiscussionPost(
          postId: '',
          groupId: '',
          userId: '',
          userDisplayName: '',
          title: '',
          content: '',
          timestamp: DateTime.now(),
        ),
      );
      
      if (post.postId.isNotEmpty) {
        parentPost = post;
        break;
      }
    }
    
    // Check if user is the author or a moderator
    if (commentToDelete.userId != userId && parentPost != null) {
      final group = _groupsCache[parentPost.groupId];
      if (group == null || !group.moderatorIds.contains(userId)) {
        throw Exception('User does not have permission to delete this comment');
      }
    }
    
    // In a real implementation, this would delete the comment from a remote source
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    
    // Update the local cache
    _commentsCache[postId]!.removeAt(commentIndex);
    
    // Notify comments listeners
    if (_commentsControllers.containsKey(postId)) {
      _commentsControllers[postId]!.add(_commentsCache[postId]!);
    }
    
    // Update the post's comment count
    if (parentPost != null) {
      final groupId = parentPost.groupId;
      final postIndex = _postsCache[groupId]!.indexWhere(
        (post) => post.postId == postId,
      );
      
      if (postIndex >= 0) {
        final updatedPost = _postsCache[groupId]![postIndex].copyWith(
          commentCount: _postsCache[groupId]![postIndex].commentCount - 1,
        );
        
        _postsCache[groupId]![postIndex] = updatedPost;
        
        // Notify posts listeners
        if (_postsControllers.containsKey(groupId)) {
          _postsControllers[groupId]!.add(_postsCache[groupId]!);
        }
      }
    }
  }
  
  /// Report a post (user action)
  Future<void> reportPost({
    required String postId,
    required String userId,
    required String reason,
  }) async {
    // In a real implementation, this would send a report to a remote server
    // For now, we'll just simulate a network delay
    await Future.delayed(const Duration(milliseconds: 500));
    print('Post $postId reported by $userId for reason: $reason');
    // In a real app, this would trigger a notification to moderators
  }
  
  /// Report a comment (user action)
  Future<void> reportComment({
    required String commentId,
    required String userId,
    required String reason,
  }) async {
    // In a real implementation, this would send a report to a remote server
    // For now, we'll just simulate a network delay
    await Future.delayed(const Duration(milliseconds: 500));
    print('Comment $commentId reported by $userId for reason: $reason');
    // In a real app, this would trigger a notification to moderators
  }
  
  /// Search for posts within a group
  Future<List<DiscussionPost>> searchPosts({
    required String groupId,
    required String query,
  }) async {
    // In a real implementation, this would search posts on the server
    // For now, we'll just filter the cached posts
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    
    if (!_postsCache.containsKey(groupId)) {
      await fetchPostsForGroup(groupId);
    }
    
    final posts = _postsCache[groupId] ?? [];
    if (query.isEmpty) return posts;
    
    // Simple case-insensitive search
    final lowerQuery = query.toLowerCase();
    return posts.where((post) {
      return post.title.toLowerCase().contains(lowerQuery) ||
             post.content.toLowerCase().contains(lowerQuery);
    }).toList();
  }
  
  /// Dispose of all stream controllers
  void dispose() {
    _groupsController.close();
    
    for (final controller in _postsControllers.values) {
      controller.close();
    }
    
    for (final controller in _commentsControllers.values) {
      controller.close();
    }
  }
  
  // EXAMPLE DATA
  // These methods provide example data for testing
  
  List<SupportGroup> _getExampleGroups() {
    return [
      SupportGroup(
        groupId: 'diabetes_support',
        name: 'Living with Diabetes',
        description: 'A space for individuals managing Type 1, Type 2, or prediabetes to share tips on blood sugar management, diet, exercise, and overcoming daily challenges. Let\'s learn from and support each other!',
        iconUrl: 'assets/images/diabetes_icon.png',
        moderatorIds: ['mod1', 'mod2'],
        guidelines: 'Be respectful and supportive. No medical advice that contradicts professional guidance. No promotion of unproven remedies.',
        isActive: true,
        lastUpdated: DateTime.now(),
      ),
      SupportGroup(
        groupId: 'hypertension_community',
        name: 'Hypertension Management',
        description: 'Connect with others working to lower their blood pressure. Discuss low-sodium recipes, stress-reduction techniques, medication experiences, and staying motivated on your heart-healthy journey.',
        iconUrl: 'assets/images/hypertension_icon.png',
        moderatorIds: ['mod2', 'mod3'],
        guidelines: 'Focus on scientifically-backed approaches. Be kind and considerate in discussions about lifestyle changes.',
        isActive: true,
        lastUpdated: DateTime.now(),
      ),
      SupportGroup(
        groupId: 'kidney_health_forum',
        name: 'Kidney Health & CKD Support',
        description: 'A supportive community for those affected by Chronic Kidney Disease (CKD), dialysis, transplants, and related conditions. Share experiences about diet, treatment options, and emotional well-being.',
        iconUrl: 'assets/images/kidney_icon.png',
        moderatorIds: ['mod1', 'mod3'],
        guidelines: 'Respect privacy and different treatment choices. No promotion of products or treatments without scientific backing.',
        isActive: true,
        lastUpdated: DateTime.now(),
      ),
    ];
  }
  
  List<DiscussionPost> _getExampleDiabetesPosts() {
    return [
      DiscussionPost(
        postId: 'post1',
        groupId: 'diabetes_support',
        userId: 'mod1',
        userDisplayName: 'DiabetesEducator',
        title: 'Welcome to our Diabetes Support Group!',
        content: 'Welcome to our community! This is a safe space to share your experiences living with diabetes. Please introduce yourself and feel free to ask questions or share tips that have worked for you.',
        timestamp: DateTime.now().subtract(const Duration(days: 30)),
        isPinned: true,
        likes: ['user1', 'user2', 'user3'],
        commentCount: 5,
      ),
      DiscussionPost(
        postId: 'post2',
        groupId: 'diabetes_support',
        userId: 'user1',
        userDisplayName: 'GlucoseWarrior',
        title: 'Low-carb meal ideas that actually taste good',
        content: 'I\'ve been struggling to find low-carb meals that I actually enjoy. Recently discovered cauliflower rice stir fry and it\'s amazing! What are your favorite low-carb recipes that don\'t feel like you\'re missing out?',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        likes: ['user2', 'mod1'],
        commentCount: 3,
      ),
      DiscussionPost(
        postId: 'post3',
        groupId: 'diabetes_support',
        userId: 'user2',
        userDisplayName: 'SugarFighter',
        title: 'Exercise and blood glucose levels',
        content: 'I\'ve noticed my glucose readings are much more stable on days when I take a 30-minute walk after dinner. Anyone else notice specific exercise routines that help with glucose control?',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        likes: ['user1'],
        commentCount: 1,
      ),
    ];
  }
  
  List<DiscussionPost> _getExampleHypertensionPosts() {
    return [
      DiscussionPost(
        postId: 'post4',
        groupId: 'hypertension_community',
        userId: 'mod2',
        userDisplayName: 'BPControl',
        title: 'Community Guidelines & Resources',
        content: 'Welcome to our hypertension management community! Here are some helpful resources to get you started on your journey to better blood pressure control. Remember to consult with your healthcare provider before making any significant changes to your regimen.',
        timestamp: DateTime.now().subtract(const Duration(days: 45)),
        isPinned: true,
        likes: ['user3', 'user4'],
        commentCount: 2,
      ),
      DiscussionPost(
        postId: 'post5',
        groupId: 'hypertension_community',
        userId: 'user3',
        userDisplayName: 'HeartHealthy',
        title: 'Sodium hiding in unexpected places',
        content: 'I just realized how much sodium is in my favorite "healthy" soup from the grocery store! 940mg per serving! What hidden sodium sources have surprised you?',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        likes: ['mod2', 'user4', 'user5'],
        commentCount: 4,
      ),
    ];
  }
  
  List<DiscussionPost> _getExampleKidneyPosts() {
    return [
      DiscussionPost(
        postId: 'post6',
        groupId: 'kidney_health_forum',
        userId: 'mod3',
        userDisplayName: 'KidneyAdvocate',
        title: 'Welcome to the Kidney Health Forum',
        content: 'Welcome to our kidney health support community. This is a place for sharing experiences, asking questions, and supporting each other through the challenges of kidney disease. Please be respectful of different treatment choices and perspectives.',
        timestamp: DateTime.now().subtract(const Duration(days: 60)),
        isPinned: true,
        likes: ['user5', 'user6'],
        commentCount: 3,
      ),
      DiscussionPost(
        postId: 'post7',
        groupId: 'kidney_health_forum',
        userId: 'user5',
        userDisplayName: 'RenalWarrior',
        title: 'Dialysis-friendly recipes',
        content: 'I\'ve been collecting kidney-friendly recipes that actually taste good! Here\'s my favorite low-phosphorus pasta dish that my whole family enjoys. Would love to hear your favorite recipes too!',
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        likes: ['mod3', 'user6'],
        commentCount: 2,
      ),
    ];
  }
  
  List<PostComment> _getExampleComments(String postId) {
    switch (postId) {
      case 'post1':
        return [
          PostComment(
            commentId: 'comment1',
            postId: 'post1',
            userId: 'user1',
            userDisplayName: 'GlucoseWarrior',
            content: 'Thanks for creating this group! I was diagnosed with Type 2 last year and still learning to manage it.',
            timestamp: DateTime.now().subtract(const Duration(days: 29)),
            likes: ['mod1'],
          ),
          PostComment(
            commentId: 'comment2',
            postId: 'post1',
            userId: 'user2',
            userDisplayName: 'SugarFighter',
            content: 'Hello everyone! Type 1 for 15 years here. Looking forward to sharing experiences.',
            timestamp: DateTime.now().subtract(const Duration(days: 28)),
          ),
        ];
      case 'post2':
        return [
          PostComment(
            commentId: 'comment3',
            postId: 'post2',
            userId: 'user2',
            userDisplayName: 'SugarFighter',
            content: 'Zucchini noodles with pesto and grilled chicken is my go-to! Feels like a treat but keeps my numbers stable.',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            likes: ['user1'],
          ),
        ];
      default:
        return [];
    }
  }
}