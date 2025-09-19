/// Represents a user's attempt at completing a quiz
class QuizAttempt {
  /// A unique identifier for this attempt
  final String attemptId;
  
  /// The ID of the user making the attempt
  final String userId;
  
  /// The ID of the quiz being attempted
  final String quizId;
  
  /// When the user started the quiz
  final DateTime dateStarted;
  
  /// When the user completed the quiz (null if not yet completed)
  final DateTime? dateCompleted;
  
  /// Map of questionId to list of selected option values
  final Map<String, List<String>> chosenAnswers;
  
  /// The user's score as a percentage (0-100)
  final double score;
  
  /// Whether the user passed the quiz based on its passing score
  final bool passed;

  const QuizAttempt({
    required this.attemptId,
    required this.userId,
    required this.quizId,
    required this.dateStarted,
    this.dateCompleted,
    required this.chosenAnswers,
    required this.score,
    required this.passed,
  });

  /// Creates a QuizAttempt from a JSON object
  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    // Convert the JSON map of chosen answers
    final jsonAnswers = json['chosenAnswers'] as Map<String, dynamic>;
    final chosenAnswersMap = <String, List<String>>{};
    
    jsonAnswers.forEach((questionId, answers) {
      if (answers is List) {
        chosenAnswersMap[questionId] = List<String>.from(answers);
      }
    });

    return QuizAttempt(
      attemptId: json['attemptId'] as String,
      userId: json['userId'] as String,
      quizId: json['quizId'] as String,
      dateStarted: DateTime.parse(json['dateStarted'] as String),
      dateCompleted: json['dateCompleted'] != null
          ? DateTime.parse(json['dateCompleted'] as String)
          : null,
      chosenAnswers: chosenAnswersMap,
      score: json['score'] as double,
      passed: json['passed'] as bool,
    );
  }

  /// Converts this QuizAttempt to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'attemptId': attemptId,
      'userId': userId,
      'quizId': quizId,
      'dateStarted': dateStarted.toIso8601String(),
      'dateCompleted': dateCompleted?.toIso8601String(),
      'chosenAnswers': chosenAnswers,
      'score': score,
      'passed': passed,
    };
  }

  /// Creates a copy of this QuizAttempt with the given fields replaced
  QuizAttempt copyWith({
    String? attemptId,
    String? userId,
    String? quizId,
    DateTime? dateStarted,
    DateTime? dateCompleted,
    Map<String, List<String>>? chosenAnswers,
    double? score,
    bool? passed,
  }) {
    return QuizAttempt(
      attemptId: attemptId ?? this.attemptId,
      userId: userId ?? this.userId,
      quizId: quizId ?? this.quizId,
      dateStarted: dateStarted ?? this.dateStarted,
      dateCompleted: dateCompleted ?? this.dateCompleted,
      chosenAnswers: chosenAnswers ?? this.chosenAnswers,
      score: score ?? this.score,
      passed: passed ?? this.passed,
    );
  }

  /// Returns true if the quiz has been completed
  bool get isCompleted => dateCompleted != null;

  /// Returns the duration of the attempt, or null if not completed
  Duration? get duration {
    if (dateCompleted == null) return null;
    return dateCompleted!.difference(dateStarted);
  }

  /// Returns the formatted duration of the attempt
  String get formattedDuration {
    final duration = this.duration;
    if (duration == null) return 'Not completed';
    
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizAttempt &&
        other.attemptId == attemptId &&
        other.userId == userId &&
        other.quizId == quizId;
  }

  @override
  int get hashCode => Object.hash(attemptId, userId, quizId);
}