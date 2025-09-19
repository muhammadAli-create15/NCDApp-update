/// Represents a rule for assigning points based on an answer
class ScoringRule {
  /// The condition that must be met (e.g., '==', '>', '<', 'contains')
  final String condition;
  
  /// The value to compare against
  final dynamic value;
  
  /// The points to award if the condition is met
  final double points;
  
  /// Constructor for the ScoringRule class
  ScoringRule({
    required this.condition,
    required this.value,
    required this.points,
  });
  
  /// Create a ScoringRule from JSON
  factory ScoringRule.fromJson(Map<String, dynamic> json) {
    return ScoringRule(
      condition: json['condition'],
      value: json['value'],
      points: json['points'] is int 
        ? (json['points'] as int).toDouble() 
        : json['points'],
    );
  }
  
  /// Convert ScoringRule to JSON
  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'value': value,
      'points': points,
    };
  }
  
  /// Calculate points based on an answer
  double calculatePoints(dynamic answer) {
    switch (condition) {
      case '==':
        return answer == value ? points : 0;
      case '!=':
        return answer != value ? points : 0;
      case '>':
        return answer is num && value is num && answer > value ? points : 0;
      case '>=':
        return answer is num && value is num && answer >= value ? points : 0;
      case '<':
        return answer is num && value is num && answer < value ? points : 0;
      case '<=':
        return answer is num && value is num && answer <= value ? points : 0;
      case 'contains':
        if (answer is List) {
          return answer.contains(value) ? points : 0;
        } else if (answer is String && value is String) {
          return answer.contains(value) ? points : 0;
        }
        return 0;
      case 'in':
        if (value is List) {
          return value.contains(answer) ? points : 0;
        }
        return 0;
      default:
        return 0;
    }
  }
  
  @override
  String toString() {
    return 'ScoringRule{condition: $condition, value: $value, points: $points}';
  }
}