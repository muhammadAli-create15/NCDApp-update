import 'question_type.dart';
import 'option.dart';
import 'skip_rule.dart';
import 'scoring_rule.dart';

/// Represents a question in a questionnaire
class Question {
  /// A unique identifier for the question
  final String questionId;
  
  /// The type of question (boolean, multiple choice, etc.)
  final QuestionType type;
  
  /// The question text
  final String text;
  
  /// Optional clarifying information for the question
  final String? subText;
  
  /// Options for choice-based question types
  final List<Option> options;
  
  /// Rules for determining if this question should be shown
  final List<SkipRule> skipLogic;
  
  /// Rules for scoring the question
  final List<ScoringRule> scoringLogic;
  
  /// Minimum value for numerical or scale questions
  final num? minValue;
  
  /// Maximum value for numerical or scale questions
  final num? maxValue;
  
  /// Unit for numerical questions (e.g., "kg", "cm")
  final String? unit;
  
  /// Whether this question is required to be answered
  final bool required;
  
  /// Constructor for the Question class
  Question({
    required this.questionId,
    required this.type,
    required this.text,
    this.subText,
    this.options = const [],
    this.skipLogic = const [],
    this.scoringLogic = const [],
    this.minValue,
    this.maxValue,
    this.unit,
    this.required = true,
  });
  
  /// Create a Question from JSON
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['questionId'],
      type: QuestionType.fromString(json['type']),
      text: json['text'],
      subText: json['subText'],
      options: (json['options'] as List?)
          ?.map((option) => Option.fromJson(option))
          .toList() ?? [],
      skipLogic: (json['skipLogic'] as List?)
          ?.map((rule) => SkipRule.fromJson(rule))
          .toList() ?? [],
      scoringLogic: (json['scoringLogic'] as List?)
          ?.map((rule) => ScoringRule.fromJson(rule))
          .toList() ?? [],
      minValue: json['minValue'],
      maxValue: json['maxValue'],
      unit: json['unit'],
      required: json['required'] ?? true,
    );
  }
  
  /// Convert Question to JSON
  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'type': type.name,
      'text': text,
      if (subText != null) 'subText': subText,
      if (options.isNotEmpty) 'options': options.map((option) => option.toJson()).toList(),
      if (skipLogic.isNotEmpty) 'skipLogic': skipLogic.map((rule) => rule.toJson()).toList(),
      if (scoringLogic.isNotEmpty) 'scoringLogic': scoringLogic.map((rule) => rule.toJson()).toList(),
      if (minValue != null) 'minValue': minValue,
      if (maxValue != null) 'maxValue': maxValue,
      if (unit != null) 'unit': unit,
      'required': required,
    };
  }
  
  /// Calculate the score for this question based on the given answer
  double calculateScore(dynamic answer) {
    if (answer == null) return 0;
    
    double totalPoints = 0;
    for (final rule in scoringLogic) {
      totalPoints += rule.calculatePoints(answer);
    }
    return totalPoints;
  }
  
  /// Determines if this question should be shown based on previous answers
  bool shouldShow(Map<String, dynamic> answers) {
    // If there's no skip logic, always show the question
    if (skipLogic.isEmpty) return true;
    
    // Check all skip rules - if any rule is satisfied, skip the question
    for (final rule in skipLogic) {
      if (rule.evaluate(answers)) {
        return false; // Skip this question
      }
    }
    
    return true; // Show this question
  }
  
  @override
  String toString() {
    return 'Question{questionId: $questionId, type: $type, text: $text}';
  }
}