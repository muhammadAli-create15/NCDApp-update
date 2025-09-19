import 'package:flutter/material.dart';

import '../models/models.dart';
import 'question_widget.dart';

/// Widget for scale selection questions
class ScaleQuestionWidget extends QuestionWidget {
  const ScaleQuestionWidget({
    Key? key,
    required Question question,
    dynamic value,
    required Function(dynamic value) onChanged,
  }) : super(
          key: key,
          question: question,
          value: value,
          onChanged: onChanged,
        );

  @override
  State<ScaleQuestionWidget> createState() => _ScaleQuestionWidgetState();
}

class _ScaleQuestionWidgetState extends State<ScaleQuestionWidget> {
  @override
  Widget build(BuildContext context) {
    // Default min and max values if not specified
    final minValue = widget.question.minValue?.toDouble() ?? 0.0;
    final maxValue = widget.question.maxValue?.toDouble() ?? 10.0;
    
    // Current value with bounds checking
    final currentValue = widget.value != null 
      ? widget.value.toDouble().clamp(minValue, maxValue) 
      : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.question.text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (widget.question.subText != null && widget.question.subText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              widget.question.subText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
        const SizedBox(height: 24.0),
        Row(
          children: [
            Text(minValue.toInt().toString()),
            Expanded(
              child: Slider(
                value: currentValue ?? minValue,
                min: minValue,
                max: maxValue,
                divisions: (maxValue - minValue).toInt(),
                label: currentValue?.toInt().toString() ?? '',
                onChanged: (value) {
                  widget.onChanged(value);
                },
              ),
            ),
            Text(maxValue.toInt().toString()),
          ],
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Text(
              currentValue != null 
                ? currentValue.toInt().toString() 
                : widget.question.required ? 'Select a value' : 'Optional',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        if (widget.question.unit != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                widget.question.unit!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
      ],
    );
  }
}