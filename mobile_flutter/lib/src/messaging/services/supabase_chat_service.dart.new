import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'chat_service.dart';

// This is a minimal mock implementation that extends ChatService
// It provides basic functionality for development without requiring Supabase
class SupabaseChatService extends ChatService {
  SupabaseChatService() : super();

  // Override the initialize method with a simple implementation
  @override
  Future<void> initialize({dynamic offlineService}) async {
    // Just set a mock user ID
    await Future.delayed(const Duration(milliseconds: 300));
    notifyListeners();
  }
  
  // Override searchUsers with mock data
  @override
  Future<List<ChatUser>> searchUsers(String query) async {
    // Return mock users for development
    return [
      ChatUser(
        id: 'user1',
        firstName: 'John',
        lastName: 'Doe',
        avatarUrl: null,
      ),
      ChatUser(
        id: 'user2',
        firstName: 'Jane',
        lastName: 'Smith',
        avatarUrl: null,
      ),
    ];
  }
  
  // Override createDirectChat with mock implementation
  @override
  Future<Chat?> createDirectChat(String otherUserId) async {
    // Create a mock direct chat
    final chat = Chat(
      id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatType.direct,
      name: '',
      participantIds: ['current_user', otherUserId],
      createdAt: DateTime.now(),
    );
    
    // Return the mock chat
    return chat;
  }
  
  // Override createGroupChat with mock implementation
  @override
  Future<Chat?> createGroupChat(String name, List<String> participantIds, {String? description}) async {
    // Create a mock group chat
    final chat = Chat(
      id: 'group_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatType.group,
      name: name,
      participantIds: ['current_user', ...participantIds],
      createdAt: DateTime.now(),
    );
    
    // Return the mock chat
    return chat;
  }
  
  // Make sure to provide the override annotation for dispose
  @override
  void dispose() {
    super.dispose();
  }
}