import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/services.dart';
import '../models/models.dart';
import 'messaging_screen.dart';
import 'custom_messaging_screen.dart';

class ChatSelectionScreen extends StatefulWidget {
  const ChatSelectionScreen({super.key});

  @override
  State<ChatSelectionScreen> createState() => _ChatSelectionScreenState();
}

class _ChatSelectionScreenState extends State<ChatSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initChatService();
  }

  Future<void> _initChatService() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    if (!chatProvider.isInitialized) {
      await chatProvider.initialize();
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _navigateToChat(BuildContext context, Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomMessagingScreen(chatId: chat.id),
      ),
    );
  }

  void _createNewChat() {
    // Show dialog to select users
    showDialog(
      context: context,
      builder: (context) => _NewChatDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewChat,
            tooltip: 'New chat',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final chatService = chatProvider.chatService;
                final currentUserId = chatService.currentUserId;
                
                if (currentUserId == null) {
                  return const Center(
                    child: Text('Please log in to view your messages'),
                  );
                }
                
                // Get sorted chats by last message timestamp
                final chats = chatService.chats.values.toList()
                  ..sort((a, b) {
                    final aTime = a.updatedAt ?? a.createdAt;
                    final bTime = b.updatedAt ?? b.createdAt;
                    return bTime.compareTo(aTime); // Most recent first
                  });
                
                // Filter chats based on search query
                final filteredChats = _searchQuery.isEmpty
                    ? chats
                    : chats.where((chat) {
                        final chatName = chat.getChatName(
                          chatService.users, 
                          currentUserId,
                        ).toLowerCase();
                        
                        return chatName.contains(_searchQuery);
                      }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search conversations',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    Expanded(
                      child: filteredChats.isEmpty
                          ? Center(
                              child: Text(
                                _searchQuery.isEmpty
                                    ? 'No conversations yet'
                                    : 'No conversations matching "$_searchQuery"',
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredChats.length,
                              itemBuilder: (context, index) {
                                final chat = filteredChats[index];
                                return _ChatListItem(
                                  chat: chat,
                                  currentUserId: currentUserId,
                                  onTap: () => _navigateToChat(context, chat),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final Chat chat;
  final String currentUserId;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatProvider>(context).chatService;
    final users = chatService.users;
    
    // Get chat name and avatar
    String chatName = chat.getChatName(users, currentUserId);
    String? avatarUrl;
    bool isOnline = false;
    
    if (chat.type == ChatType.direct) {
      try {
        final otherUserId = chat.getOtherParticipantId(currentUserId);
        final otherUser = users[otherUserId];
        if (otherUser != null) {
          avatarUrl = otherUser.avatarUrl;
          isOnline = otherUser.isOnline;
        }
      } catch (e) {
        // Handle invalid chat or missing user
      }
    }
    
    // Format timestamp
    final timestamp = chat.updatedAt ?? chat.createdAt;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    String formattedTime;
    if (messageDate == today) {
      // Today, show time only
      formattedTime = DateFormat('h:mm a').format(timestamp);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      formattedTime = 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      // Within last week, show day name
      formattedTime = DateFormat('EEEE').format(timestamp);
    } else {
      // Older, show date
      formattedTime = DateFormat('M/d/yy').format(timestamp);
    }
    
    // Get unread count
    final unreadCount = chat.getUnreadCountForUser(currentUserId);
    
    // Get last message preview
    String messagePreview = '';
    if (chat.lastMessage != null) {
      if (chat.lastMessage!.senderId == currentUserId) {
        messagePreview = 'You: ${chat.lastMessage!.content}';
      } else {
        messagePreview = chat.lastMessage!.content;
      }
      
      // Truncate if too long
      if (messagePreview.length > 40) {
        messagePreview = '${messagePreview.substring(0, 37)}...';
      }
    }

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[300],
            backgroundImage: avatarUrl != null
                ? CachedNetworkImageProvider(avatarUrl) as ImageProvider
                : null,
            child: avatarUrl == null
                ? Text(
                    chatName.isNotEmpty ? chatName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 18),
                  )
                : null,
          ),
          if (isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        chatName,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: messagePreview.isNotEmpty
          ? Text(
              messagePreview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
              ),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 12,
              color: unreadCount > 0 ? Theme.of(context).primaryColor : Colors.grey,
            ),
          ),
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _NewChatDialog extends StatefulWidget {
  @override
  State<_NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<_NewChatDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _selectedUsers = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUsers.contains(userId)) {
        _selectedUsers.remove(userId);
      } else {
        _selectedUsers.add(userId);
      }
    });
  }

  Future<void> _createChat() async {
    if (_selectedUsers.isEmpty) {
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final chatService = chatProvider.chatService;

    try {
      final isGroupChat = _selectedUsers.length > 1;
      final chat = await chatService.createChat(
        participantIds: _selectedUsers,
        type: isGroupChat ? ChatType.group : ChatType.direct,
      );

      if (mounted) {
        Navigator.pop(context); // Close dialog
        
        // Navigate to new chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagingScreen(chatId: chat.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Conversation'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search for users',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 8),
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final chatService = chatProvider.chatService;
                final currentUserId = chatService.currentUserId;
                final users = chatService.users.values
                    .where((user) => user.id != currentUserId)
                    .toList();

                // Filter users by search query
                final filteredUsers = _searchQuery.isEmpty
                    ? users
                    : users.where((user) {
                        final fullName = user.fullName.toLowerCase();
                        return fullName.contains(_searchQuery);
                      }).toList();

                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isSelected = _selectedUsers.contains(user.id);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.avatarUrl != null
                              ? CachedNetworkImageProvider(user.avatarUrl!) as ImageProvider
                              : null,
                          child: user.avatarUrl == null
                              ? Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?')
                              : null,
                        ),
                        title: Text(user.fullName),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                            : const Icon(Icons.circle_outlined),
                        onTap: () => _toggleUserSelection(user.id),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Create'),
          onPressed: _selectedUsers.isEmpty ? null : _createChat,
        ),
      ],
    );
  }
}