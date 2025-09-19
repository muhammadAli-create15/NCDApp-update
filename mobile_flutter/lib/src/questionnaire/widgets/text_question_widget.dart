import 'package:flutter/material.dart';

import '../models/models.dart';
import 'question_widget.dart';

/// Widget for text input questions
class TextQuestionWidget extends QuestionWidget {
  const TextQuestionWidget({
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
  State<TextQuestionWidget> createState() => _TextQuestionWidgetState();
}

class _TextQuestionWidgetState extends State<TextQuestionWidget> {
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
  void didUpdateWidget(TextQuestionWidget oldWidget) {
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
    if (value.isEmpty && widget.question.required) {
      setState(() {
        _errorText = 'This field is required';
      });
      widget.onChanged(null);
    } else {
      setState(() {
        _errorText = null;
      });
      widget.onChanged(value.isEmpty ? null : value);
    }
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
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Enter your answer',
            errorText: _errorText,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          textInputAction: TextInputAction.done,
          onChanged: _validateAndUpdate,
        ),
      ],
    );
  }
}