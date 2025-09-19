import 'package:flutter/material.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';
import 'quiz_session_screen.dart';

/// Screen that displays details about a quiz and allows starting it
class QuizDetailScreen extends StatefulWidget {
  /// The quiz to display
  final Quiz quiz;

  const QuizDetailScreen({
    Key? key,
    required this.quiz,
  }) : super(key: key);

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  final QuizRepository _repository = MockQuizRepository();
  List<QuizAttempt> _attempts = [];
  bool _isLoading = true;
  bool _isStartingQuiz = false;

  // Mock user ID (would come from auth system)
  final String _userId = 'user123';

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final attempts = await _repository.getUserAttemptsForQuiz(
        _userId,
        widget.quiz.quizId,
      );

      setState(() {
        _attempts = attempts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load attempts: $e');
    }
  }

  Future<void> _startQuiz() async {
    setState(() {
      _isStartingQuiz = true;
    });

    try {
      final attempt = await _repository.startQuizAttempt(
        _userId,
        widget.quiz.quizId,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizSessionScreen(
              quiz: widget.quiz,
              attemptId: attempt.attemptId,
            ),
          ),
        ).then((_) {
          _loadAttempts(); // Reload attempts when returning
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to start quiz: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isStartingQuiz = false;
        });
      }
    }
  }

  bool _canTakeQuiz() {
    if (widget.quiz.maxAttempts == null) {
      return true;
    }
    return _attempts.length < widget.quiz.maxAttempts!;
  }

  bool _hasPassed() {
    return _attempts.any((attempt) => attempt.passed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.category.displayName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuizHeader(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuizInfo(),
                        const SizedBox(height: 24),
                        _buildDescription(),
                        const SizedBox(height: 24),
                        _buildAttemptsSection(),
                        const SizedBox(height: 32),
                        _buildStartButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuizHeader() {
    return Container(
      width: double.infinity,
      color: _getCategoryColor(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.quiz.difficulty.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.quiz.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_hasPassed()) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'PASSED',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizInfo() {
    return Row(
      children: [
        _buildInfoItem(
          icon: Icons.quiz_outlined,
          label: '${widget.quiz.questionCount} Questions',
        ),
        _buildInfoItem(
          icon: Icons.check_circle_outline,
          label: '${widget.quiz.passingScore}% to Pass',
        ),
        if (widget.quiz.maxAttempts != null)
          _buildInfoItem(
            icon: Icons.replay,
            label: '${widget.quiz.maxAttempts} Attempts',
          ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this Quiz',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.quiz.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'Version: ${widget.quiz.version}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildAttemptsSection() {
    if (_attempts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Previous Attempts',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _attempts.length,
          itemBuilder: (context, index) {
            return _buildAttemptItem(_attempts[index]);
          },
        ),
      ],
    );
  }

  Widget _buildAttemptItem(QuizAttempt attempt) {
    final dateString = _formatDate(attempt.dateStarted);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          attempt.passed ? Icons.check_circle : Icons.info_outline,
          color: attempt.passed ? Colors.green : Colors.orange,
        ),
        title: Text(
          dateString,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: attempt.dateCompleted != null
            ? Text('Score: ${attempt.score.toInt()}% • ${attempt.formattedDuration}')
            : const Text('Incomplete'),
        trailing: attempt.passed
            ? const Icon(Icons.emoji_events, color: Colors.amber)
            : null,
      ),
    );
  }

  Widget _buildStartButton() {
    final bool canTake = _canTakeQuiz();
    
    return Center(
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: canTake && !_isStartingQuiz ? _startQuiz : null,
            icon: _isStartingQuiz
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(
              _isStartingQuiz ? 'Starting...' : 'Start Quiz',
              style: const TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              minimumSize: const Size(200, 50),
            ),
          ),
          if (!canTake) ...[
            const SizedBox(height: 8),
            Text(
              'You\'ve reached the maximum number of attempts.',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    switch (widget.quiz.category) {
      case QuizCategory.diabetes:
        return Colors.blue[700]!;
      case QuizCategory.hypertension:
        return Colors.red[700]!;
      case QuizCategory.kidney:
        return Colors.purple[700]!;
      case QuizCategory.generalNcd:
        return Colors.green[700]!;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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