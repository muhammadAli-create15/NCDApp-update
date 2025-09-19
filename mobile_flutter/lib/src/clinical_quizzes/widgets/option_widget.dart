import 'package:flutter/material.dart';

import '../models/models.dart';

/// A widget to display a quiz answer option
class OptionWidget extends StatelessWidget {
  /// The option to display
  final Option option;
  
  /// Whether this option is selected
  final bool isSelected;
  
  /// Whether to show if this option is correct (for feedback)
  final bool showCorrectness;
  
  /// Callback when the option is selected
  final VoidCallback onSelect;

  const OptionWidget({
    Key? key,
    required this.option,
    required this.isSelected,
    this.showCorrectness = false,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    final icon = _getIcon();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color.withOpacity(isSelected ? 0.2 : 0.05),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: color,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                icon != null
                    ? Icon(
                        icon,
                        color: color,
                        size: 20,
                      )
                    : Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: color,
                            width: 2,
                          ),
                          color: isSelected ? color : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.displayText,
                    style: TextStyle(
                      color: isSelected ? color : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColor(BuildContext context) {
    if (!showCorrectness) {
      return isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    }

    if (option.isCorrect) {
      return Colors.green;
    } else {
      return isSelected ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    }
  }

  IconData? _getIcon() {
    if (!showCorrectness) {
      return null;
    }

    if (option.isCorrect) {
      return Icons.check_circle;
    } else if (isSelected) {
      return Icons.cancel;
    }
    
    return null;
  }
}