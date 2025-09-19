import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../repositories/quiz_repository.dart';
import 'quiz_results_screen.dart';

/// Screen that displays a user's quiz attempt history
class QuizHistoryScreen extends StatelessWidget {
  /// Optional user ID. If not provided, will use the current user.
  final String? userId;

  /// Constructor
  const QuizHistoryScreen({
    Key? key,
    this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Try to get the repository from Provider
    final repository = Provider.of<QuizRepository>(context, listen: false);
    final currentUserId = userId ?? 'user123'; // Use provided userId or default
    
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz History')),
      body: StreamBuilder<void>(
        stream: repository.onQuizDataChanged,
        builder: (context, _) {
          return FutureBuilder<List<QuizAttempt>>(
            future: repository.getUserAttempts(currentUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No quiz history found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.library_books),
                        label: const Text('Go to Quiz Library'),
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/quizzes');
                        },
                      ),
                    ],
                  ),
                );
              }
              
              // Sort attempts by date (newest first)
              final attempts = snapshot.data!;
              attempts.sort((a, b) => 
                (b.dateStarted).compareTo(a.dateStarted)
              );
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: attempts.length,
                itemBuilder: (context, index) {
                  final attempt = attempts[index];
                  return _buildAttemptCard(context, attempt, repository);
                },
              );
            },
          );
        }
      ),
    );
  }
  
  Widget _buildAttemptCard(
    BuildContext context, 
    QuizAttempt attempt,
    QuizRepository repository,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    
    return FutureBuilder<Quiz>(
      future: repository.getQuizById(attempt.quizId),
      builder: (context, snapshot) {
        final quizTitle = snapshot.data?.title ?? 'Loading quiz...';
        final quizCategory = snapshot.data?.category.name ?? '';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              if (attempt.dateCompleted != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QuizResultsScreen(
                      attemptId: attempt.attemptId,
                    ),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          quizTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (attempt.dateCompleted != null) _buildScoreBadge(context, attempt),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quizCategory,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        attempt.dateCompleted != null
                            ? 'Completed ${dateFormat.format(attempt.dateCompleted!)}'
                            : 'Started ${dateFormat.format(attempt.dateStarted)} (In progress)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (attempt.dateCompleted != null)
                        Text(
                          attempt.passed ? 'PASSED' : 'FAILED',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: attempt.passed ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
  
  Widget _buildScoreBadge(BuildContext context, QuizAttempt attempt) {
    final score = (attempt.score * 100).round();
    
    Color badgeColor;
    if (score >= 80) {
      badgeColor = Colors.green[700]!;
    } else if (score >= 60) {
      badgeColor = Colors.orange[700]!;
    } else {
      badgeColor = Colors.red[700]!;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$score%',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}