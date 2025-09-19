import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import '../utils/attachment_handler.dart';

class CustomMessagingScreen extends StatefulWidget {
  final String chatId;

  const CustomMessagingScreen({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  State<CustomMessagingScreen> createState() => _CustomMessagingScreenState();
}

class _CustomMessagingScreenState extends State<CustomMessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isTyping = false;
  bool _isLoading = true;
  bool _isSending = false;
  List<ChatMessage> _messages = [];
  late AttachmentHandler _attachmentHandler;
  
  @override
  void initState() {
    super.initState();
    _attachmentHandler = AttachmentHandler(context, widget.chatId);
    _loadMessages();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final chatService = chatProvider.chatService;
    
    try {
      final messages = await chatService.loadMessages(widget.chatId);
      
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
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
      final message = await chatService.sendMessage(
        chatId: widget.chatId,
        content: text,
        type: MessageType.text,
      );
      
      setState(() {
        _messages.insert(0, message);
      });
      
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
  
  void _handleAttachmentPress() {
    _attachmentHandler.showAttachmentOptions();
  }
  
  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
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
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      chatName.isNotEmpty ? chatName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 14),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chatName, style: const TextStyle(fontSize: 16)),
                if (isOnline)
                  const Text(
                    'Online',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call feature not implemented')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
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
                      : ListView.builder(
                          reverse: true,
                          itemCount: _messages.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isCurrentUser = message.senderId == currentUserId;
                            
                            return MessageBubble(
                              message: message,
                              isCurrentUser: isCurrentUser,
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file),
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
                              vertical: 10,
                              horizontal: 16,
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
                        icon: const Icon(Icons.send),
                        color: Theme.of(context).primaryColor,
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
  }
}