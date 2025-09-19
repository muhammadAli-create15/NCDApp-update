import 'package:flutter/foundation.dart';

class ChatUser {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? pushToken;

  ChatUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
    this.pushToken,
  });

  String get fullName => '$firstName $lastName';

  // Convert a JSON map to a ChatUser
  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null 
        ? DateTime.parse(json['lastSeen'] as String) 
        : null,
      pushToken: json['pushToken'] as String?,
    );
  }

  // Convert a ChatUser to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'pushToken': pushToken,
    };
  }

  // Creates a copy of the ChatUser with updated fields
  ChatUser copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
    String? pushToken,
  }) {
    return ChatUser(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      pushToken: pushToken ?? this.pushToken,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}