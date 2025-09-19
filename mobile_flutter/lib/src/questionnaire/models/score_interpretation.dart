/// Represents an interpretation range for a questionnaire score
class ScoreInterpretation {
  /// Minimum score value for this interpretation (inclusive)
  final double minScore;
  
  /// Maximum score value for this interpretation (inclusive)
  final double maxScore;
  
  /// The interpretation text (e.g., "Low Risk", "Moderate Risk")
  final String label;
  
  /// Detailed description of what this score means
  final String description;
  
  /// Optional color indicator for visual representation (hex color code)
  final String? colorCode;
  
  /// Constructor for the ScoreInterpretation class
  ScoreInterpretation({
    required this.minScore,
    required this.maxScore,
    required this.label,
    required this.description,
    this.colorCode,
  });
  
  /// Create a ScoreInterpretation from JSON
  factory ScoreInterpretation.fromJson(Map<String, dynamic> json) {
    return ScoreInterpretation(
      minScore: json['minScore'] is int 
        ? (json['minScore'] as int).toDouble() 
        : json['minScore'],
      maxScore: json['maxScore'] is int 
        ? (json['maxScore'] as int).toDouble() 
        : json['maxScore'],
      label: json['label'],
      description: json['description'],
      colorCode: json['colorCode'],
    );
  }
  
  /// Convert ScoreInterpretation to JSON
  Map<String, dynamic> toJson() {
    return {
      'minScore': minScore,
      'maxScore': maxScore,
      'label': label,
      'description': description,
      if (colorCode != null) 'colorCode': colorCode,
    };
  }
  
  /// Check if a given score falls within this interpretation range
  bool includesScore(double score) {
    return score >= minScore && score <= maxScore;
  }
  
  @override
  String toString() {
    return 'ScoreInterpretation{label: $label, range: $minScore-$maxScore}';
  }
}