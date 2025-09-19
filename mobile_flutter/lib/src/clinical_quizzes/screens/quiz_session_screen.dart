import 'package:flutter/material.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';
import '../widgets/widgets.dart';
import 'quiz_results_screen.dart';

/// Screen for taking a quiz
class QuizSessionScreen extends StatefulWidget {
  /// The quiz being taken
  final Quiz quiz;
  
  /// The ID of the current attempt
  final String attemptId;

  const QuizSessionScreen({
    Key? key,
    required this.quiz,
    required this.attemptId,
  }) : super(key: key);

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  final QuizRepository _repository = MockQuizRepository();
  late PageController _pageController;
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;
  bool _isFinishDialogOpen = false;
  
  // Map to store selected answers for each question
  Map<String, List<String>> _answers = {};
  
  // Feedback mode (learning mode vs. test mode)
  final bool _showImmediateFeedback = true;
  Map<String, bool> _questionsFeedbackShown = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Gets the current question
  Question get _currentQuestion {
    return widget.quiz.questions[_currentQuestionIndex];
  }

  /// Gets the selected answer values for the current question
  List<String> get _currentAnswers {
    return _answers[_currentQuestion.questionId] ?? [];
  }

  /// Checks if feedback is currently being shown for the current question
  bool get _showingFeedback {
    return _questionsFeedbackShown[_currentQuestion.questionId] ?? false;
  }

  /// Submits the answer for the current question
  Future<void> _submitCurrentAnswer() async {
    final questionId = _currentQuestion.questionId;
    
    if (_showImmediateFeedback && !_showingFeedback) {
      setState(() {
        _questionsFeedbackShown[questionId] = true;
      });
      
      // Save the answer in the repository
      await _saveAnswer(questionId, _currentAnswers);
      return;
    }

    await _goToNextQuestion();
  }

  /// Saves the current answer to the repository
  Future<void> _saveAnswer(String questionId, List<String> answerValues) async {
    try {
      await _repository.updateQuizAttempt(
        widget.attemptId,
        {questionId: answerValues},
      );
    } catch (e) {
      _showErrorSnackBar('Failed to save answer: $e');
    }
  }

  /// Moves to the next question or finishes the quiz
  Future<void> _goToNextQuestion() async {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      final nextIndex = _currentQuestionIndex + 1;
      
      setState(() {
        _currentQuestionIndex = nextIndex;
      });
      
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showFinishDialog();
    }
  }

  /// Moves to the previous question
  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      final prevIndex = _currentQuestionIndex - 1;
      
      setState(() {
        _currentQuestionIndex = prevIndex;
      });
      
      _pageController.animateToPage(
        prevIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Shows a dialog to confirm finishing the quiz
  void _showFinishDialog() {
    if (_isFinishDialogOpen) return;
    
    setState(() {
      _isFinishDialogOpen = true;
    });

    final int answeredCount = _answers.length;
    final int totalQuestions = widget.quiz.questionCount;
    final bool allAnswered = answeredCount == totalQuestions;

    showDialog(
      context: context,
      barrierDismissible: !_isSubmitting,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => !_isSubmitting,
          child: AlertDialog(
            title: const Text('Finish Quiz'),
            content: _isSubmitting
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Submitting your answers...'),
                    ],
                  )
                : Text(
                    allAnswered
                        ? 'Are you ready to submit your answers and finish the quiz?'
                        : 'You have answered $answeredCount out of $totalQuestions questions. Are you sure you want to finish?',
                  ),
            actions: _isSubmitting
                ? []
                : [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _isFinishDialogOpen = false;
                        });
                      },
                      child: const Text('Continue Quiz'),
                    ),
                    ElevatedButton(
                      onPressed: _finishQuiz,
                      child: const Text('Finish Quiz'),
                    ),
                  ],
          ),
        );
      },
    );
  }

  /// Finishes the quiz and navigates to the results screen
  Future<void> _finishQuiz() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final attempt = await _repository.completeQuizAttempt(
        widget.attemptId,
        _answers,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        
        // Navigate to results screen, replacing this screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultsScreen(
              attemptId: attempt.attemptId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        _showErrorSnackBar('Failed to finish quiz: $e');
        setState(() {
          _isSubmitting = false;
          _isFinishDialogOpen = false;
        });
      }
    }
  }

  /// Updates the answer for the current question
  void _onAnswerSelected(List<String> selectedValues) {
    setState(() {
      _answers[_currentQuestion.questionId] = selectedValues;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmQuit(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.quiz.questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionPage(widget.quiz.questions[index]);
                },
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ProgressIndicatorWidget(
        currentQuestionIndex: _currentQuestionIndex,
        totalQuestions: widget.quiz.questions.length,
      ),
    );
  }

  Widget _buildQuestionPage(Question question) {
    final answers = _answers[question.questionId] ?? [];
    final showingFeedback = _questionsFeedbackShown[question.questionId] ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuestionWidget(
            question: question,
            selectedOptionValues: answers,
            showCorrectness: showingFeedback,
            onAnswerSelected: _onAnswerSelected,
          ),
          if (showingFeedback) ...[
            const SizedBox(height: 24),
            FeedbackWidget(
              question: question,
              selectedOptionValues: answers,
            ),
          ],
          const SizedBox(height: 100), // Space for navigation buttons
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final bool hasAnswer = _currentAnswers.isNotEmpty;
    final bool isFirstQuestion = _currentQuestionIndex == 0;
    final bool isLastQuestion = _currentQuestionIndex == widget.quiz.questions.length - 1;
    final bool showingFeedback = _showingFeedback;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isFirstQuestion)
            OutlinedButton.icon(
              onPressed: _goToPreviousQuestion,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            )
          else
            const SizedBox(width: 100),
          ElevatedButton.icon(
            onPressed: hasAnswer ? _submitCurrentAnswer : null,
            icon: Icon(showingFeedback || !_showImmediateFeedback
                ? Icons.arrow_forward
                : Icons.check),
            label: Text(
              showingFeedback
                  ? (isLastQuestion ? 'Finish' : 'Next')
                  : (_showImmediateFeedback ? 'Check' : (isLastQuestion ? 'Finish' : 'Next')),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              minimumSize: const Size(120, 48),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmQuit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit Quiz'),
        content: const Text(
          'Are you sure you want to quit? Your progress will be saved, but the quiz will be marked as incomplete.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}