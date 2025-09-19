import 'dart:async';

import '../models/models.dart';

/// Abstract repository interface for quiz operations
abstract class QuizRepository {
  /// Fetches all available quizzes
  Future<List<Quiz>> getAvailableQuizzes();
  
  /// Fetches a specific quiz by ID
  Future<Quiz> getQuizById(String quizId);
  
  /// Fetches all quizzes for a specific category
  Future<List<Quiz>> getQuizzesByCategory(QuizCategory category);
  
  /// Creates a new quiz attempt
  Future<QuizAttempt> startQuizAttempt(String userId, String quizId);
  
  /// Updates an existing quiz attempt with new answers
  Future<void> updateQuizAttempt(
    String attemptId, 
    Map<String, List<String>> chosenAnswers,
  );
  
  /// Completes a quiz attempt with final answers and calculates the score
  Future<QuizAttempt> completeQuizAttempt(
    String attemptId,
    Map<String, List<String>> finalAnswers,
  );
  
  /// Retrieves all attempts for a specific user
  Future<List<QuizAttempt>> getUserAttempts(String userId);
  
  /// Retrieves all attempts for a specific quiz by a specific user
  Future<List<QuizAttempt>> getUserAttemptsForQuiz(String userId, String quizId);
  
  /// Retrieves a specific attempt by ID
  Future<QuizAttempt> getAttemptById(String attemptId);
  
  /// Checks if there are newer versions of quizzes available
  Future<bool> checkForUpdates();
  
  /// Syncs local data with remote server
  Future<void> syncWithRemote();
  
  /// Stream that emits when quiz data is updated
  Stream<void> get onQuizDataChanged;
}