import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../repositories/questionnaire_repository.dart';

/// Service for managing questionnaires and their logic
class QuestionnaireService extends ChangeNotifier {
  final QuestionnaireRepository _repository;
  
  /// List of questionnaire metadata
  List<Map<String, dynamic>> _questionnairesMetadata = [];
  
  /// Map of questionnaires by ID
  final Map<String, Questionnaire> _questionnaires = {};
  
  /// Map of in-progress sessions by questionnaire ID
  final Map<String, QuestionnaireSession> _sessions = {};
  
  /// Currently loaded responses
  List<QuestionnaireResponse>? _responseHistory;
  
  /// Loading state
  bool _isLoading = false;
  
  /// Error state
  String? _error;
  
  /// Constructor for QuestionnaireService
  QuestionnaireService({
    QuestionnaireRepository? repository,
  }) : _repository = repository ?? QuestionnaireRepository();
  
  /// Loading state getter
  bool get isLoading => _isLoading;
  
  /// Error state getter
  String? get error => _error;
  
  /// Get all questionnaire metadata
  List<Map<String, dynamic>> get questionnairesMetadata => 
      List.unmodifiable(_questionnairesMetadata);
  
  /// Initialize the service by loading questionnaires
  Future<void> initialize() async {
    await loadQuestionnaires();
  }
  
  /// Load all available questionnaires
  Future<void> loadQuestionnaires() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _questionnairesMetadata = await _repository.fetchQuestionnairesMetadata();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load questionnaires: $e';
      notifyListeners();
    }
  }
  
  /// Force refresh questionnaires from the server
  Future<void> refreshQuestionnaires() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _questionnairesMetadata = await _repository.refreshQuestionnaires();
      
      // Clear the loaded questionnaires to force reload
      _questionnaires.clear();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to refresh questionnaires: $e';
      notifyListeners();
    }
  }
  
  /// Get a specific questionnaire by ID
  Future<Questionnaire?> getQuestionnaire(String questionnaireId) async {
    // Return from cache if available
    if (_questionnaires.containsKey(questionnaireId)) {
      return _questionnaires[questionnaireId];
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final questionnaire = await _repository.fetchQuestionnaire(questionnaireId);
      _questionnaires[questionnaireId] = questionnaire;
      _isLoading = false;
      notifyListeners();
      return questionnaire;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load questionnaire: $e';
      notifyListeners();
      return null;
    }
  }
  
  /// Start or resume a questionnaire session
  Future<QuestionnaireSession?> startQuestionnaire(String questionnaireId) async {
    // Check if there's an existing session
    if (_sessions.containsKey(questionnaireId)) {
      return _sessions[questionnaireId];
    }
    
    // Try to load a saved session
    final savedSession = await _repository.getSession(questionnaireId);
    if (savedSession != null) {
      _sessions[questionnaireId] = savedSession;
      return savedSession;
    }
    
    // No existing session, create a new one
    final questionnaire = await getQuestionnaire(questionnaireId);
    if (questionnaire == null) return null;
    
    final session = QuestionnaireSession(questionnaire: questionnaire);
    _sessions[questionnaireId] = session;
    
    // Save the new session
    await _repository.saveSession(session);
    
    return session;
  }
  
  /// Save progress in a questionnaire session
  Future<void> saveQuestionnaireProgress(QuestionnaireSession session) async {
    _sessions[session.questionnaire.questionnaireId] = session;
    await _repository.saveSession(session);
  }
  
  /// Answer a question in a questionnaire session
  Future<void> answerQuestion(
    QuestionnaireSession session, 
    String questionId, 
    dynamic answer
  ) async {
    session.setAnswer(questionId, answer);
    await saveQuestionnaireProgress(session);
  }
  
  /// Move to the next question in a questionnaire session
  bool moveToNextQuestion(QuestionnaireSession session) {
    if (session.isLastQuestion()) {
      return false;
    }
    
    session.currentQuestionIndex = session.getNextQuestionIndex();
    session.lastUpdated = DateTime.now();
    saveQuestionnaireProgress(session);
    return true;
  }
  
  /// Move to the previous question in a questionnaire session
  bool moveToPreviousQuestion(QuestionnaireSession session) {
    if (session.currentQuestionIndex <= 0) {
      return false;
    }
    
    session.currentQuestionIndex = session.getPreviousQuestionIndex();
    session.lastUpdated = DateTime.now();
    saveQuestionnaireProgress(session);
    return true;
  }
  
  /// Complete a questionnaire and save the response
  Future<QuestionnaireResponse> completeQuestionnaire(
    QuestionnaireSession session, 
    String userId,
    {String? interpretation}
  ) async {
    final questionnaire = session.questionnaire;
    final score = questionnaire.calculateTotalScore(session.currentAnswers);
    
    final response = QuestionnaireResponse(
      responseId: _repository.generateResponseId(),
      questionnaireId: questionnaire.questionnaireId,
      questionnaireVersion: questionnaire.version,
      userId: userId,
      dateCompleted: DateTime.now(),
      answers: Map.from(session.currentAnswers),
      calculatedScore: score,
      interpretation: interpretation,
    );
    
    // Save the response
    await _repository.saveResponse(response);
    
    // Clear the session
    _sessions.remove(questionnaire.questionnaireId);
    await _repository.clearSession(questionnaire.questionnaireId);
    
    // Refresh the response history
    _responseHistory = null;
    
    return response;
  }
  
  /// Get the questionnaire response history
  Future<List<QuestionnaireResponse>> getResponseHistory() async {
    if (_responseHistory != null) {
      return _responseHistory!;
    }
    
    _responseHistory = await _repository.getResponseHistory();
    return _responseHistory!;
  }
  
  /// Get responses for a specific questionnaire
  Future<List<QuestionnaireResponse>> getResponsesForQuestionnaire(
    String questionnaireId
  ) async {
    final history = await getResponseHistory();
    return history
        .where((response) => response.questionnaireId == questionnaireId)
        .toList();
  }
  
  /// Get the most recent response for a questionnaire
  Future<QuestionnaireResponse?> getMostRecentResponse(
    String questionnaireId
  ) async {
    return _repository.getMostRecentResponse(questionnaireId);
  }
  
  /// Interpret a score based on interpretation ranges
  String interpretScore(double score, List<ScoreInterpretation> interpretations) {
    for (final interpretation in interpretations) {
      if (interpretation.includesScore(score)) {
        return interpretation.label;
      }
    }
    return 'Unknown';
  }
}