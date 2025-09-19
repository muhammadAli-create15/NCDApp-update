import 'enums.dart';
import 'option.dart';

/// Represents a question in a quiz
class Question {
  /// A unique identifier for the question within the quiz
  final String questionId;
  
  /// The type of question (single answer, multiple answers)
  final QuestionType type;
  
  /// The text of the question
  final String text;
  
  /// Optional URL for an image related to the question
  final String? imageUrl;
  
  /// The list of available answer options
  final List<Option> options;
  
  /// Detailed explanation of the correct answer(s) and rationale
  final String explanation;

  const Question({
    required this.questionId,
    required this.type,
    required this.text,
    this.imageUrl,
    required this.options,
    required this.explanation,
  });

  /// Creates a Question from a JSON object
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['questionId'] as String,
      type: QuestionType.fromJson(json['type'] as String),
      text: json['text'] as String,
      imageUrl: json['imageUrl'] as String?,
      options: (json['options'] as List)
          .map((e) => Option.fromJson(e as Map<String, dynamic>))
          .toList(),
      explanation: json['explanation'] as String,
    );
  }

  /// Converts this Question to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'type': type.toJson(),
      'text': text,
      'imageUrl': imageUrl,
      'options': options.map((e) => e.toJson()).toList(),
      'explanation': explanation,
    };
  }

  /// Creates a copy of this Question with the given fields replaced
  Question copyWith({
    String? questionId,
    QuestionType? type,
    String? text,
    String? imageUrl,
    List<Option>? options,
    String? explanation,
  }) {
    return Question(
      questionId: questionId ?? this.questionId,
      type: type ?? this.type,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      options: options ?? this.options,
      explanation: explanation ?? this.explanation,
    );
  }

  /// Returns all correct options for this question
  List<Option> get correctOptions {
    return options.where((option) => option.isCorrect).toList();
  }

  /// Returns true if the selected answers are correct
  bool areAnswersCorrect(List<String> selectedOptionValues) {
    // If it's a single answer question, only one answer should be selected
    if (type == QuestionType.multipleChoiceSingleAnswer && selectedOptionValues.length != 1) {
      return false;
    }

    // Get the values of all correct options
    final correctValues = options
        .where((option) => option.isCorrect)
        .map((option) => option.value)
        .toList();

    // For correct answers:
    // 1. All selected options must be correct
    // 2. All correct options must be selected
    return selectedOptionValues.every((value) => correctValues.contains(value)) &&
           correctValues.every((value) => selectedOptionValues.contains(value));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Question &&
        other.questionId == questionId &&
        other.type == type &&
        other.text == text &&
        other.imageUrl == imageUrl &&
        other.explanation == explanation;
  }

  @override
  int get hashCode => Object.hash(questionId, type, text, imageUrl, explanation);
}