/// Represents a completed questionnaire response
class QuestionnaireResponse {
  /// Unique identifier for this completion instance
  final String responseId;
  
  /// ID of the questionnaire that was completed
  final String questionnaireId;
  
  /// The version of the questionnaire that was completed
  final String questionnaireVersion;
  
  /// ID of the user who completed the questionnaire
  final String userId;
  
  /// When the questionnaire was completed
  final DateTime dateCompleted;
  
  /// Key-Value pairs where the key is the questionId and the value is the user's answer
  final Map<String, dynamic> answers;
  
  /// The final score after applying all scoring rules
  final double calculatedScore;
  
  /// Result interpretation based on the score (e.g., "Low Risk")
  final String? interpretation;
  
  /// Constructor for the QuestionnaireResponse class
  QuestionnaireResponse({
    required this.responseId,
    required this.questionnaireId,
    required this.questionnaireVersion,
    required this.userId,
    required this.dateCompleted,
    required this.answers,
    required this.calculatedScore,
    this.interpretation,
  });
  
  /// Create a QuestionnaireResponse from JSON
  factory QuestionnaireResponse.fromJson(Map<String, dynamic> json) {
    return QuestionnaireResponse(
      responseId: json['responseId'],
      questionnaireId: json['questionnaireId'],
      questionnaireVersion: json['questionnaireVersion'],
      userId: json['userId'],
      dateCompleted: DateTime.parse(json['dateCompleted']),
      answers: Map<String, dynamic>.from(json['answers']),
      calculatedScore: json['calculatedScore'] is int
          ? (json['calculatedScore'] as int).toDouble()
          : json['calculatedScore'],
      interpretation: json['interpretation'],
    );
  }
  
  /// Convert QuestionnaireResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'responseId': responseId,
      'questionnaireId': questionnaireId,
      'questionnaireVersion': questionnaireVersion,
      'userId': userId,
      'dateCompleted': dateCompleted.toIso8601String(),
      'answers': answers,
      'calculatedScore': calculatedScore,
      if (interpretation != null) 'interpretation': interpretation,
    };
  }
  
  /// Create a copy of this response with the given field values overridden
  QuestionnaireResponse copyWith({
    String? responseId,
    String? questionnaireId,
    String? questionnaireVersion,
    String? userId,
    DateTime? dateCompleted,
    Map<String, dynamic>? answers,
    double? calculatedScore,
    String? interpretation,
  }) {
    return QuestionnaireResponse(
      responseId: responseId ?? this.responseId,
      questionnaireId: questionnaireId ?? this.questionnaireId,
      questionnaireVersion: questionnaireVersion ?? this.questionnaireVersion,
      userId: userId ?? this.userId,
      dateCompleted: dateCompleted ?? this.dateCompleted,
      answers: answers ?? this.answers,
      calculatedScore: calculatedScore ?? this.calculatedScore,
      interpretation: interpretation ?? this.interpretation,
    );
  }
  
  @override
  String toString() {
    return 'QuestionnaireResponse{responseId: $responseId, questionnaireId: $questionnaireId, score: $calculatedScore}';
  }
}