import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';
import '../widgets/widgets.dart';

/// A simplified screen that displays basic quiz results
class QuizResultsScreen extends StatelessWidget {
  /// The ID of the attempt to show results for
  final String attemptId;

  const QuizResultsScreen({
    Key? key,
    required this.attemptId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<QuizRepository>(context, listen: false);
    
    return FutureBuilder<QuizAttempt>(
      future: repository.getAttemptById(attemptId),
      builder: (context, attemptSnapshot) {
        if (attemptSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quiz Results')),
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (attemptSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Error: ${attemptSnapshot.error}')),
          );
        }
        
        final attempt = attemptSnapshot.data!;
        
        return FutureBuilder<Quiz>(
          future: repository.getQuizById(attempt.quizId),
          builder: (context, quizSnapshot) {
            if (quizSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: AppBar(title: const Text('Quiz Results')),
                body: const Center(child: CircularProgressIndicator()),
              );
            } else if (quizSnapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(child: Text('Error: ${quizSnapshot.error}')),
              );
            }
            
            final quiz = quizSnapshot.data!;
            return _buildResultsScreen(context, quiz, attempt);
          },
        );
      },
    );
  }
  
  Widget _buildResultsScreen(BuildContext context, Quiz quiz, QuizAttempt attempt) {
    final score = (attempt.score * 100).round();
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with pass/fail status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: attempt.passed ? Colors.green[700] : Colors.red[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    attempt.passed ? 'PASSED' : 'FAILED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quiz.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Score circle
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[100],
                  border: Border.all(
                    color: attempt.passed ? Colors.green[700]! : Colors.red[700]!,
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$score%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: attempt.passed ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quiz details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      label: 'Correct Answers',
                      value: '${(attempt.score * quiz.questions.length).round()}/${quiz.questions.length}',
                      icon: Icons.check_circle_outline,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      label: 'Passing Score',
                      value: '${quiz.passingScore}%',
                      icon: Icons.done_all,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      label: 'Time Taken',
                      value: _formatDuration(attempt),
                      icon: Icons.timer,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      label: 'Started',
                      value: dateFormat.format(attempt.dateStarted),
                      icon: Icons.play_circle_outline,
                    ),
                    if (attempt.dateCompleted != null) ...[
                      const Divider(),
                      _buildInfoRow(
                        label: 'Completed',
                        value: dateFormat.format(attempt.dateCompleted!),
                        icon: Icons.event_available,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Take new quiz button
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Take Another Quiz'),
              onPressed: () {
                // Pop back to quizzes screen
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/quizzes');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(QuizAttempt attempt) {
    if (attempt.dateCompleted == null) return 'In progress';
    
    final duration = attempt.dateCompleted!.difference(attempt.dateStarted);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}