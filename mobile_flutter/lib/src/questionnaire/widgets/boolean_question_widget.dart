import 'package:flutter/material.dart';

import '../models/models.dart';
import 'question_widget.dart';

/// Widget for boolean (yes/no) questions
class BooleanQuestionWidget extends QuestionWidget {
  const BooleanQuestionWidget({
    Key? key,
    required Question question,
    bool? value,
    required Function(dynamic value) onChanged,
  }) : super(
          key: key,
          question: question,
          value: value,
          onChanged: onChanged,
        );

  @override
  State<BooleanQuestionWidget> createState() => _BooleanQuestionWidgetState();
}

class _BooleanQuestionWidgetState extends State<BooleanQuestionWidget> {
  late bool? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value as bool?;
  }

  @override
  void didUpdateWidget(BooleanQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _value = widget.value as bool?;
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
        Row(
          children: [
            Expanded(
              child: _buildOptionButton(
                text: 'Yes',
                isSelected: _value == true,
                onTap: () {
                  setState(() {
                    _value = true;
                  });
                  widget.onChanged(_value);
                },
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: _buildOptionButton(
                text: 'No',
                isSelected: _value == false,
                onTap: () {
                  setState(() {
                    _value = false;
                  });
                  widget.onChanged(_value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
      borderRadius: BorderRadius.circular(8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}