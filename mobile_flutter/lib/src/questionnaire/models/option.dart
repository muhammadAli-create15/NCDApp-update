/// Represents an answer option for a question in a questionnaire
class Option {
  /// The underlying value of the option (e.g., true, "yes", 1)
  final dynamic value;
  
  /// The display text shown to the user (e.g., "Yes", "No", "Not Sure")
  final String displayText;
  
  /// Optional reference to an icon for visual representation
  final String? icon;
  
  /// Constructor for the Option class
  Option({
    required this.value,
    required this.displayText,
    this.icon,
  });
  
  /// Create an Option from JSON
  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      value: json['value'],
      displayText: json['displayText'],
      icon: json['icon'],
    );
  }
  
  /// Convert Option to JSON
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'displayText': displayText,
      if (icon != null) 'icon': icon,
    };
  }
  
  @override
  String toString() {
    return 'Option{value: $value, displayText: $displayText, icon: $icon}';
  }
  
  /// Creates a copy of this Option with the given field values overridden
  Option copyWith({
    dynamic value,
    String? displayText,
    String? icon,
  }) {
    return Option(
      value: value ?? this.value,
      displayText: displayText ?? this.displayText,
      icon: icon ?? this.icon,
    );
  }
}