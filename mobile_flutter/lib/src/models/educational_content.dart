import 'education_category.dart';
import 'risk_level.dart';

/// Represents a single unit of educational content in the health education component
class EducationalContent {
  /// A unique identifier for the content
  final String contentId;
  
  /// A short, catchy headline
  final String title;
  
  /// The detailed advice and explanation
  final String body;
  
  /// The category of the advice (e.g., diet, exercise)
  final EducationCategory category;
  
  /// The risk factor this content addresses (e.g., bmi, all, ldl_cholesterol)
  final String targetRiskFactor;
  
  /// Risk levels for which this content is most appropriate
  final List<RiskLevel> targetRiskLevels;
  
  /// To order content within the same category/risk level
  final int priority;
  
  /// When the content was last updated
  final DateTime lastUpdated;
  
  /// Optional list of URLs or citations to credible sources
  final List<String> references;
  
  /// A bulleted list of clear, concrete actions the user can take
  final List<String> actionableSteps;
  
  /// Whether the user has bookmarked/favorited this content
  bool isSaved;
  
  /// Whether the user has read this content
  bool isRead;
  
  EducationalContent({
    required this.contentId,
    required this.title,
    required this.body,
    required this.category,
    required this.targetRiskFactor,
    required this.targetRiskLevels,
    required this.priority,
    required this.lastUpdated,
    this.references = const [],
    required this.actionableSteps,
    this.isSaved = false,
    this.isRead = false,
  });
  
  /// Create from JSON map (e.g. from remote database)
  factory EducationalContent.fromJson(Map<String, dynamic> json) {
    return EducationalContent(
      contentId: json['contentId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      category: EducationCategory.fromId(json['category'] as String) ?? EducationCategory.generalWellness,
      targetRiskFactor: json['targetRiskFactor'] as String,
      targetRiskLevels: (json['targetRiskLevels'] as List)
          .map((level) => _parseRiskLevel(level as String))
          .toList(),
      priority: json['priority'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      references: (json['references'] as List?)?.cast<String>() ?? [],
      actionableSteps: (json['actionableSteps'] as List).cast<String>(),
      isSaved: json['isSaved'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
    );
  }
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'title': title,
      'body': body,
      'category': category.id,
      'targetRiskFactor': targetRiskFactor,
      'targetRiskLevels': targetRiskLevels.map((level) => level.level).toList(),
      'priority': priority,
      'lastUpdated': lastUpdated.toIso8601String(),
      'references': references,
      'actionableSteps': actionableSteps,
      'isSaved': isSaved,
      'isRead': isRead,
    };
  }
  
  /// Helper method to parse risk level from string
  static RiskLevel _parseRiskLevel(String level) {
    return RiskLevel.values.firstWhere(
      (e) => e.level.toLowerCase() == level.toLowerCase(),
      orElse: () => RiskLevel.normal,
    );
  }
  
  /// Create a copy with updated properties
  EducationalContent copyWith({
    String? contentId,
    String? title,
    String? body,
    EducationCategory? category,
    String? targetRiskFactor,
    List<RiskLevel>? targetRiskLevels,
    int? priority,
    DateTime? lastUpdated,
    List<String>? references,
    List<String>? actionableSteps,
    bool? isSaved,
    bool? isRead,
  }) {
    return EducationalContent(
      contentId: contentId ?? this.contentId,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      targetRiskFactor: targetRiskFactor ?? this.targetRiskFactor,
      targetRiskLevels: targetRiskLevels ?? this.targetRiskLevels,
      priority: priority ?? this.priority,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      references: references ?? this.references,
      actionableSteps: actionableSteps ?? this.actionableSteps,
      isSaved: isSaved ?? this.isSaved,
      isRead: isRead ?? this.isRead,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is EducationalContent && other.contentId == contentId;
  }
  
  @override
  int get hashCode => contentId.hashCode;
}