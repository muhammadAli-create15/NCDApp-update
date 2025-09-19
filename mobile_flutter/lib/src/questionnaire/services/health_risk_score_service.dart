import '../models/models.dart';
import '../models/score_interpretation.dart';

/// Service for converting questionnaire results to health risk scores
/// This service helps integrate questionnaire results with the risk assessment component
class HealthRiskScoreService {
  /// Map of questionnaire ID to risk factor ID
  final Map<String, String> _questionnaireToRiskFactor;
  
  /// Map of questionnaire ID to score interpretations
  final Map<String, List<ScoreInterpretation>> _interpretations;
  
  /// Constructor for the HealthRiskScoreService
  HealthRiskScoreService({
    Map<String, String>? questionnaireToRiskFactor,
    Map<String, List<ScoreInterpretation>>? interpretations,
  }) : 
    _questionnaireToRiskFactor = questionnaireToRiskFactor ?? _defaultMapping,
    _interpretations = interpretations ?? _defaultInterpretations;
  
  /// Convert a questionnaire response to a risk level
  String getRiskFactor(String questionnaireId) {
    return _questionnaireToRiskFactor[questionnaireId] ?? 'general';
  }
  
  /// Get the interpretation for a questionnaire score
  String getInterpretation(String questionnaireId, double score) {
    final interpretations = _interpretations[questionnaireId] ?? [];
    
    for (final interpretation in interpretations) {
      if (interpretation.includesScore(score)) {
        return interpretation.label;
      }
    }
    
    return 'Unknown';
  }
  
  /// Get the detailed description for a questionnaire score
  String getDescription(String questionnaireId, double score) {
    final interpretations = _interpretations[questionnaireId] ?? [];
    
    for (final interpretation in interpretations) {
      if (interpretation.includesScore(score)) {
        return interpretation.description;
      }
    }
    
    return 'No description available';
  }
  
  /// Get the color code for a questionnaire score
  String? getColorCode(String questionnaireId, double score) {
    final interpretations = _interpretations[questionnaireId] ?? [];
    
    for (final interpretation in interpretations) {
      if (interpretation.includesScore(score)) {
        return interpretation.colorCode;
      }
    }
    
    return null;
  }
  
  /// Default mapping of questionnaire IDs to risk factors
  static const Map<String, String> _defaultMapping = {
    'who_heart_risk': 'cardiovascular',
    'findrisc': 'diabetes',
    'ipaq': 'physical_activity',
    'predimed': 'diet',
    'phq9': 'depression',
    'gad7': 'anxiety',
    'family_history': 'genetic',
    'smoking_assessment': 'smoking',
    'alcohol_audit': 'alcohol',
  };
  
  /// Default interpretation ranges for different questionnaires
  static final Map<String, List<ScoreInterpretation>> _defaultInterpretations = {
    'who_heart_risk': [
      ScoreInterpretation(
        minScore: 0,
        maxScore: 5,
        label: 'Low Risk',
        description: 'Your cardiovascular risk appears to be low based on your answers.',
        colorCode: '#4CAF50', // Green
      ),
      ScoreInterpretation(
        minScore: 6,
        maxScore: 10,
        label: 'Moderate Risk',
        description: 'Your cardiovascular risk appears to be moderate. Consider discussing with your healthcare provider.',
        colorCode: '#FFC107', // Amber
      ),
      ScoreInterpretation(
        minScore: 11,
        maxScore: 20,
        label: 'High Risk',
        description: 'Your cardiovascular risk appears to be high. It is recommended that you consult with a healthcare provider.',
        colorCode: '#FF5722', // Deep Orange
      ),
    ],
    'findrisc': [
      ScoreInterpretation(
        minScore: 0,
        maxScore: 7,
        label: 'Low Risk',
        description: 'Your risk of developing type 2 diabetes within the next 10 years is estimated to be low (1 in 100).',
        colorCode: '#4CAF50', // Green
      ),
      ScoreInterpretation(
        minScore: 8,
        maxScore: 11,
        label: 'Slightly Elevated Risk',
        description: 'Your risk of developing type 2 diabetes within the next 10 years is estimated to be slightly elevated (1 in 25).',
        colorCode: '#8BC34A', // Light Green
      ),
      ScoreInterpretation(
        minScore: 12,
        maxScore: 14,
        label: 'Moderate Risk',
        description: 'Your risk of developing type 2 diabetes within the next 10 years is estimated to be moderate (1 in 6).',
        colorCode: '#FFC107', // Amber
      ),
      ScoreInterpretation(
        minScore: 15,
        maxScore: 20,
        label: 'High Risk',
        description: 'Your risk of developing type 2 diabetes within the next 10 years is estimated to be high (1 in 3).',
        colorCode: '#FF5722', // Deep Orange
      ),
      ScoreInterpretation(
        minScore: 21,
        maxScore: 26,
        label: 'Very High Risk',
        description: 'Your risk of developing type 2 diabetes within the next 10 years is estimated to be very high (1 in 2).',
        colorCode: '#F44336', // Red
      ),
    ],
    'phq9': [
      ScoreInterpretation(
        minScore: 0,
        maxScore: 4,
        label: 'Minimal Depression',
        description: 'Your symptoms suggest minimal or no depression.',
        colorCode: '#4CAF50', // Green
      ),
      ScoreInterpretation(
        minScore: 5,
        maxScore: 9,
        label: 'Mild Depression',
        description: 'Your symptoms suggest mild depression. Consider discussing with a healthcare provider if symptoms persist.',
        colorCode: '#8BC34A', // Light Green
      ),
      ScoreInterpretation(
        minScore: 10,
        maxScore: 14,
        label: 'Moderate Depression',
        description: 'Your symptoms suggest moderate depression. It is recommended to consult with a healthcare provider.',
        colorCode: '#FFC107', // Amber
      ),
      ScoreInterpretation(
        minScore: 15,
        maxScore: 19,
        label: 'Moderately Severe Depression',
        description: 'Your symptoms suggest moderately severe depression. Please consult with a healthcare provider.',
        colorCode: '#FF5722', // Deep Orange
      ),
      ScoreInterpretation(
        minScore: 20,
        maxScore: 27,
        label: 'Severe Depression',
        description: 'Your symptoms suggest severe depression. Please seek immediate help from a healthcare provider.',
        colorCode: '#F44336', // Red
      ),
    ],
  };
}