import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'chat_message.dart';
import 'chat_user.dart';

enum ChatType {
  direct,  // One-on-one chat
  group,   // Group chat
}

class Chat {
  final String id;
  final ChatType type;
  final String name;  // Used for group chats or can be null for direct chats
  final List<String> participantIds;
  final ChatMessage? lastMessage;
  final Map<String, int> unreadCount;  // Map of userId to unread count
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;  // For additional info

  Chat({
    String? id,
    required this.type,
    this.name = '',
    required this.participantIds,
    this.lastMessage,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
    this.updatedAt,
    this.metadata,
  }) : 
    id = id ?? const Uuid().v4(),
    unreadCount = unreadCount ?? {},
    createdAt = createdAt ?? DateTime.now();

  // For direct chats, get the ID of the other participant (not the current user)
  String getOtherParticipantId(String currentUserId) {
    if (type != ChatType.direct || participantIds.length != 2) {
      throw Exception('Not a direct chat or invalid number of participants');
    }
    return participantIds.firstWhere((id) => id != currentUserId);
  }

  // Get chat name based on type
  String getChatName(Map<String, ChatUser> users, String currentUserId) {
    if (type == ChatType.direct) {
      final otherId = getOtherParticipantId(currentUserId);
      final otherUser = users[otherId];
      return otherUser?.fullName ?? 'Unknown User';
    } else {
      return name;
    }
  }

  // Get total unread count for a specific user
  int getUnreadCountForUser(String userId) {
    return unreadCount[userId] ?? 0;
  }

  // Convert a JSON map to a Chat
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      type: ChatType.values.firstWhere(
        (e) => e.toString() == 'ChatType.${json['type']}',
        orElse: () => ChatType.direct,
      ),
      name: json['name'] as String? ?? '',
      participantIds: List<String>.from(json['participantIds'] as List),
      lastMessage: json['lastMessage'] != null 
        ? ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>) 
        : null,
      unreadCount: json['unreadCount'] != null 
        ? Map<String, int>.from(json['unreadCount'] as Map)
        : {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt'] as String) 
        : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert a Chat to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'name': name,
      'participantIds': participantIds,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Creates a copy of the Chat with updated fields
  Chat copyWith({
    String? id,
    ChatType? type,
    String? name,
    List<String>? participantIds,
    ChatMessage? lastMessage,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Chat(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      participantIds: participantIds ?? this.participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}