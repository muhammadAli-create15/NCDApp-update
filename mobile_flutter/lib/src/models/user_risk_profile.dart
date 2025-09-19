import 'risk_level.dart';

/// Represents a user's health risk profile based on the risk assessment
class UserRiskProfile {
  /// User's unique identifier
  final String userId;
  
  /// The overall risk level across all factors
  final RiskLevel overallRiskLevel;
  
  /// A key-value pair where key is a risk factor ID and value is its calculated RiskLevel
  final Map<String, RiskLevel> specificRiskFactors;
  
  /// When the risk profile was last calculated
  final DateTime lastUpdated;
  
  UserRiskProfile({
    required this.userId,
    required this.overallRiskLevel,
    required this.specificRiskFactors,
    required this.lastUpdated,
  });
  
  /// Create from JSON map (e.g. from remote database or local storage)
  factory UserRiskProfile.fromJson(Map<String, dynamic> json) {
    // Parse the specificRiskFactors map
    final specificRiskFactorsRaw = json['specificRiskFactors'] as Map<String, dynamic>;
    final specificRiskFactors = <String, RiskLevel>{};
    
    specificRiskFactorsRaw.forEach((key, value) {
      final riskLevel = RiskLevel.values.firstWhere(
        (level) => level.level == value,
        orElse: () => RiskLevel.normal,
      );
      specificRiskFactors[key] = riskLevel;
    });
    
    return UserRiskProfile(
      userId: json['userId'] as String,
      overallRiskLevel: RiskLevel.values.firstWhere(
        (level) => level.level == json['overallRiskLevel'],
        orElse: () => RiskLevel.normal,
      ),
      specificRiskFactors: specificRiskFactors,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    final specificRiskFactorsJson = <String, String>{};
    specificRiskFactors.forEach((key, value) {
      specificRiskFactorsJson[key] = value.level;
    });
    
    return {
      'userId': userId,
      'overallRiskLevel': overallRiskLevel.level,
      'specificRiskFactors': specificRiskFactorsJson,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  /// Get the risk level for a specific factor (returns normal if not found)
  RiskLevel getRiskLevelFor(String factorId) {
    return specificRiskFactors[factorId] ?? RiskLevel.normal;
  }
  
  /// Check if user has any high or very high risk factors
  bool hasHighRisks() {
    return specificRiskFactors.values.any((level) => 
      level == RiskLevel.high || level == RiskLevel.veryHigh);
  }
  
  /// Get a list of high-risk factor IDs
  List<String> getHighRiskFactorIds() {
    return specificRiskFactors.entries
      .where((entry) => entry.value == RiskLevel.high || entry.value == RiskLevel.veryHigh)
      .map((entry) => entry.key)
      .toList();
  }
}