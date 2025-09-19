import 'question.dart';

/// Represents a full assessment questionnaire
class Questionnaire {
  /// A unique identifier for the questionnaire
  final String questionnaireId;
  
  /// User-facing title of the questionnaire
  final String title;
  
  /// Brief explanation of the questionnaire's purpose
  final String description;
  
  /// Version to track updates from the remote source
  final String version;
  
  /// The ordered list of questions in the questionnaire
  final List<Question> questions;
  
  /// Category of the questionnaire (e.g., "cardiovascular", "diabetes")
  final String? category;
  
  /// Estimated time to complete in minutes
  final int? estimatedTimeMinutes;
  
  /// If the questionnaire should be paginated or scrollable
  final bool isPaginated;
  
  /// Constructor for the Questionnaire class
  Questionnaire({
    required this.questionnaireId,
    required this.title,
    required this.description,
    required this.version,
    required this.questions,
    this.category,
    this.estimatedTimeMinutes,
    this.isPaginated = false,
  });
  
  /// Create a Questionnaire from JSON
  factory Questionnaire.fromJson(Map<String, dynamic> json) {
    return Questionnaire(
      questionnaireId: json['questionnaireId'],
      title: json['title'],
      description: json['description'],
      version: json['version'],
      questions: (json['questions'] as List)
          .map((question) => Question.fromJson(question))
          .toList(),
      category: json['category'],
      estimatedTimeMinutes: json['estimatedTimeMinutes'],
      isPaginated: json['isPaginated'] ?? false,
    );
  }
  
  /// Convert Questionnaire to JSON
  Map<String, dynamic> toJson() {
    return {
      'questionnaireId': questionnaireId,
      'title': title,
      'description': description,
      'version': version,
      'questions': questions.map((question) => question.toJson()).toList(),
      if (category != null) 'category': category,
      if (estimatedTimeMinutes != null) 'estimatedTimeMinutes': estimatedTimeMinutes,
      'isPaginated': isPaginated,
    };
  }
  
  /// Get visible questions based on current answers
  List<Question> getVisibleQuestions(Map<String, dynamic> answers) {
    return questions.where((question) => question.shouldShow(answers)).toList();
  }
  
  /// Calculate the overall score for the questionnaire based on all answers
  double calculateTotalScore(Map<String, dynamic> answers) {
    double totalScore = 0;
    
    for (final question in questions) {
      if (answers.containsKey(question.questionId)) {
        totalScore += question.calculateScore(answers[question.questionId]);
      }
    }
    
    return totalScore;
  }
  
  @override
  String toString() {
    return 'Questionnaire{questionnaireId: $questionnaireId, title: $title, version: $version}';
  }
}