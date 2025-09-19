import 'package:flutter/material.dart';

import '../models/models.dart';

/// A widget that displays feedback for a quiz question after answering
class FeedbackWidget extends StatelessWidget {
  /// The question to display feedback for
  final Question question;
  
  /// The selected answer option values
  final List<String> selectedOptionValues;

  const FeedbackWidget({
    Key? key,
    required this.question,
    required this.selectedOptionValues,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isCorrect = question.areAnswersCorrect(selectedOptionValues);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultHeader(context, isCorrect),
        const SizedBox(height: 16),
        _buildExplanation(context),
      ],
    );
  }

  Widget _buildResultHeader(BuildContext context, bool isCorrect) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            isCorrect ? 'Correct!' : 'Incorrect',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explanation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            question.explanation,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (_shouldShowCorrectAnswers()) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Correct Answer${question.correctOptions.length > 1 ? 's' : ''}:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ..._buildCorrectAnswers(context),
          ],
        ],
      ),
    );
  }

  bool _shouldShowCorrectAnswers() {
    return !question.areAnswersCorrect(selectedOptionValues);
  }

  List<Widget> _buildCorrectAnswers(BuildContext context) {
    final correctOptions = question.correctOptions;
    return correctOptions
        .map((option) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(option.displayText),
                  ),
                ],
              ),
            ))
        .toList();
  }
}