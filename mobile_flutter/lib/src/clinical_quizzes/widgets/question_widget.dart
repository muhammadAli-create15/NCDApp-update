import 'package:flutter/material.dart';

import '../models/models.dart';
import 'option_widget.dart';

/// A widget that displays a quiz question with its answer options
class QuestionWidget extends StatefulWidget {
  /// The question to display
  final Question question;
  
  /// The currently selected option values
  final List<String> selectedOptionValues;
  
  /// Whether to show if the answers are correct (feedback mode)
  final bool showCorrectness;
  
  /// Callback when the selected options change
  final Function(List<String>) onAnswerSelected;

  const QuestionWidget({
    Key? key,
    required this.question,
    required this.selectedOptionValues,
    this.showCorrectness = false,
    required this.onAnswerSelected,
  }) : super(key: key);

  @override
  State<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestionText(),
        if (widget.question.imageUrl != null) _buildImage(),
        const SizedBox(height: 16),
        _buildOptions(),
      ],
    );
  }

  Widget _buildQuestionText() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        widget.question.text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          widget.question.imageUrl!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return Column(
      children: widget.question.options
          .map((option) => OptionWidget(
                option: option,
                isSelected: widget.selectedOptionValues.contains(option.value),
                showCorrectness: widget.showCorrectness,
                onSelect: () => _handleOptionSelected(option),
              ))
          .toList(),
    );
  }

  void _handleOptionSelected(Option option) {
    if (widget.showCorrectness) {
      // If showing correctness, don't allow changing answers
      return;
    }

    List<String> newSelectedValues;

    if (widget.question.type.allowsMultipleAnswers) {
      // For multiple choice questions, toggle the selection
      if (widget.selectedOptionValues.contains(option.value)) {
        newSelectedValues = List.from(widget.selectedOptionValues)
          ..remove(option.value);
      } else {
        newSelectedValues = List.from(widget.selectedOptionValues)
          ..add(option.value);
      }
    } else {
      // For single choice questions, select only this option
      newSelectedValues = [option.value];
    }

    widget.onAnswerSelected(newSelectedValues);
  }
}