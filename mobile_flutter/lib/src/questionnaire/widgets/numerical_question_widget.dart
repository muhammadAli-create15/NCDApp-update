import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import 'question_widget.dart';

/// Widget for numerical input questions
class NumericalQuestionWidget extends QuestionWidget {
  const NumericalQuestionWidget({
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
  State<NumericalQuestionWidget> createState() => _NumericalQuestionWidgetState();
}

class _NumericalQuestionWidgetState extends State<NumericalQuestionWidget> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value != null ? widget.value.toString() : '',
    );
  }

  @override
  void didUpdateWidget(NumericalQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value != null ? widget.value.toString() : '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndUpdate(String value) {
    if (value.isEmpty) {
      _errorText = widget.question.required ? 'This field is required' : null;
      widget.onChanged(null);
      return;
    }

    try {
      final num parsedValue = num.parse(value);
      
      // Validate min/max if specified
      if (widget.question.minValue != null && parsedValue < widget.question.minValue!) {
        _errorText = 'Value must be at least ${widget.question.minValue}';
      } else if (widget.question.maxValue != null && parsedValue > widget.question.maxValue!) {
        _errorText = 'Value must be at most ${widget.question.maxValue}';
      } else {
        _errorText = null;
        widget.onChanged(parsedValue);
      }
    } catch (e) {
      _errorText = 'Please enter a valid number';
      widget.onChanged(null);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 16.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
                decoration: InputDecoration(
                  labelText: 'Enter a number',
                  errorText: _errorText,
                  border: const OutlineInputBorder(),
                ),
                onChanged: _validateAndUpdate,
              ),
            ),
            if (widget.question.unit != null)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 12.0),
                child: Text(
                  widget.question.unit!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
          ],
        ),
        if (widget.question.minValue != null && widget.question.maxValue != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Valid range: ${widget.question.minValue} - ${widget.question.maxValue} ${widget.question.unit ?? ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
      ],
    );
  }
}