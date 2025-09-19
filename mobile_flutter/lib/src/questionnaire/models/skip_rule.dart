/// Represents a rule for determining if a question should be shown based on previous answers
class SkipRule {
  /// The ID of the question this rule depends on
  final String sourceQuestionId;
  
  /// The condition that must be met (e.g., '==', '>', '<', 'contains')
  final String condition;
  
  /// The value to compare against
  final dynamic value;
  
  /// Constructor for the SkipRule class
  SkipRule({
    required this.sourceQuestionId,
    required this.condition,
    required this.value,
  });
  
  /// Create a SkipRule from JSON
  factory SkipRule.fromJson(Map<String, dynamic> json) {
    return SkipRule(
      sourceQuestionId: json['sourceQuestionId'],
      condition: json['condition'],
      value: json['value'],
    );
  }
  
  /// Convert SkipRule to JSON
  Map<String, dynamic> toJson() {
    return {
      'sourceQuestionId': sourceQuestionId,
      'condition': condition,
      'value': value,
    };
  }
  
  /// Evaluate if this skip rule is satisfied based on a given answer
  bool evaluate(Map<String, dynamic> answers) {
    // If the source question hasn't been answered yet, default to showing the question
    if (!answers.containsKey(sourceQuestionId)) return false;
    
    final sourceAnswer = answers[sourceQuestionId];
    
    switch (condition) {
      case '==':
        return sourceAnswer == value;
      case '!=':
        return sourceAnswer != value;
      case '>':
        return sourceAnswer is num && value is num && sourceAnswer > value;
      case '>=':
        return sourceAnswer is num && value is num && sourceAnswer >= value;
      case '<':
        return sourceAnswer is num && value is num && sourceAnswer < value;
      case '<=':
        return sourceAnswer is num && value is num && sourceAnswer <= value;
      case 'contains':
        if (sourceAnswer is List) {
          return sourceAnswer.contains(value);
        } else if (sourceAnswer is String && value is String) {
          return sourceAnswer.contains(value);
        }
        return false;
      case 'isEmpty':
        if (sourceAnswer is String) {
          return sourceAnswer.isEmpty;
        } else if (sourceAnswer is List) {
          return sourceAnswer.isEmpty;
        }
        return sourceAnswer == null;
      case 'isNotEmpty':
        if (sourceAnswer is String) {
          return sourceAnswer.isNotEmpty;
        } else if (sourceAnswer is List) {
          return sourceAnswer.isNotEmpty;
        }
        return sourceAnswer != null;
      default:
        return false;
    }
  }
  
  @override
  String toString() {
    return 'SkipRule{sourceQuestionId: $sourceQuestionId, condition: $condition, value: $value}';
  }
}