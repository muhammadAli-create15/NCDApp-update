import 'package:flutter/material.dart';

import '../models/models.dart';

/// A card widget that displays a quiz summary and allows tapping to view details
class QuizCard extends StatelessWidget {
  /// The quiz to display
  final Quiz quiz;
  
  /// Callback when the card is tapped
  final VoidCallback onTap;
  
  /// Optional best score to display
  final double? bestScore;
  
  /// Whether the quiz has been passed by the user
  final bool isPassed;

  const QuizCard({
    Key? key,
    required this.quiz,
    required this.onTap,
    this.bestScore,
    this.isPassed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            _buildBody(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _getCategoryColor(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            _getCategoryIcon(),
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            quiz.category.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              quiz.difficulty.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quiz.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            quiz.description,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.quiz_outlined, size: 16),
              const SizedBox(width: 4),
              Text(
                '${quiz.questionCount} questions',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              const Icon(Icons.check_circle_outline, size: 16),
              const SizedBox(width: 4),
              Text(
                'Pass: ${quiz.passingScore}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (quiz.maxAttempts != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.repeat, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${quiz.maxAttempts} attempts',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (bestScore != null) ...[
            Text(
              'Best score: ${bestScore!.toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const Spacer(),
          ],
          if (isPassed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'PASSED',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            const Text(
              'TAP TO START',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    switch (quiz.category) {
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

  IconData _getCategoryIcon() {
    switch (quiz.category) {
      case QuizCategory.diabetes:
        return Icons.medical_services;
      case QuizCategory.hypertension:
        return Icons.favorite;
      case QuizCategory.kidney:
        return Icons.bloodtype;
      case QuizCategory.generalNcd:
        return Icons.health_and_safety;
    }
  }
}