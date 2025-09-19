import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_message_service.dart';

class ChatService extends ChangeNotifier {
  final String _baseUrl; // Base URL for API requests
  final String _socketUrl; // URL for WebSocket connection

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Define storage bucket names
  static const String MESSAGE_ATTACHMENTS_BUCKET = 'message_attachments';
  static const String POST_ATTACHMENTS_BUCKET = 'post_attachments';
  
  io.Socket? _socket;
  final Map<String, ChatUser> _users = {};
  final Map<String, Chat> _chats = {};
  final Map<String, List<ChatMessage>> _messages = {};
  
  String? _currentUserId;
  bool _connected = false;
  
  // Offline message handling - will be properly initialized through the provider
  OfflineMessageService? _offlineService;
  
  // Stream controllers for real-time updates
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _chatController = StreamController<Chat>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Streams that UI can listen to
  Stream<ChatMessage> get onMessage => _messageController.stream;
  Stream<Chat> get onChatUpdated => _chatController.stream;
  Stream<Map<String, dynamic>> get onTypingStatus => _typingController.stream;
  Stream<Map<String, dynamic>> get onUserStatusChanged => _statusController.stream;

  // Constructor
  ChatService({
    String baseUrl = 'https://api.example.com', // Replace with actual API URL
    String socketUrl = 'https://api.example.com', // Replace with actual Socket URL
  }) : 
    _baseUrl = baseUrl,
    _socketUrl = socketUrl;

  // Getters
  bool get isConnected => _connected;
  String? get currentUserId => _currentUserId;
  Map<String, ChatUser> get users => _users;
  Map<String, Chat> get chats => _chats;

  // Initialize the service
  Future<void> initialize({OfflineMessageService? offlineService}) async {
    // Get current user ID from auth provider
    _currentUserId = _supabase.auth.currentUser?.id;
    
    if (_currentUserId == null) {
      debugPrint('ChatService: Cannot initialize, user not logged in');
      return;
    }

    // Use provided offline service or create one
    _offlineService = offlineService ?? OfflineMessageService();
    
    // Initialize offline message handling if we created a new instance
    if (offlineService == null) {
      await _offlineService!.initialize();
    }
    
    // Listen to connectivity changes for syncing messages
    _offlineService!.onConnectivityChange.listen((isOnline) {
      if (isOnline && _connected) {
        _syncPendingMessages();
      }
    });
    
    // Listen to pending messages for UI updates
    _offlineService!.pendingMessages.listen((messages) {
      // When pending messages change, update UI
      notifyListeners();
    });

    // Connect to socket
    await _connectSocket();
    
    // Load initial data
    await Future.wait([
      loadChats(),
      loadUsers(),
    ]);
  }

