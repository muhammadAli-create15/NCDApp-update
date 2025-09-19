import 'package:flutter/material.dart';

import '../models/models.dart';
import 'question_widget.dart';

/// Widget for multiple-choice questions
class MultipleChoiceQuestionWidget extends QuestionWidget {
  const MultipleChoiceQuestionWidget({
    Key? key,
    required Question question,
    List<dynamic>? value,
    required Function(dynamic value) onChanged,
  }) : super(
          key: key,
          question: question,
          value: value,
          onChanged: onChanged,
        );

  @override
  State<MultipleChoiceQuestionWidget> createState() => _MultipleChoiceQuestionWidgetState();
}

class _MultipleChoiceQuestionWidgetState extends State<MultipleChoiceQuestionWidget> {
  late List<dynamic> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = List<dynamic>.from(widget.value ?? []);
  }

  @override
  void didUpdateWidget(MultipleChoiceQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _selectedValues = List<dynamic>.from(widget.value ?? []);
    }
  }

  void _toggleValue(dynamic value) {
    setState(() {
      if (_selectedValues.contains(value)) {
        _selectedValues.remove(value);
      } else {
        _selectedValues.add(value);
      }
    });
    widget.onChanged(_selectedValues);
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
        const SizedBox(height: 8.0),
        Text(
          'Select all that apply',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 12.0),
        ...widget.question.options.map((option) => _buildOptionTile(option)),
      ],
    );
  }

  Widget _buildOptionTile(Option option) {
    final bool isSelected = _selectedValues.contains(option.value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          onTap: () => _toggleValue(option.value),
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                width: isSelected ? 2.0 : 1.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                if (option.icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Icon(
                      IconData(
                        int.parse(option.icon!),
                        fontFamily: 'MaterialIcons',
                      ),
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                    ),
                  ),
                Expanded(
                  child: Text(
                    option.displayText,
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) {
                    if (value != null) {
                      _toggleValue(option.value);
                    }
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}