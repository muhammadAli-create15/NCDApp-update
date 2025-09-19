import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../data/mock_quiz_data.dart';
import '../models/models.dart';
import 'quiz_repository.dart';

/// Mock implementation of QuizRepository for development and testing
class MockQuizRepository implements QuizRepository {
  final List<Quiz> _quizzes = [];
  final List<QuizAttempt> _attempts = [];
  final _quizDataController = StreamController<void>.broadcast();
  final _uuid = const Uuid();
  
  // Simulate user ID from authentication
  final String _currentUserId = 'user123';

  MockQuizRepository() {
    _loadMockData();
  }

  @override
  Stream<void> get onQuizDataChanged => _quizDataController.stream;

  @override
  Future<bool> checkForUpdates() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    return false; // Mock: no updates available
  }

  @override
  Future<QuizAttempt> completeQuizAttempt(
    String attemptId, 
    Map<String, List<String>> finalAnswers,
  ) async {
    // Find the attempt
    final attemptIndex = _attempts.indexWhere((a) => a.attemptId == attemptId);
    if (attemptIndex == -1) {
      throw Exception('Attempt not found');
    }

    // Find the associated quiz
    final attempt = _attempts[attemptIndex];
    final quiz = await getQuizById(attempt.quizId);

    // Calculate score
    double correctAnswers = 0;
    for (final question in quiz.questions) {
      final answersForQuestion = finalAnswers[question.questionId];
      if (answersForQuestion != null && 
          question.areAnswersCorrect(answersForQuestion)) {
        correctAnswers++;
      }
    }

    final score = (correctAnswers / quiz.questionCount) * 100;
    final passed = quiz.isPassed(correctAnswers);

    // Update the attempt with the final answers, score, and completion status
    final updatedAttempt = attempt.copyWith(
      chosenAnswers: finalAnswers,
      dateCompleted: DateTime.now(),
      score: score,
      passed: passed,
    );

    _attempts[attemptIndex] = updatedAttempt;
    _quizDataController.add(null); // Notify listeners
    
    return updatedAttempt;
  }

  @override
  Future<QuizAttempt> getAttemptById(String attemptId) async {
    final attempt = _attempts.firstWhere(
      (a) => a.attemptId == attemptId,
      orElse: () => throw Exception('Attempt not found'),
    );
    return attempt;
  }

  @override
  Future<List<Quiz>> getAvailableQuizzes() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    return _quizzes;
  }

  @override
  Future<Quiz> getQuizById(String quizId) async {
    final quiz = _quizzes.firstWhere(
      (q) => q.quizId == quizId,
      orElse: () => throw Exception('Quiz not found'),
    );
    return quiz;
  }

  @override
  Future<List<Quiz>> getQuizzesByCategory(QuizCategory category) async {
    return _quizzes.where((q) => q.category == category).toList();
  }

  @override
  Future<List<QuizAttempt>> getUserAttempts(String userId) async {
    return _attempts.where((a) => a.userId == userId).toList();
  }

  @override
  Future<List<QuizAttempt>> getUserAttemptsForQuiz(
    String userId, 
    String quizId,
  ) async {
    return _attempts
        .where((a) => a.userId == userId && a.quizId == quizId)
        .toList();
  }

  @override
  Future<QuizAttempt> startQuizAttempt(String userId, String quizId) async {
    // Verify the quiz exists
    await getQuizById(quizId);

    final attempt = QuizAttempt(
      attemptId: _uuid.v4(),
      userId: userId,
      quizId: quizId,
      dateStarted: DateTime.now(),
      dateCompleted: null,
      chosenAnswers: {},
      score: 0,
      passed: false,
    );

    _attempts.add(attempt);
    _quizDataController.add(null); // Notify listeners
    
    return attempt;
  }

  @override
  Future<void> syncWithRemote() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    // In a real implementation, this would sync data with a remote server
  }

  @override
  Future<void> updateQuizAttempt(
    String attemptId, 
    Map<String, List<String>> chosenAnswers,
  ) async {
    final attemptIndex = _attempts.indexWhere((a) => a.attemptId == attemptId);
    if (attemptIndex == -1) {
      throw Exception('Attempt not found');
    }

    // Merge the existing answers with the new ones
    final currentAnswers = Map<String, List<String>>.from(
      _attempts[attemptIndex].chosenAnswers,
    );
    currentAnswers.addAll(chosenAnswers);

    // Update the attempt
    _attempts[attemptIndex] = _attempts[attemptIndex].copyWith(
      chosenAnswers: currentAnswers,
    );
    
    _quizDataController.add(null); // Notify listeners
  }

  // Helper method to load mock data
  void _loadMockData() {
    // Load sample quizzes from MockQuizData
    _quizzes.addAll(MockQuizData.getSampleQuizzes());
    
    // If no quizzes were loaded, fall back to the older implementation
    if (_quizzes.isEmpty) {
      _loadLegacyMockData();
    }
  }
  
  // Legacy method to load mock data if needed
  void _loadLegacyMockData() {
    // Add sample quizzes here
    _quizzes.addAll([
      Quiz(
        quizId: 'hypertension_guidelines_2023',
        title: '2023 Hypertension Management Guidelines',
        description: 'Test your knowledge of the latest guidelines for managing hypertension in adults.',
        category: QuizCategory.hypertension,
        difficulty: QuizDifficulty.intermediate,
        version: '1.0',
        questions: _createHypertensionQuizQuestions(),
        passingScore: 70,
        maxAttempts: null,
      ),
      Quiz(
        quizId: 'diabetes_management_2023',
        title: 'Diabetes Management Essentials',
        description: 'Core concepts in modern diabetes management, including medication, lifestyle interventions, and monitoring.',
        category: QuizCategory.diabetes,
        difficulty: QuizDifficulty.beginner,
        version: '1.1',
        questions: _createDiabetesQuizQuestions(),
        passingScore: 80,
        maxAttempts: null,
      ),
      Quiz(
        quizId: 'kidney_disease_advanced',
        title: 'Advanced CKD Management',
        description: 'Advanced topics in chronic kidney disease management for specialists.',
        category: QuizCategory.kidney,
        difficulty: QuizDifficulty.advanced,
        version: '1.0',
        questions: _createKidneyDiseaseQuizQuestions(),
        passingScore: 75,
        maxAttempts: 3,
      ),
    ]);
  }

  // Helper methods to create mock questions
  List<Question> _createHypertensionQuizQuestions() {
    return [
      Question(
        questionId: 'htn_q1',
        type: QuestionType.multipleChoiceSingleAnswer,
        text: 'According to the 2023 guidelines, what is the recommended blood pressure target for most adults with hypertension?',
        options: [
          Option(value: 'a', displayText: '<150/90 mmHg', isCorrect: false),
          Option(value: 'b', displayText: '<140/90 mmHg', isCorrect: false),
          Option(value: 'c', displayText: '<130/80 mmHg', isCorrect: true),
          Option(value: 'd', displayText: '<120/70 mmHg', isCorrect: false),
        ],
        explanation: 'The 2023 guidelines recommend a target of <130/80 mmHg for most adults with hypertension. This more aggressive target is based on evidence from the SPRINT trial and other studies showing cardiovascular benefit from more intensive blood pressure control.',
      ),
      Question(
        questionId: 'htn_q2',
        type: QuestionType.multipleChoiceSingleAnswer,
        text: 'A 58-year-old patient with Type 2 Diabetes and preserved ejection fraction has a BP of 145/88 mmHg. According to the latest guidelines, what is the first-line recommended pharmacologic approach?',
        options: [
          Option(value: 'a', displayText: 'ACE Inhibitor or ARB', isCorrect: true),
          Option(value: 'b', displayText: 'Calcium Channel Blocker', isCorrect: false),
          Option(value: 'c', displayText: 'Thiazide Diuretic', isCorrect: false),
          Option(value: 'd', displayText: 'Beta Blocker', isCorrect: false),
        ],
        explanation: 'For patients with diabetes and hypertension, an ACE Inhibitor or ARB is recommended as first-line therapy due to their proven benefits in diabetic nephropathy. This is supported by multiple clinical trials showing reduced progression of kidney disease and cardiovascular events in diabetic patients treated with these agents.',
      ),
      Question(
        questionId: 'htn_q3',
        type: QuestionType.multipleChoiceMultipleAnswer,
        text: 'Which of the following are considered compelling indications for specific antihypertensive drug classes? Select all that apply.',
        options: [
          Option(value: 'a', displayText: 'Heart failure with reduced ejection fraction - ACE inhibitor', isCorrect: true),
          Option(value: 'b', displayText: 'Osteoporosis - Thiazide diuretic', isCorrect: true),
          Option(value: 'c', displayText: 'Migraine - Alpha blocker', isCorrect: false),
          Option(value: 'd', displayText: 'Prior myocardial infarction - Beta blocker', isCorrect: true),
          Option(value: 'e', displayText: 'Benign prostatic hyperplasia - Calcium channel blocker', isCorrect: false),
        ],
        explanation: 'Heart failure with reduced ejection fraction is a compelling indication for ACE inhibitors due to mortality benefits. Thiazide diuretics can help reduce calcium excretion and increase bone density, beneficial in osteoporosis. Beta blockers reduce mortality post-MI. Alpha blockers are indicated for BPH, not migraines, and CCBs don\'t have specific benefits for BPH.',
      ),
    ];
  }

  List<Question> _createDiabetesQuizQuestions() {
    return [
      Question(
        questionId: 'dm_q1',
        type: QuestionType.multipleChoiceSingleAnswer,
        text: 'What is the recommended HbA1c target for most non-pregnant adults with diabetes according to the American Diabetes Association?',
        options: [
          Option(value: 'a', displayText: '<6.0%', isCorrect: false),
          Option(value: 'b', displayText: '<6.5%', isCorrect: false),
          Option(value: 'c', displayText: '<7.0%', isCorrect: true),
          Option(value: 'd', displayText: '<7.5%', isCorrect: false),
        ],
        explanation: 'The American Diabetes Association recommends an HbA1c target of <7.0% for most non-pregnant adults with diabetes. This target balances the benefits of glycemic control with the risks of hypoglycemia and other adverse effects of treatment.',
      ),
      Question(
        questionId: 'dm_q2',
        type: QuestionType.multipleChoiceMultipleAnswer,
        text: 'Which of the following medications have been shown to reduce cardiovascular events in patients with type 2 diabetes and established cardiovascular disease? Select all that apply.',
        imageUrl: 'https://example.com/diabetes_meds_chart.jpg',
        options: [
          Option(value: 'a', displayText: 'Empagliflozin (SGLT2 inhibitor)', isCorrect: true),
          Option(value: 'b', displayText: 'Liraglutide (GLP-1 receptor agonist)', isCorrect: true),
          Option(value: 'c', displayText: 'Sitagliptin (DPP-4 inhibitor)', isCorrect: false),
          Option(value: 'd', displayText: 'Canagliflozin (SGLT2 inhibitor)', isCorrect: true),
          Option(value: 'e', displayText: 'Glimepiride (Sulfonylurea)', isCorrect: false),
        ],
        explanation: 'SGLT2 inhibitors (empagliflozin, canagliflozin) and GLP-1 receptor agonists (liraglutide) have demonstrated cardiovascular benefits in large randomized controlled trials. The EMPA-REG OUTCOME trial showed that empagliflozin reduced cardiovascular death by 38%. The LEADER trial showed that liraglutide reduced major adverse cardiovascular events by 13%. The CANVAS program showed that canagliflozin reduced major adverse cardiovascular events by 14%. DPP-4 inhibitors and sulfonylureas have not demonstrated cardiovascular benefits in clinical trials.',
      ),
    ];
  }

  List<Question> _createKidneyDiseaseQuizQuestions() {
    return [
      Question(
        questionId: 'ckd_q1',
        type: QuestionType.multipleChoiceSingleAnswer,
        text: 'A 67-year-old patient has an eGFR of 25 mL/min/1.73m² and albuminuria of 500 mg/g. According to the KDIGO classification, what stage of CKD does this represent?',
        options: [
          Option(value: 'a', displayText: 'Stage 3a, A3', isCorrect: false),
          Option(value: 'b', displayText: 'Stage 3b, A3', isCorrect: false),
          Option(value: 'c', displayText: 'Stage 4, A3', isCorrect: true),
          Option(value: 'd', displayText: 'Stage 5, A2', isCorrect: false),
        ],
        explanation: 'According to the KDIGO classification, an eGFR of 25 mL/min/1.73m² corresponds to Stage 4 CKD (eGFR 15-29 mL/min/1.73m²). Albuminuria of 500 mg/g is classified as A3 (>300 mg/g). Therefore, this patient has Stage 4, A3 CKD, which represents a high risk for progression to kidney failure and cardiovascular events.',
      ),
      Question(
        questionId: 'ckd_q2',
        type: QuestionType.multipleChoiceMultipleAnswer,
        text: 'Which of the following interventions have been shown to slow the progression of diabetic kidney disease? Select all that apply.',
        options: [
          Option(value: 'a', displayText: 'SGLT2 inhibitors', isCorrect: true),
          Option(value: 'b', displayText: 'ACE inhibitors or ARBs', isCorrect: true),
          Option(value: 'c', displayText: 'Finerenone', isCorrect: true),
          Option(value: 'd', displayText: 'Intensive glucose control (HbA1c <6.5%)', isCorrect: false),
          Option(value: 'e', displayText: 'High-protein diet', isCorrect: false),
        ],
        explanation: 'SGLT2 inhibitors have shown significant renal benefits in multiple trials (CREDENCE, DAPA-CKD). ACE inhibitors and ARBs reduce albuminuria and slow progression of diabetic kidney disease. Finerenone, a non-steroidal mineralocorticoid receptor antagonist, has been shown to reduce CKD progression in the FIDELIO-DKD trial. Very intensive glucose control has not consistently shown benefits and carries hypoglycemia risks. High-protein diets may actually accelerate CKD progression and are typically not recommended.',
      ),
    ];
  }

  // Clean up resources
  void dispose() {
    _quizDataController.close();
  }
}