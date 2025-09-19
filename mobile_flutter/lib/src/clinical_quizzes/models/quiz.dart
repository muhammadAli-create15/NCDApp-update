import 'enums.dart';
import 'question.dart';

/// Represents a complete quiz with questions and metadata
class Quiz {
  /// A unique identifier for the quiz
  final String quizId;
  
  /// The title of the quiz
  final String title;
  
  /// A description of what the quiz covers
  final String description;
  
  /// The medical category for this quiz
  final QuizCategory category;
  
  /// The difficulty level of the quiz
  final QuizDifficulty difficulty;
  
  /// The version of this quiz content
  final String version;
  
  /// The list of questions in this quiz
  final List<Question> questions;
  
  /// The minimum score percentage required to pass the quiz (0-100)
  final int passingScore;
  
  /// Optional limit on how many times a user can attempt the quiz
  final int? maxAttempts;

  const Quiz({
    required this.quizId,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.version,
    required this.questions,
    required this.passingScore,
    this.maxAttempts,
  });

  /// Creates a Quiz from a JSON object
  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      quizId: json['quizId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: QuizCategory.fromJson(json['category'] as String),
      difficulty: QuizDifficulty.fromJson(json['difficulty'] as String),
      version: json['version'] as String,
      questions: (json['questions'] as List)
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList(),
      passingScore: json['passingScore'] as int,
      maxAttempts: json['maxAttempts'] as int?,
    );
  }

  /// Converts this Quiz to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'title': title,
      'description': description,
      'category': category.toJson(),
      'difficulty': difficulty.toJson(),
      'version': version,
      'questions': questions.map((q) => q.toJson()).toList(),
      'passingScore': passingScore,
      'maxAttempts': maxAttempts,
    };
  }

  /// Creates a copy of this Quiz with the given fields replaced
  Quiz copyWith({
    String? quizId,
    String? title,
    String? description,
    QuizCategory? category,
    QuizDifficulty? difficulty,
    String? version,
    List<Question>? questions,
    int? passingScore,
    int? maxAttempts,
  }) {
    return Quiz(
      quizId: quizId ?? this.quizId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      version: version ?? this.version,
      questions: questions ?? this.questions,
      passingScore: passingScore ?? this.passingScore,
      maxAttempts: maxAttempts ?? this.maxAttempts,
    );
  }

  /// Returns the total number of questions in this quiz
  int get questionCount => questions.length;

  /// Returns the maximum possible score for this quiz
  int get maxScore => questionCount;

  /// Calculates if the given score passes this quiz
  bool isPassed(double score) {
    final percentage = (score / maxScore) * 100;
    return percentage >= passingScore;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Quiz &&
        other.quizId == quizId &&
        other.title == title &&
        other.category == category &&
        other.difficulty == difficulty &&
        other.version == version;
  }

  @override
  int get hashCode => Object.hash(quizId, title, category, difficulty, version);
}