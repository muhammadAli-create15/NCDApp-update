import 'package:flutter/material.dart';

import '../models/models.dart';
import '../repositories/support_group_repository.dart';
import '../widgets/widgets.dart';
import 'edit_post_screen.dart';

/// Screen for viewing a specific discussion post and its comments
class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String groupId;

  const PostDetailScreen({
    Key? key,
    required this.postId,
    required this.groupId,
  }) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final SupportGroupRepository _repository = SupportGroupRepository();
  bool _isLoading = true;
  bool _isLoadingComments = true;
  DiscussionPost? _post;
  List<PostComment> _comments = [];
  String _errorMessage = '';
  
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  
  // Mock user ID and display name (would come from auth system)
  final String _currentUserId = 'user1';
  final String _currentUserDisplayName = 'CurrentUser';

  @override
  void initState() {
    super.initState();
    _loadPost();
    _loadComments();
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Fetch all posts for the group
      final posts = await _repository.fetchPostsForGroup(widget.groupId);
      
      // Find the specific post
      final post = posts.firstWhere(
        (p) => p.postId == widget.postId,
        orElse: () => throw Exception('Post not found'),
      );

      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load post: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadComments() async {
    try {
      setState(() {
        _isLoadingComments = true;
      });

      final comments = await _repository.fetchCommentsForPost(widget.postId);
      
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingComments = false;
        // We don't set _errorMessage here to keep showing the post
        // even if comments fail to load
      });
    }
  }
  
  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    
    try {
      setState(() {
        _isSubmittingComment = true;
      });
      
      await _repository.createComment(
        postId: widget.postId,
        userId: _currentUserId,
        userDisplayName: _currentUserDisplayName,
        content: content,
      );
      
      _commentController.clear();
      await _loadComments();
      await _loadPost(); // Reload post to update comment count
      
      setState(() {
        _isSubmittingComment = false;
      });
    } catch (e) {
      setState(() {
        _isSubmittingComment = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      });
    }
  }
  
  Future<void> _toggleLike() async {
    if (_post == null) return;
    
    try {
      await _repository.togglePostLike(
        postId: widget.postId,
        userId: _currentUserId,
      );
      
      await _loadPost();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to like post: $e')),
      );
    }
  }
  
  void _showReportDialog() {
    String reason = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please provide a reason for reporting this post:',
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                reason = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reason.trim().isNotEmpty) {
                _repository.reportPost(
                  postId: widget.postId,
                  userId: _currentUserId,
                  reason: reason,
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report submitted. Thank you for keeping our community safe.'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for your report.'),
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion'),
        actions: [
          if (_post != null && _post!.userId == _currentUserId)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navigate to edit post screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPostScreen(post: _post!),
                  ),
                ).then((_) => _loadPost());
              },
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report') {
                _showReportDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'report',
                child: Text('Report Post'),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _loadPost();
                _loadComments();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_post == null) {
      return const Center(
        child: Text('Post not found.'),
      );
    }

    return Column(
      children: [
        // Post content (scrollable)
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadPost();
              await _loadComments();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostContent(),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Comments (${_post!.commentCount})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildCommentsList(),
                ],
              ),
            ),
          ),
        ),
        // Comment input field
        _buildCommentInput(),
      ],
    );
  }

  Widget _buildPostContent() {
    if (_post == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              child: Text(_post!.userDisplayName[0]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _post!.userDisplayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatDate(_post!.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (_post!.isPinned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.push_pin, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Pinned',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _post!.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _post!.content,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              icon: Icon(
                _post!.isLikedBy(_currentUserId) 
                    ? Icons.favorite 
                    : Icons.favorite_border,
                color: _post!.isLikedBy(_currentUserId) 
                    ? Colors.red 
                    : null,
              ),
              onPressed: _toggleLike,
            ),
            Text(
              '${_post!.likes.length} likes',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 16),
            const Icon(Icons.comment),
            const SizedBox(width: 4),
            Text(
              '${_post!.commentCount} comments',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_post!.isEdited) ...[
              const Spacer(),
              Text(
                'Edited',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCommentsList() {
    if (_isLoadingComments) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_comments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No comments yet. Be the first to comment!'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return CommentCard(
          comment: _comments[index],
          currentUserId: _currentUserId,
          onLikeToggled: (commentId) {
            _repository.toggleCommentLike(
              commentId: commentId,
              userId: _currentUserId,
            ).then((_) => _loadComments());
          },
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Write a comment...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          _isSubmittingComment
              ? const CircularProgressIndicator()
              : IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _submitComment,
                ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple date formatting
    return '${date.day}/${date.month}/${date.year}';
  }
}

