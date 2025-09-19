import 'package:flutter/material.dart';
import '../models/educational_content.dart';
import '../models/education_category.dart';

class EducationContentCard extends StatelessWidget {
  final EducationalContent content;
  final VoidCallback onTap;
  final VoidCallback onSaveTap;
  
  const EducationContentCard({
    Key? key,
    required this.content,
    required this.onTap,
    required this.onSaveTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: _getCategoryColor(content.category).withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildCategoryIcon(),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      content.category.name,
                      style: TextStyle(
                        color: _getCategoryColor(content.category),
                        fontWeight: FontWeight.w500,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                  if (content.isRead)
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16.0,
                      color: Colors.grey,
                    ),
                  IconButton(
                    icon: Icon(
                      content.isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: content.isSaved ? Colors.amber : Colors.grey,
                    ),
                    onPressed: onSaveTap,
                    tooltip: content.isSaved ? 'Remove from saved' : 'Save for later',
                    iconSize: 20.0,
                    splashRadius: 24.0,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Text(
                content.title,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                _truncateText(content.body, 100),
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16.0),
              _buildActionableSteps(),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    ),
                    child: Row(
                      children: const [
                        Text('Read more'),
                        SizedBox(width: 4.0),
                        Icon(Icons.arrow_forward, size: 16.0),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: _getCategoryColor(content.category).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(
        _getCategoryIcon(content.category),
        color: _getCategoryColor(content.category),
        size: 16.0,
      ),
    );
  }
  
  Widget _buildActionableSteps() {
    if (content.actionableSteps.isEmpty) return const SizedBox.shrink();
    
    // Show just first actionable step in the card
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16.0,
            color: Colors.green,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              content.actionableSteps.first,
              style: const TextStyle(fontSize: 12.0),
            ),
          ),
          if (content.actionableSteps.length > 1)
            Text(
              '+${content.actionableSteps.length - 1} more',
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to get color for a category
  Color _getCategoryColor(EducationCategory category) {
    switch (category) {
      case EducationCategory.dietNutrition:
        return Colors.green;
      case EducationCategory.physicalActivity:
        return Colors.blue;
      case EducationCategory.stressManagement:
        return Colors.purple;
      case EducationCategory.smokingCessation:
        return Colors.orange;
      case EducationCategory.generalWellness:
        return Colors.teal;
    }
  }
  
  // Helper method to get icon for a category
  IconData _getCategoryIcon(EducationCategory category) {
    switch (category) {
      case EducationCategory.dietNutrition:
        return Icons.restaurant;
      case EducationCategory.physicalActivity:
        return Icons.fitness_center;
      case EducationCategory.stressManagement:
        return Icons.spa;
      case EducationCategory.smokingCessation:
        return Icons.smoke_free;
      case EducationCategory.generalWellness:
        return Icons.favorite;
    }
  }
  
  // Helper method to truncate long text
  String _truncateText(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}...';
  }
}