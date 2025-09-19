/// Enum representing different types of questions in a questionnaire
enum QuestionType {
  /// A simple yes/no question
  boolean,
  
  /// Question allowing selection of multiple answers from options
  multipleChoice,
  
  /// Question requiring selection of a single answer from options
  singleChoice,
  
  /// Question requiring a numerical input
  numerical,
  
  /// Question requiring selection on a scale (e.g., 1-10)
  scale,
  
  /// Question requiring a free-text response
  text;
  
  /// Convert the enum value to a string representation
  String get name {
    switch (this) {
      case QuestionType.boolean:
        return 'boolean';
      case QuestionType.multipleChoice:
        return 'multipleChoice';
      case QuestionType.singleChoice:
        return 'singleChoice';
      case QuestionType.numerical:
        return 'numerical';
      case QuestionType.scale:
        return 'scale';
      case QuestionType.text:
        return 'text';
    }
  }
  
  /// Parse a string to get the corresponding QuestionType enum value
  static QuestionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'boolean':
        return QuestionType.boolean;
      case 'multiplechoice':
        return QuestionType.multipleChoice;
      case 'singlechoice':
        return QuestionType.singleChoice;
      case 'numerical':
        return QuestionType.numerical;
      case 'scale':
        return QuestionType.scale;
      case 'text':
        return QuestionType.text;
      default:
        throw ArgumentError('Invalid QuestionType: $value');
    }
  }
}