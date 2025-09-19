/// Represents an answer option for a quiz question
class Option {
  /// The underlying value of the option, used for storing answers
  final String value;
  
  /// The text displayed to the user for this option
  final String displayText;
  
  /// Whether this option is a correct answer
  final bool isCorrect;

  const Option({
    required this.value,
    required this.displayText,
    required this.isCorrect,
  });

  /// Creates an Option from a JSON object
  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      value: json['value'] as String,
      displayText: json['displayText'] as String,
      isCorrect: json['isCorrect'] as bool,
    );
  }

  /// Converts this Option to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'displayText': displayText,
      'isCorrect': isCorrect,
    };
  }

  /// Creates a copy of this Option with the given fields replaced
  Option copyWith({
    String? value,
    String? displayText,
    bool? isCorrect,
  }) {
    return Option(
      value: value ?? this.value,
      displayText: displayText ?? this.displayText,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Option &&
        other.value == value &&
        other.displayText == displayText &&
        other.isCorrect == isCorrect;
  }

  @override
  int get hashCode => Object.hash(value, displayText, isCorrect);
}