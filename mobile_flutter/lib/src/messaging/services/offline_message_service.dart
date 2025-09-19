import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/models.dart';

class OfflineMessageService {
  static const String _pendingMessagesKey = 'pending_messages';
  
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  
  final _pendingMessages = <ChatMessage>[];
  final _onlineStatusController = StreamController<bool>.broadcast();
  final _pendingMessagesController = StreamController<List<ChatMessage>>.broadcast();
  
  // Streams for UI to listen to
  Stream<bool> get onConnectivityChange => _onlineStatusController.stream;
  Stream<List<ChatMessage>> get pendingMessages => _pendingMessagesController.stream;
  
  // Getters
  bool get isOnline => _isOnline;
  List<ChatMessage> get pendingMessagesList => List.unmodifiable(_pendingMessages);
  
  // Initialize the service
  Future<void> initialize() async {
    // Load pending messages from storage
    await _loadPendingMessages();
    
    // Start listening to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _isOnline = result != ConnectivityResult.none;
      _onlineStatusController.add(_isOnline);
      
      // If we're back online and have pending messages, try to send them
      if (_isOnline && _pendingMessages.isNotEmpty) {
        debugPrint('OfflineMessageService: Back online with ${_pendingMessages.length} pending messages');
        syncPendingMessages();
      }
    });
    
    // Check current connectivity
    final ConnectivityResult result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    _onlineStatusController.add(_isOnline);
  }
  
  // Queue a message to be sent when back online
  Future<void> queueMessage(ChatMessage message) async {
    _pendingMessages.add(message);
    await _savePendingMessages();
    _pendingMessagesController.add(_pendingMessages);
  }
  
  // Add a message update to be processed when back online
  Future<void> addPendingUpdate(ChatMessage message) async {
    // Find and replace existing message if it exists
    final index = _pendingMessages.indexWhere((msg) => msg.id == message.id);
    if (index != -1) {
      _pendingMessages[index] = message;
    } else {
      _pendingMessages.add(message);
    }
    await _savePendingMessages();
    _pendingMessagesController.add(_pendingMessages);
  }
  
  // Remove a message from the queue (after it's been successfully sent)
  Future<void> removeMessage(String messageId) async {
    _pendingMessages.removeWhere((msg) => msg.id == messageId);
    await _savePendingMessages();
    _pendingMessagesController.add(_pendingMessages);
  }
  
  // Get the number of pending messages for a specific chat
  int getPendingMessageCount(String chatId) {
    return _pendingMessages.where((msg) => msg.chatId == chatId).length;
  }
  
  // Get all pending messages for a specific chat
  List<ChatMessage> getPendingMessagesForChat(String chatId) {
    return _pendingMessages.where((msg) => msg.chatId == chatId).toList();
  }
  
  // Save pending messages to shared preferences
  Future<void> _savePendingMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = _pendingMessages.map((msg) => jsonEncode(msg.toJson())).toList();
      await prefs.setStringList(_pendingMessagesKey, messagesJson);
    } catch (e) {
      debugPrint('OfflineMessageService: Error saving pending messages: $e');
    }
  }
  
  // Load pending messages from shared preferences
  Future<void> _loadPendingMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getStringList(_pendingMessagesKey) ?? [];
      
      _pendingMessages.clear();
      for (final json in messagesJson) {
        try {
          final message = ChatMessage.fromJson(jsonDecode(json));
          _pendingMessages.add(message);
        } catch (e) {
          debugPrint('OfflineMessageService: Error parsing message: $e');
        }
      }
      
      _pendingMessagesController.add(_pendingMessages);
    } catch (e) {
      debugPrint('OfflineMessageService: Error loading pending messages: $e');
    }
  }
  
  // Sync pending messages when back online
  Future<void> syncPendingMessages() async {
    if (_pendingMessages.isEmpty) return;
    
    debugPrint('OfflineMessageService: Syncing ${_pendingMessages.length} pending messages');
    
    // Create a copy of the pending messages to avoid modification during iteration
    final messagesToSync = List<ChatMessage>.from(_pendingMessages);
    
    // In a real app, we would inject the ChatService through dependency injection
    // For this example, we'll assume there's a sendPendingMessage method that we can call
    // This is a placeholder - in a real app you would need to get the ChatService instance
    for (final message in messagesToSync) {
      try {
        // Attempt to send the message
        // In a real implementation, you would use the actual ChatService here
        // Something like: await chatService.sendMessage(message.chatId, message.content, type: message.type);
        
        debugPrint('OfflineMessageService: Syncing message ${message.id}');
        
        // If successful, remove from pending queue
        await removeMessage(message.id);
      } catch (e) {
        debugPrint('OfflineMessageService: Failed to sync message ${message.id}: $e');
        // Leave in queue to try again later
      }
    }
  }
  
  // Cleanup resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _onlineStatusController.close();
    _pendingMessagesController.close();
  }
}