/// Represents the medical category for a quiz
enum QuizCategory {
  diabetes,
  hypertension,
  kidney,
  generalNcd;

  /// Converts the enum to a string representation suitable for storage/API
  String toJson() => name;

  /// Creates an enum from a string representation
  static QuizCategory fromJson(String value) {
    return QuizCategory.values.firstWhere(
      (element) => element.name == value,
      orElse: () => QuizCategory.generalNcd,
    );
  }

  /// Returns a user-friendly display name
  String get displayName {
    switch (this) {
      case QuizCategory.diabetes:
        return 'Diabetes';
      case QuizCategory.hypertension:
        return 'Hypertension';
      case QuizCategory.kidney:
        return 'Kidney Disease';
      case QuizCategory.generalNcd:
        return 'General NCD Knowledge';
    }
  }
}

/// Represents the difficulty level of a quiz
enum QuizDifficulty {
  beginner,
  intermediate,
  advanced;

  /// Converts the enum to a string representation suitable for storage/API
  String toJson() => name;

  /// Creates an enum from a string representation
  static QuizDifficulty fromJson(String value) {
    return QuizDifficulty.values.firstWhere(
      (element) => element.name == value,
      orElse: () => QuizDifficulty.intermediate,
    );
  }

  /// Returns a user-friendly display name
  String get displayName {
    switch (this) {
      case QuizDifficulty.beginner:
        return 'Beginner';
      case QuizDifficulty.intermediate:
        return 'Intermediate';
      case QuizDifficulty.advanced:
        return 'Advanced';
    }
  }
}

/// Represents the type of question in a quiz
enum QuestionType {
  multipleChoiceSingleAnswer,
  multipleChoiceMultipleAnswer;

  /// Converts the enum to a string representation suitable for storage/API
  String toJson() => name;

  /// Creates an enum from a string representation
  static QuestionType fromJson(String value) {
    return QuestionType.values.firstWhere(
      (element) => element.name == value,
      orElse: () => QuestionType.multipleChoiceSingleAnswer,
    );
  }

  /// Returns true if the question type allows multiple answers
  bool get allowsMultipleAnswers {
    return this == QuestionType.multipleChoiceMultipleAnswer;
  }
}