/// Defines the different categories for health educational content
enum EducationCategory {
  dietNutrition(
    id: 'diet_nutrition',
    name: 'Diet & Nutrition',
    icon: 'food_bank',
  ),
  
  physicalActivity(
    id: 'physical_activity',
    name: 'Physical Activity',
    icon: 'fitness_center',
  ),
  
  stressManagement(
    id: 'stress_management',
    name: 'Stress Management',
    icon: 'spa',
  ),
  
  smokingCessation(
    id: 'smoking_cessation',
    name: 'Smoking Cessation',
    icon: 'smoke_free',
  ),
  
  generalWellness(
    id: 'general_wellness',
    name: 'General Wellness',
    icon: 'favorite',
  );
  
  final String id;
  final String name;
  final String icon;
  
  const EducationCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
  
  /// Find category by ID
  static EducationCategory? fromId(String id) {
    return EducationCategory.values.firstWhere(
      (category) => category.id == id,
      orElse: () => EducationCategory.generalWellness,
    );
  }
}