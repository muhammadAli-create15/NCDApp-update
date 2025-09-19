/// Support Group model representing a forum/group for NCD support
class SupportGroup {
  /// A unique identifier (e.g., "diabetes_type2", "hypertension_management")
  final String groupId;
  
  /// User-facing name (e.g., "Type 2 Diabetes Support Forum")
  final String name;
  
  /// A detailed overview of the group's purpose, focus, and rules
  final String description;
  
  /// A URL or path to an icon representing the condition
  final String iconUrl;
  
  /// List of user IDs for users with elevated privileges
  /// (e.g., to remove posts, pin announcements)
  final List<String> moderatorIds;
  
  /// Community rules and etiquette for participation
  final String guidelines;
  
  /// Allows for soft-launching or archiving groups
  final bool isActive;
  
  /// Timestamp from the remote config to manage caching
  final DateTime lastUpdated;
  
  /// Constructor for the SupportGroup class
  SupportGroup({
    required this.groupId,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.moderatorIds,
    required this.guidelines,
    required this.isActive,
    required this.lastUpdated,
  });
  
  /// Create a SupportGroup from JSON
  factory SupportGroup.fromJson(Map<String, dynamic> json) {
    return SupportGroup(
      groupId: json['groupId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      moderatorIds: List<String>.from(json['moderatorIds'] ?? []),
      guidelines: json['guidelines'] as String,
      isActive: json['isActive'] as bool,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
  
  /// Convert SupportGroup to JSON
  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'moderatorIds': moderatorIds,
      'guidelines': guidelines,
      'isActive': isActive,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  /// Check if the given user is a moderator of this group
  bool isModerator(String userId) {
    return moderatorIds.contains(userId);
  }
  
  @override
  String toString() {
    return 'SupportGroup{groupId: $groupId, name: $name}';
  }
}