import 'package:flutter/material.dart';

/// A widget that displays the progress through a quiz
class ProgressIndicatorWidget extends StatelessWidget {
  /// The current question index (0-based)
  final int currentQuestionIndex;
  
  /// The total number of questions
  final int totalQuestions;
  
  /// Whether to show the question numbers
  final bool showQuestionNumber;

  const ProgressIndicatorWidget({
    Key? key,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    this.showQuestionNumber = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = (currentQuestionIndex + 1) / totalQuestions;

    return Column(
      children: [
        if (showQuestionNumber)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Question ${currentQuestionIndex + 1} of $totalQuestions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                'Remaining: ${totalQuestions - currentQuestionIndex - 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}