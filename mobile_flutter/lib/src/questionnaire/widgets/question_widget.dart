import 'package:flutter/material.dart';

import '../models/models.dart';
import 'boolean_question_widget.dart';
import 'multiple_choice_question_widget.dart';
import 'numerical_question_widget.dart';
import 'scale_question_widget.dart';
import 'single_choice_question_widget.dart';
import 'text_question_widget.dart';

/// Base class for question widgets
abstract class QuestionWidget extends StatefulWidget {
  final Question question;
  final dynamic value;
  final Function(dynamic value) onChanged;
  
  const QuestionWidget({
    Key? key,
    required this.question,
    this.value,
    required this.onChanged,
  }) : super(key: key);
}

/// Factory for creating the appropriate question widget based on question type
class QuestionWidgetFactory {
  static Widget createQuestionWidget({
    required Question question,
    dynamic value,
    required Function(dynamic) onChanged,
  }) {
    switch (question.type) {
      case QuestionType.boolean:
        return BooleanQuestionWidget(
          question: question,
          value: value,
          onChanged: onChanged,
        );
      case QuestionType.singleChoice:
        return SingleChoiceQuestionWidget(
          question: question,
          value: value,
          onChanged: onChanged,
        );
      case QuestionType.multipleChoice:
        return MultipleChoiceQuestionWidget(
          question: question,
          value: value as List<dynamic>?,
          onChanged: onChanged,
        );
      case QuestionType.numerical:
        return NumericalQuestionWidget(
          question: question,
          value: value,
          onChanged: onChanged,
        );
      case QuestionType.scale:
        return ScaleQuestionWidget(
          question: question,
          value: value,
          onChanged: onChanged,
        );
      case QuestionType.text:
        return TextQuestionWidget(
          question: question,
          value: value,
          onChanged: onChanged,
        );
    }
  }
}