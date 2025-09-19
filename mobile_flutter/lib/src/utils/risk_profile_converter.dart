import '../models/risk_factor.dart';
import '../models/risk_level.dart';
import '../models/user_risk_profile.dart';

/// Utility class to convert between different risk representation models
class RiskProfileConverter {
  /// Convert a list of risk factors to a UserRiskProfile
  static UserRiskProfile fromRiskFactors(
    String userId,
    List<RiskFactor> riskFactors,
    RiskLevel overallRisk,
  ) {
    // Create a map of specific risk factors
    final specificRiskFactors = <String, RiskLevel>{};
    
    // Convert each risk factor to entry in the map
    for (final factor in riskFactors) {
      specificRiskFactors[factor.id] = factor.riskLevel;
    }
    
    // Get the latest updated date from risk factors or use current time
    final lastUpdated = riskFactors.isNotEmpty
        ? riskFactors
            .map((factor) => factor.lastUpdated)
            .reduce((a, b) => a.isAfter(b) ? a : b)
        : DateTime.now();
    
    // Create and return the user risk profile
    return UserRiskProfile(
      userId: userId,
      overallRiskLevel: overallRisk,
      specificRiskFactors: specificRiskFactors,
      lastUpdated: lastUpdated,
    );
  }
}