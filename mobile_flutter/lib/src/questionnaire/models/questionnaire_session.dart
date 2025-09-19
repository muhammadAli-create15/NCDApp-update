import 'questionnaire.dart';

/// Represents an in-progress questionnaire session
class QuestionnaireSession {
  /// The questionnaire being completed
  final Questionnaire questionnaire;
  
  /// Current answers provided by the user
  final Map<String, dynamic> currentAnswers;
  
  /// The index of the current question (for paginated questionnaires)
  int currentQuestionIndex;
  
  /// When the session was started
  final DateTime startTime;
  
  /// When the session was last updated
  DateTime lastUpdated;
  
  /// Constructor for the QuestionnaireSession class
  QuestionnaireSession({
    required this.questionnaire,
    Map<String, dynamic>? currentAnswers,
    this.currentQuestionIndex = 0,
    DateTime? startTime,
    DateTime? lastUpdated,
  }) : 
    this.currentAnswers = currentAnswers ?? {},
    this.startTime = startTime ?? DateTime.now(),
    this.lastUpdated = lastUpdated ?? DateTime.now();
  
  /// Create a QuestionnaireSession from JSON
  factory QuestionnaireSession.fromJson(Map<String, dynamic> json, Questionnaire questionnaire) {
    return QuestionnaireSession(
      questionnaire: questionnaire,
      currentAnswers: Map<String, dynamic>.from(json['currentAnswers']),
      currentQuestionIndex: json['currentQuestionIndex'],
      startTime: DateTime.parse(json['startTime']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
  
  /// Convert QuestionnaireSession to JSON
  Map<String, dynamic> toJson() {
    return {
      'questionnaireId': questionnaire.questionnaireId,
      'currentAnswers': currentAnswers,
      'currentQuestionIndex': currentQuestionIndex,
      'startTime': startTime.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  /// Updates an answer and sets lastUpdated to current time
  void setAnswer(String questionId, dynamic answer) {
    currentAnswers[questionId] = answer;
    lastUpdated = DateTime.now();
  }
  
  /// Get the next question index based on skip logic
  int getNextQuestionIndex() {
    final visibleQuestions = questionnaire.getVisibleQuestions(currentAnswers);
    
    // Find the current question in the visible questions list
    int currentVisibleIndex = -1;
    if (currentQuestionIndex < questionnaire.questions.length) {
      final currentQuestionId = questionnaire.questions[currentQuestionIndex].questionId;
      for (int i = 0; i < visibleQuestions.length; i++) {
        if (visibleQuestions[i].questionId == currentQuestionId) {
          currentVisibleIndex = i;
          break;
        }
      }
    }
    
    // Get the next visible question's index in the full questions list
    if (currentVisibleIndex < visibleQuestions.length - 1) {
      final nextVisibleQuestion = visibleQuestions[currentVisibleIndex + 1];
      for (int i = 0; i < questionnaire.questions.length; i++) {
        if (questionnaire.questions[i].questionId == nextVisibleQuestion.questionId) {
          return i;
        }
      }
    }
    
    // If we can't find a next question, return the current index
    return currentQuestionIndex;
  }
  
  /// Get the previous question index based on skip logic
  int getPreviousQuestionIndex() {
    final visibleQuestions = questionnaire.getVisibleQuestions(currentAnswers);
    
    // Find the current question in the visible questions list
    int currentVisibleIndex = -1;
    if (currentQuestionIndex < questionnaire.questions.length) {
      final currentQuestionId = questionnaire.questions[currentQuestionIndex].questionId;
      for (int i = 0; i < visibleQuestions.length; i++) {
        if (visibleQuestions[i].questionId == currentQuestionId) {
          currentVisibleIndex = i;
          break;
        }
      }
    }
    
    // Get the previous visible question's index in the full questions list
    if (currentVisibleIndex > 0) {
      final previousVisibleQuestion = visibleQuestions[currentVisibleIndex - 1];
      for (int i = 0; i < questionnaire.questions.length; i++) {
        if (questionnaire.questions[i].questionId == previousVisibleQuestion.questionId) {
          return i;
        }
      }
    }
    
    // If we can't find a previous question, return the current index
    return currentQuestionIndex;
  }
  
  /// Check if this is the last question in the questionnaire
  bool isLastQuestion() {
    final visibleQuestions = questionnaire.getVisibleQuestions(currentAnswers);
    if (visibleQuestions.isEmpty) return true;
    
    // Find the current question in the visible questions list
    if (currentQuestionIndex < questionnaire.questions.length) {
      final currentQuestionId = questionnaire.questions[currentQuestionIndex].questionId;
      for (int i = 0; i < visibleQuestions.length; i++) {
        if (visibleQuestions[i].questionId == currentQuestionId) {
          // If this is the last visible question, return true
          return i == visibleQuestions.length - 1;
        }
      }
    }
    
    return false;
  }
  
  /// Check if all required questions have been answered
  bool allRequiredQuestionsAnswered() {
    final visibleQuestions = questionnaire.getVisibleQuestions(currentAnswers);
    for (final question in visibleQuestions) {
      if (question.required && 
          (!currentAnswers.containsKey(question.questionId) || 
           currentAnswers[question.questionId] == null)) {
        return false;
      }
    }
    return true;
  }
  
  /// Calculate the progress percentage (0.0 to 1.0)
  double calculateProgress() {
    final visibleQuestions = questionnaire.getVisibleQuestions(currentAnswers);
    if (visibleQuestions.isEmpty) return 1.0;
    
    // Count how many questions have been answered
    int answeredCount = 0;
    for (final question in visibleQuestions) {
      if (currentAnswers.containsKey(question.questionId) && 
          currentAnswers[question.questionId] != null) {
        answeredCount++;
      }
    }
    
    return answeredCount / visibleQuestions.length;
  }
}