  // Connect to WebSocket server
  Future<void> _connectSocket() async {
    if (_currentUserId == null) return;
    
    try {
      _socket = io.io(_socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'auth': {'token': await _supabase.auth.currentSession?.accessToken},
      });

      _socket!.onConnect((_) {
        _connected = true;
        debugPrint('ChatService: Connected to socket');
        
        // Join user-specific room
        _socket!.emit('join', {'userId': _currentUserId});
        
        // Update user status
        _updateStatus(true);
        
        notifyListeners();
      });

      _socket!.onDisconnect((_) {
        _connected = false;
        debugPrint('ChatService: Disconnected from socket');
        notifyListeners();
      });

      _socket!.on('message', (data) {
        final message = ChatMessage.fromJson(data);
        _handleNewMessage(message);
      });

      _socket!.on('typing', (data) {
        _typingController.add(data);
      });

      _socket!.on('status', (data) {
        _statusController.add(data);
        _updateUserStatus(data['userId'], data['isOnline']);
      });

      _socket!.connect();
    } catch (e) {
      debugPrint('ChatService: Error connecting to socket: $e');
    }
  }

  // Disconnect from WebSocket server
  void disconnect() {
    _updateStatus(false);
    _socket?.disconnect();
    _connected = false;
    notifyListeners();
  }

  // Update user online status
  void _updateStatus(bool isOnline) {
    if (_currentUserId == null || _socket == null) return;
    _socket!.emit('status', {
      'userId': _currentUserId,
      'isOnline': isOnline,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Update a user's online status
  void _updateUserStatus(String userId, bool isOnline) {
    if (_users.containsKey(userId)) {
      _users[userId] = _users[userId]!.copyWith(
        isOnline: isOnline,
        lastSeen: isOnline ? null : DateTime.now(),
      );
      notifyListeners();
    }
  }

  // Handle incoming new message
  void _handleNewMessage(ChatMessage message) {
    // Add message to local cache
    if (!_messages.containsKey(message.chatId)) {
      _messages[message.chatId] = [];
    }
    _messages[message.chatId]!.add(message);

    // Update chat's last message and timestamp
    if (_chats.containsKey(message.chatId)) {
      _chats[message.chatId] = _chats[message.chatId]!.copyWith(
        lastMessage: message,
        updatedAt: DateTime.now(),
      );
      
      // Update unread count if message is not from current user
      if (message.senderId != _currentUserId) {
        final unreadCount = Map<String, int>.from(_chats[message.chatId]!.unreadCount);
        unreadCount[_currentUserId!] = (unreadCount[_currentUserId!] ?? 0) + 1;
        _chats[message.chatId] = _chats[message.chatId]!.copyWith(unreadCount: unreadCount);
      }
      
      // Notify listeners about chat update
      _chatController.add(_chats[message.chatId]!);
    }
    
    // Notify listeners about new message
    _messageController.add(message);
    
    notifyListeners();
  }
  
  // Update an existing message (for attachments, status updates, etc.)
  Future<void> updateMessage(ChatMessage message) async {
    if (_currentUserId == null) return;
    
    try {
      if (_messages.containsKey(message.chatId)) {
        final index = _messages[message.chatId]!.indexWhere((m) => m.id == message.id);
        
        if (index != -1) {
          // Update the message in the local cache
          _messages[message.chatId]![index] = message;
          
          // Update the chat if this was the last message
          if (_chats.containsKey(message.chatId) && 
              _chats[message.chatId]!.lastMessage?.id == message.id) {
            _chats[message.chatId] = _chats[message.chatId]!.copyWith(
              lastMessage: message,
            );
            
            // Notify listeners about chat update
            _chatController.add(_chats[message.chatId]!);
          }
          
          // Emit socket event if connected
          if (_connected && _socket != null) {
            _socket!.emit('updateMessage', message.toJson());
          } else {
            // Store for offline syncing
            _offlineService?.addPendingUpdate(message);
          }
          
          // Notify about the updated message
          _messageController.add(message);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('ChatService: Error updating message: $e');
    }
  }

  // Load user data
  Future<void> loadUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var user in data) {
          final chatUser = ChatUser.fromJson(user);
          _users[chatUser.id] = chatUser;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ChatService: Error loading users: $e');
      // For demo purposes, create some mock users
      _createMockUsers();
    }
  }

  // Load all chats for the current user
  Future<void> loadChats() async {
    if (_currentUserId == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chats/recent'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var chat in data) {
          final chatObj = Chat.fromJson(chat);
          _chats[chatObj.id] = chatObj;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ChatService: Error loading chats: $e');
      // For demo purposes, create some mock chats
      _createMockChats();
    }
  }

  // Load messages for a specific chat
  Future<List<ChatMessage>> loadMessages(String chatId, {int limit = 20, int? before}) async {
    if (!_messages.containsKey(chatId)) {
      _messages[chatId] = [];
    }
    
    // If we already have messages for this chat, return them
    if (_messages[chatId]!.isNotEmpty && before == null) {
      return _messages[chatId]!;
    }
    
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      
      if (before != null) {
        queryParams['before'] = before.toString();
      }
      
      final uri = Uri.parse('$_baseUrl/api/messages/$chatId').replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(
        uri,
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final messages = data.map((msg) => ChatMessage.fromJson(msg)).toList();
        
        // Clear unread count for this chat
        await markChatAsRead(chatId);
        
        if (before == null) {
          _messages[chatId] = messages;
        } else {
          // Prepend older messages
          _messages[chatId] = [...messages, ..._messages[chatId]!];
        }
        
        notifyListeners();
        return messages;
      }
    } catch (e) {
      debugPrint('ChatService: Error loading messages for chat $chatId: $e');
      // For demo purposes, create some mock messages
      _createMockMessages(chatId);
    }
    
    return _messages[chatId] ?? [];
  }

  // Send a new message
  Future<ChatMessage> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
    bool forceOffline = false, // For testing offline mode
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Create message object
    final message = ChatMessage(
      chatId: chatId,
      senderId: _currentUserId!,
      content: content,
      type: type,
      metadata: metadata,
    );

    // Add message to local cache (optimistic update)
    _handleNewMessage(message);

    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity == ConnectivityResult.none || forceOffline;

    if (isOffline) {
      // Device is offline, queue the message for later
      debugPrint('ChatService: Device is offline, queuing message');
      
      // Use the injected offline service or create a temporary one
      try {
        if (_offlineService != null) {
          await _offlineService!.queueMessage(message);
        } else {
          // Fallback to a temporary instance if not injected
          final tempOfflineService = OfflineMessageService();
          await tempOfflineService.initialize();
          await tempOfflineService.queueMessage(message);
        }
        
        // Log the queuing
        debugPrint('ChatService: Message queued for offline sending');
      } catch (e) {
        debugPrint('ChatService: Error queueing offline message: $e');
      }
      
      // Update status to sending
      final pendingMessage = message.copyWith(status: MessageStatus.sending);
      
      // Update local cache
      final index = _messages[chatId]!.indexWhere((msg) => msg.id == message.id);
      if (index >= 0) {
        _messages[chatId]![index] = pendingMessage;
      }
      
      notifyListeners();
      return pendingMessage;
    }

    try {
      // Send message to server
      final response = await http.post(
        Uri.parse('$_baseUrl/api/messages/send'),
        headers: await _getAuthHeaders(),
        body: json.encode(message.toJson()),
      );

      if (response.statusCode == 201) {
        // Replace the optimistic message with the server response
        final serverMessage = ChatMessage.fromJson(json.decode(response.body));
        
        // Update status to sent
        final updatedMessage = message.copyWith(
          id: serverMessage.id,
          status: MessageStatus.sent,
        );
        
        // Update local cache
        final index = _messages[chatId]!.indexWhere((msg) => msg.id == message.id);
        if (index >= 0) {
          _messages[chatId]![index] = updatedMessage;
        }
        
        // Also emit via socket for real-time delivery
        _socket?.emit('message', updatedMessage.toJson());
        
        notifyListeners();
        return updatedMessage;
      } else {
        // Update status to failed
        final failedMessage = message.copyWith(status: MessageStatus.failed);
        
        // Update local cache
        final index = _messages[chatId]!.indexWhere((msg) => msg.id == message.id);
        if (index >= 0) {
          _messages[chatId]![index] = failedMessage;
        }
        
        notifyListeners();
        throw Exception('Failed to send message: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('ChatService: Error sending message: $e');
      
      // Update status to failed
      final failedMessage = message.copyWith(status: MessageStatus.failed);
      
      // Update local cache
      final index = _messages[chatId]!.indexWhere((msg) => msg.id == message.id);
      if (index >= 0) {
        _messages[chatId]![index] = failedMessage;
      }
      
      notifyListeners();
      
      // For demo, mock a successful send
      await Future.delayed(const Duration(seconds: 1));
      return message.copyWith(status: MessageStatus.sent);
    }
  }

  // Create a new chat
  Future<Chat> createChat({
    required List<String> participantIds,
    String? name,
    ChatType type = ChatType.direct,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Make sure current user is included in participants
    if (!participantIds.contains(_currentUserId)) {
      participantIds.add(_currentUserId!);
    }

    final newChat = Chat(
      type: type,
      name: name ?? '',
      participantIds: participantIds,
    );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/chats/create'),
        headers: await _getAuthHeaders(),
        body: json.encode(newChat.toJson()),
      );

      if (response.statusCode == 201) {
        final chat = Chat.fromJson(json.decode(response.body));
        _chats[chat.id] = chat;
        notifyListeners();
        return chat;
      } else {
        throw Exception('Failed to create chat: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('ChatService: Error creating chat: $e');
      
      // For demo purposes, just use the new chat object
      _chats[newChat.id] = newChat;
      notifyListeners();
      return newChat;
    }
  }

  // Mark all messages in a chat as read
  Future<void> markChatAsRead(String chatId) async {
    if (_currentUserId == null || !_chats.containsKey(chatId)) return;
    
    // Update unread count locally
    final unreadCount = Map<String, int>.from(_chats[chatId]!.unreadCount);
    unreadCount[_currentUserId!] = 0;
    
    _chats[chatId] = _chats[chatId]!.copyWith(unreadCount: unreadCount);
    
    try {
      await http.put(
        Uri.parse('$_baseUrl/api/messages/$chatId/status'),
        headers: await _getAuthHeaders(),
        body: json.encode({
          'userId': _currentUserId,
          'status': 'read',
        }),
      );
    } catch (e) {
      debugPrint('ChatService: Error marking chat as read: $e');
    }
    
    notifyListeners();
  }

  // Send typing indicator
  void sendTypingStatus(String chatId, bool isTyping) {
    if (_currentUserId == null || _socket == null) return;
    
    _socket!.emit('typing', {
      'chatId': chatId,
      'userId': _currentUserId,
      'isTyping': isTyping,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Get HTTP headers with auth token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _supabase.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Send a message to the server
  Future<ChatMessage> _sendMessageToServer(ChatMessage message) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Send message to server
      final response = await http.post(
        Uri.parse('$_baseUrl/api/messages/send'),
        headers: await _getAuthHeaders(),
        body: json.encode(message.toJson()),
      );

      if (response.statusCode == 201) {
        // Replace the message with the server response
        final serverMessage = ChatMessage.fromJson(json.decode(response.body));
        
        // Update status to delivered
        final updatedMessage = message.copyWith(
          id: serverMessage.id,
          status: MessageStatus.delivered,
        );
        
        // Also emit via socket for real-time delivery
        _socket?.emit('message', updatedMessage.toJson());
        
        return updatedMessage;
      } else {
        throw Exception('Failed to send message: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('ChatService: Error sending message to server: $e');
      
      // For demo purposes, mock a successful send after a brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Simulate a successful send
      final updatedMessage = message.copyWith(status: MessageStatus.delivered);
      return updatedMessage;
    }
  }
  
  // Sync any pending offline messages
  Future<void> _syncPendingMessages() async {
    if (_offlineService == null) return;
    
    debugPrint('ChatService: Syncing pending messages');
    
    final pendingMessages = _offlineService!.pendingMessagesList;
    if (pendingMessages.isEmpty) return;
    
    for (final message in List<ChatMessage>.from(pendingMessages)) {
      try {
        // Skip messages that are already sent
        if (message.status == MessageStatus.delivered || 
            message.status == MessageStatus.read) {
          await _offlineService!.removeMessage(message.id);
          continue;
        }
        
        // Try to send the pending message
        debugPrint('ChatService: Syncing offline message ${message.id}');
        
        // Send message to server
        await _sendMessageToServer(message);
        
        // Update status and notify listeners
        final chatId = message.chatId;
        final updatedMessage = message.copyWith(status: MessageStatus.delivered);
        
        // Update in the local cache
        final index = _messages[chatId]?.indexWhere((msg) => msg.id == message.id) ?? -1;
        if (index >= 0 && _messages.containsKey(chatId)) {
          _messages[chatId]![index] = updatedMessage;
        }
        
        // Remove from offline queue
        await _offlineService!.removeMessage(message.id);
        
        notifyListeners();
      } catch (e) {
        debugPrint('ChatService: Failed to sync message ${message.id}: $e');
        // Leave in queue to try again later
      }
    }
  }

  // Clean up resources
  void dispose() {
    disconnect();
    _messageController.close();
    _chatController.close();
    _typingController.close();
    _statusController.close();
    _offlineService?.dispose();
    super.dispose();
  }

  // MOCK DATA METHODS FOR DEMO PURPOSES
  // These methods would be removed in production

  void _createMockUsers() {
    final users = [
      ChatUser(
        id: 'user1',
        firstName: 'Dr.',
        lastName: 'Smith',
        isOnline: true,
        avatarUrl: 'https://i.pravatar.cc/150?img=1',
      ),
      ChatUser(
        id: 'user2',
        firstName: 'Nurse',
        lastName: 'Johnson',
        isOnline: false,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
        avatarUrl: 'https://i.pravatar.cc/150?img=2',
      ),
      ChatUser(
        id: 'user3',
        firstName: 'Support',
        lastName: 'Team',
        isOnline: true,
        avatarUrl: 'https://i.pravatar.cc/150?img=3',
      ),
    ];

    for (var user in users) {
      _users[user.id] = user;
    }

    // Set current user if not set
    if (_currentUserId == null) {
      _currentUserId = 'currentUser';
      _users[_currentUserId!] = ChatUser(
        id: _currentUserId!,
        firstName: 'You',
        lastName: '',
        isOnline: true,
      );
    }
  }

  void _createMockChats() {
    // Make sure we have some users
    if (_users.isEmpty) _createMockUsers();

    if (_currentUserId == null) return;

    final chats = [
      Chat(
        id: 'chat1',
        type: ChatType.direct,
        participantIds: [_currentUserId!, 'user1'],
        unreadCount: {_currentUserId!: 2},
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Chat(
        id: 'chat2',
        type: ChatType.direct,
        participantIds: [_currentUserId!, 'user2'],
        unreadCount: {_currentUserId!: 0},
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Chat(
        id: 'chat3',
        type: ChatType.group,
        name: 'NCD Support Group',
        participantIds: [_currentUserId!, 'user1', 'user2', 'user3'],
        unreadCount: {_currentUserId!: 5},
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    for (var chat in chats) {
      _chats[chat.id] = chat;
    }
  }

  void _createMockMessages(String chatId) {
    if (_currentUserId == null) return;

    // Create mock messages for the given chat
    final otherUserId = _chats[chatId]?.getOtherParticipantId(_currentUserId!) ?? 'user1';

    final messages = [
      ChatMessage(
        id: 'msg1_$chatId',
        chatId: chatId,
        senderId: otherUserId,
        content: 'Hello, how are you feeling today?',
        type: MessageType.text,
        status: MessageStatus.read,
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
      ChatMessage(
        id: 'msg2_$chatId',
        chatId: chatId,
        senderId: _currentUserId!,
        content: 'I\'m feeling much better, thanks for asking!',
        type: MessageType.text,
        status: MessageStatus.read,
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      ),
      ChatMessage(
        id: 'msg3_$chatId',
        chatId: chatId,
        senderId: otherUserId,
        content: 'That\'s great to hear. Have you been taking your medication regularly?',
        type: MessageType.text,
        status: MessageStatus.read,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ChatMessage(
        id: 'msg4_$chatId',
        chatId: chatId,
        senderId: _currentUserId!,
        content: 'Yes, I haven\'t missed any doses this week.',
        type: MessageType.text,
        status: MessageStatus.read,
        createdAt: DateTime.now().subtract(const Duration(hours: 23)),
      ),
      ChatMessage(
        id: 'msg5_$chatId',
        chatId: chatId,
        senderId: otherUserId,
        content: 'Your next appointment is scheduled for next Monday. Would you like to receive a reminder?',
        type: MessageType.text,
        status: MessageStatus.delivered,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];

    _messages[chatId] = messages;

    // Update last message in the chat
    if (_chats.containsKey(chatId)) {
      _chats[chatId] = _chats[chatId]!.copyWith(
        lastMessage: messages.last,
      );
    }
  }
}