import 'package:flutter/material.dart';
import 'chat_service.dart';
import 'offline_message_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService;
  bool _initialized = false;

  ChatProvider({
    required ChatService chatService,
  }) : _chatService = chatService;

  // Getters
  ChatService get chatService => _chatService;
  bool get isInitialized => _initialized;

  // Initialize the chat service
  Future<void> initialize({OfflineMessageService? offlineService}) async {
    if (_initialized) return;
    
    await _chatService.initialize(offlineService: offlineService);
    _initialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }
}