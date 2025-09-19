import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as chat_ui;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../services/services.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class MessagingScreen extends StatefulWidget {
  final String chatId;

  const MessagingScreen({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isTyping = false;
  bool _isLoading = true;
  bool _isSending = false;
  List<ChatMessage> _messages = [];
  Map<String, bool> _typingUsers = {};
  
  // Attachment handler
  late final AttachmentHandler _attachmentHandler;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    
    // Initialize attachment handler
    _attachmentHandler = AttachmentHandler(context, widget.chatId);
    
    // Initialize offline provider
    final offlineProvider = Provider.of<OfflineMessageProvider>(context, listen: false);
    offlineProvider.initialize();
    
    // We don't need to add a listener here since the provider will rebuild
    // the widget when the connectivity status changes
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final chatService = chatProvider.chatService;

    // Mark the chat as read when opening
    await chatService.markChatAsRead(widget.chatId);

    // Load messages
    final messages = await chatService.loadMessages(widget.chatId);
    
    if (mounted) {
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    }

    // Listen for new messages
    chatService.onMessage.listen((message) {
      if (message.chatId == widget.chatId) {
        setState(() {
          // Check if message already exists to avoid duplicates
          if (!_messages.any((m) => m.id == message.id)) {
            _messages = [..._messages, message];
          }
        });
        
        // Mark as read if it's not from current user
        if (message.senderId != chatService.currentUserId) {
          chatService.markChatAsRead(widget.chatId);
        }
      }
    });

    // Listen for typing status
    chatService.onTypingStatus.listen((data) {
      if (data['chatId'] == widget.chatId && 
          data['userId'] != chatService.currentUserId) {
        setState(() {
          _typingUsers[data['userId']] = data['isTyping'];
        });
      }
    });
  }

  void _handleTyping(String text) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final chatService = chatProvider.chatService;
    
    final isTypingNow = text.isNotEmpty;
    if (_isTyping != isTypingNow) {
      _isTyping = isTypingNow;
      chatService.sendTypingStatus(widget.chatId, isTypingNow);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final chatService = chatProvider.chatService;

    try {
      await chatService.sendMessage(
        chatId: widget.chatId,
        content: text,
        type: MessageType.text,
      );
      
      _messageController.clear();
      _handleTyping('');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
  
  // Handle attachment button press
  void _handleAttachmentPress() {
    _attachmentHandler.showAttachmentOptions();
  }

  // The _pickImage method has been moved to the AttachmentHandler class

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final chatService = chatProvider.chatService;
        final currentUserId = chatService.currentUserId;
        final chat = chatService.chats[widget.chatId];
        
        if (currentUserId == null) {
          return const Scaffold(
            body: Center(child: Text('Please log in to view messages')),
          );
        }

        if (chat == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat')),
            body: const Center(child: Text('Chat not found')),
          );
        }

        // Get chat name and avatar
        final users = chatService.users;
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

        // Check if anyone is typing
        final typingUserIds = _typingUsers.entries
            .where((entry) => entry.value && entry.key != currentUserId)
            .map((entry) => entry.key)
            .toList();
        
        String typingText = '';
        if (typingUserIds.isNotEmpty) {
          if (typingUserIds.length == 1) {
            final typingUser = users[typingUserIds.first];
            typingText = '${typingUser?.firstName ?? 'Someone'} is typing...';
          } else {
            typingText = 'Several people are typing...';
          }
        }

        // Convert app messages to Flutter Chat UI format
        final chatUIMessages = _messages.map((msg) {
          final author = types.User(id: msg.senderId);
          
          switch (msg.type) {
            case MessageType.text:
              return types.TextMessage(
                id: msg.id,
                author: author,
                text: msg.content,
                createdAt: msg.createdAt.millisecondsSinceEpoch,
              );
              
            case MessageType.image:
              return types.ImageMessage(
                id: msg.id,
                author: author,
                uri: msg.content,
                name: msg.metadata?['name'] ?? 'Image',
                size: msg.metadata?['size'] ?? 0,
                width: msg.metadata?['width'] ?? 300,
                height: msg.metadata?['height'] ?? 200,
                createdAt: msg.createdAt.millisecondsSinceEpoch,
              );
              
            case MessageType.video:
              // Custom handling for video messages
              return types.CustomMessage(
                id: msg.id,
                author: author,
                metadata: {
                  'uri': msg.content,
                  ...?msg.metadata,
                  'type': 'video',
                },
                createdAt: msg.createdAt.millisecondsSinceEpoch,
              );
              
            case MessageType.file:
              return types.FileMessage(
                id: msg.id,
                author: author,
                uri: msg.content,
                name: msg.metadata?['name'] ?? 'File',
                size: msg.metadata?['size'] ?? 0,
                createdAt: msg.createdAt.millisecondsSinceEpoch,
              );
              
            case MessageType.audio:
              // Custom handling for audio messages
              return types.CustomMessage(
                id: msg.id,
                author: author,
                metadata: {
                  'uri': msg.content,
                  ...?msg.metadata,
                  'type': 'audio',
                },
                createdAt: msg.createdAt.millisecondsSinceEpoch,
              );
              
            default:
              return types.TextMessage(
                id: msg.id,
                author: author,
                text: msg.content,
                createdAt: msg.createdAt.millisecondsSinceEpoch,
              );
          }
        }).toList();

        // Check offline status using OfflineMessageProvider
        final offlineProvider = Provider.of<OfflineMessageProvider>(context);
        final isOffline = !offlineProvider.isOnline;
        
        // Get pending messages for this chat
        final pendingMessageCount = offlineProvider.getPendingMessageCount(widget.chatId);
        
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: avatarUrl != null
                          ? CachedNetworkImageProvider(avatarUrl) as ImageProvider
                          : null,
                      child: avatarUrl == null
                          ? Text(
                              chatName.isNotEmpty ? chatName[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                    ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chatName,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (chat.type == ChatType.direct)
                      Row(
                        children: [
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOnline ? Colors.green : Colors.grey,
                            ),
                          ),
                          
                          // Show offline status indicator
                          if (isOffline)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.cloud_off,
                                    size: 12,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'You are offline',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  
                                  // Show pending messages count if any
                                  if (pendingMessageCount > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4.0),
                                      child: Text(
                                        '($pendingMessageCount queued)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.phone),
                onPressed: () {
                  // Implement call feature if needed
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Call feature not implemented yet')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Show chat options menu
                  // Like delete chat, block user, etc.
                },
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: _messages.isEmpty
                          ? const Center(child: Text('No messages yet'))
                          : chat_ui.Chat(
                              messages: chatUIMessages,
                              onSendPressed: (partialText) {
                                // Not used since we have our own input widget
                              },
                              user: types.User(id: currentUserId),
                              theme: chat_ui.DefaultChatTheme(
                                // Customize the UI theme here
                                backgroundColor: Colors.white,
                                primaryColor: Theme.of(context).primaryColor,
                                secondaryColor: Colors.grey[200]!,
                                inputBackgroundColor: Colors.grey[200]!,
                                userAvatarImageBackgroundColor: Colors.grey[200]!,
                                userAvatarNameColors: [Theme.of(context).primaryColor],
                              ),
                              showUserAvatars: true,
                              showUserNames: chat.type == ChatType.group,
                              emptyState: const Center(
                                child: Text('No messages yet. Start a conversation!'),
                              ),
                            ),
                    ),
                    if (typingText.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Text(
                          typingText,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _handleAttachmentPress,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                hintText: 'Type a message',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.send,
                              onChanged: _handleTyping,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.send,
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: _messageController.text.trim().isEmpty || _isSending
                                ? null
                                : _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// These classes have been replaced by the AttachmentHandler functionality