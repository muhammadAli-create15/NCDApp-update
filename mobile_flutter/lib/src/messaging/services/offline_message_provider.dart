import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'offline_message_service.dart';

class OfflineMessageProvider extends ChangeNotifier {
  final OfflineMessageService _offlineMessageService = OfflineMessageService();
  
  bool _initialized = false;
  bool _isOnline = true;
  
  // Getters
  OfflineMessageService get offlineMessageService => _offlineMessageService;
  bool get isInitialized => _initialized;
  bool get isOnline => _isOnline;
  List<ChatMessage> get pendingMessages => _offlineMessageService.pendingMessagesList;
  
  // Initialize the offline message service
  Future<void> initialize() async {
    if (_initialized) return;
    
    await _offlineMessageService.initialize();
    _initialized = true;
    
    // Listen to connectivity changes
    _offlineMessageService.onConnectivityChange.listen((online) {
      _isOnline = online;
      notifyListeners();
    });
    
    // Listen to pending messages changes
    _offlineMessageService.pendingMessages.listen((_) {
      notifyListeners();
    });
    
    notifyListeners();
  }
  
  // Queue a message to be sent when back online
  Future<void> queueMessage(ChatMessage message) async {
    await _offlineMessageService.queueMessage(message);
    notifyListeners();
  }
  
  // Remove a message from the queue (after it's been successfully sent)
  Future<void> removeMessage(String messageId) async {
    await _offlineMessageService.removeMessage(messageId);
    notifyListeners();
  }
  
  // Get the number of pending messages for a specific chat
  int getPendingMessageCount(String chatId) {
    return _offlineMessageService.getPendingMessageCount(chatId);
  }
  
  // Get all pending messages for a specific chat
  List<ChatMessage> getPendingMessagesForChat(String chatId) {
    return _offlineMessageService.getPendingMessagesForChat(chatId);
  }
  
  @override
  void dispose() {
    _offlineMessageService.dispose();
    super.dispose();
  }
}