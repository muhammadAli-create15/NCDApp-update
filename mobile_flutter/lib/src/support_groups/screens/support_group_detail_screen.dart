import 'package:flutter/material.dart';

import '../models/models.dart';
import '../repositories/support_group_repository.dart';
import '../widgets/discussion_post_card.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';

/// Screen for viewing a specific support group's discussion
class SupportGroupDetailScreen extends StatefulWidget {
  final String groupId;
  
  const SupportGroupDetailScreen({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  State<SupportGroupDetailScreen> createState() => _SupportGroupDetailScreenState();
}

class _SupportGroupDetailScreenState extends State<SupportGroupDetailScreen> {
  final SupportGroupRepository _repository = SupportGroupRepository();
  bool _isLoading = true;
  SupportGroup? _group;
  List<DiscussionPost> _posts = [];
  String _errorMessage = '';
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _loadGroup();
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadGroup() async {
    try {
      // First load all groups
      final groups = await _repository.fetchGroups();
      
      // Find the specific group
      final group = groups.firstWhere(
        (g) => g.groupId == widget.groupId,
        orElse: () => throw Exception('Group not found'),
      );
      
      setState(() {
        _group = group;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load group: $e';
      });
    }
  }

  Future<void> _loadPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final posts = await _repository.fetchPostsForGroup(widget.groupId);
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load posts: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _searchPosts() async {
    if (_searchController.text.isEmpty) {
      await _loadPosts();
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final posts = await _repository.searchPosts(
        groupId: widget.groupId,
        query: _searchController.text,
      );
      
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Search failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create post screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreatePostScreen(groupId: widget.groupId),
            ),
          ).then((_) => _loadPosts()); // Reload posts when returning
        },
        tooltip: 'New Post',
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search posts...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          onSubmitted: (_) => _searchPosts(),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
              _loadPosts();
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchPosts,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
            },
          ),
        ],
      );
    }

    return AppBar(
      title: Text(_group?.name ?? 'Group Discussion'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            if (_group != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SupportGroupGuidelinesScreen(
                    group: _group!,
                  ),
                ),
              );
            }
          },
          tooltip: 'Guidelines',
        ),
      ],
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
              onPressed: _loadPosts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No posts available.'),
            const SizedBox(height: 16),
            if (!_isSearching) ...[
              const Text('Be the first to start a discussion!'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatePostScreen(groupId: widget.groupId),
                    ),
                  ).then((_) => _loadPosts());
                },
                child: const Text('Create Post'),
              ),
            ] else ...[
              const Text('No posts match your search.'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _loadPosts();
                  });
                },
                child: const Text('Clear Search'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          // We'll implement a dedicated widget for post display
          return DiscussionPostCard(
            post: post,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(
                    postId: post.postId,
                    groupId: widget.groupId,
                  ),
                ),
              ).then((_) => _loadPosts());
            },
          );
        },
      ),
    );
  }
}

/// Screen for viewing community guidelines
class SupportGroupGuidelinesScreen extends StatelessWidget {
  final SupportGroup group;
  
  const SupportGroupGuidelinesScreen({
    Key? key,
    required this.group,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Guidelines'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              group.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(
              'Community Guidelines',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              group.guidelines,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'About this community',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Last Updated'),
              subtitle: Text(_formatDate(group.lastUpdated)),
            ),
            ListTile(
              leading: const Icon(Icons.supervisor_account),
              title: const Text('Moderation'),
              subtitle: const Text('This group is actively moderated to ensure a supportive environment.'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Remember that support groups are not a substitute for professional medical advice. Always consult with healthcare providers for medical decisions.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    // Simple date formatting
    return '${date.day}/${date.month}/${date.year}';
  }
}

