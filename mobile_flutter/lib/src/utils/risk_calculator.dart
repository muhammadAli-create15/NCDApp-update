import 'package:flutter/material.dart';
import '../models/risk_level.dart';
import '../models/user_health_data.dart';
import '../models/risk_factor.dart';
import '../models/user_risk_profile.dart';

class RiskCalculator {
  // Calculate BMI risk level based on BMI value
  static RiskLevel calculateBMIRisk(double bmi) {
    if (bmi < 23) {
      return RiskLevel.normal;
    } else if (bmi >= 23 && bmi < 25) {
      return RiskLevel.moderate;
    } else if (bmi >= 25 && bmi < 30) {
      return RiskLevel.high;
    } else {
      return RiskLevel.veryHigh;
    }
  }

  // Calculate LDL Cholesterol risk
  static RiskLevel calculateLDLCholesterolRisk(double ldl) {
    if (ldl < 100) {
      return RiskLevel.normal;
    } else if (ldl >= 100 && ldl < 130) {
      return RiskLevel.moderate;
    } else if (ldl >= 130 && ldl < 160) {
      return RiskLevel.high;
    } else {
      return RiskLevel.veryHigh;
    }
  }

  // Calculate HDL Cholesterol risk (lower is worse for HDL)
  static RiskLevel calculateHDLCholesterolRisk(double hdl, Gender? gender) {
    // Different thresholds based on gender
    if (gender == Gender.male) {
      if (hdl >= 60) {
        return RiskLevel.normal;
      } else if (hdl >= 50 && hdl < 60) {
        return RiskLevel.moderate;
      } else if (hdl >= 40 && hdl < 50) {
        return RiskLevel.high;
      } else {
        return RiskLevel.veryHigh;
      }
    } else {
      // Female or other
      if (hdl >= 60) {
        return RiskLevel.normal;
      } else if (hdl >= 50 && hdl < 60) {
        return RiskLevel.moderate;
      } else if (hdl >= 40 && hdl < 50) {
        return RiskLevel.high;
      } else {
        return RiskLevel.veryHigh;
      }
    }
  }

  // Calculate Total Cholesterol risk
  static RiskLevel calculateTotalCholesterolRisk(double totalCholesterol) {
    if (totalCholesterol < 200) {
      return RiskLevel.normal;
    } else if (totalCholesterol >= 200 && totalCholesterol < 240) {
      return RiskLevel.moderate;
    } else {
      return RiskLevel.high;
    }
  }

  // Calculate Triglycerides risk
  static RiskLevel calculateTriglyceridesRisk(double triglycerides) {
    if (triglycerides < 150) {
      return RiskLevel.normal;
    } else if (triglycerides >= 150 && triglycerides < 200) {
      return RiskLevel.moderate;
    } else if (triglycerides >= 200 && triglycerides < 500) {
      return RiskLevel.high;
    } else {
      return RiskLevel.veryHigh;
    }
  }

  // Calculate Blood Pressure risk
  static RiskLevel calculateBloodPressureRisk(int systolic, int diastolic) {
    // Consider the higher risk category from either systolic or diastolic
    RiskLevel systolicRisk;
    RiskLevel diastolicRisk;

    // Systolic risk assessment
    if (systolic < 120) {
      systolicRisk = RiskLevel.normal;
    } else if (systolic >= 120 && systolic < 130) {
      systolicRisk = RiskLevel.moderate;
    } else if (systolic >= 130 && systolic < 140) {
      systolicRisk = RiskLevel.high;
    } else {
      systolicRisk = RiskLevel.veryHigh;
    }

    // Diastolic risk assessment
    if (diastolic < 80) {
      diastolicRisk = RiskLevel.normal;
    } else if (diastolic >= 80 && diastolic < 85) {
      diastolicRisk = RiskLevel.moderate;
    } else if (diastolic >= 85 && diastolic < 90) {
      diastolicRisk = RiskLevel.high;
    } else {
      diastolicRisk = RiskLevel.veryHigh;
    }

    // Return the higher risk level
    return systolicRisk.value > diastolicRisk.value ? systolicRisk : diastolicRisk;
  }

  // Calculate Blood Sugar risk (fasting glucose)
  static RiskLevel calculateBloodSugarRisk(double bloodSugar) {
    if (bloodSugar < 100) {
      return RiskLevel.normal;
    } else if (bloodSugar >= 100 && bloodSugar < 126) {
      return RiskLevel.moderate;
    } else {
      return RiskLevel.high;
    }
  }

  // Calculate smoking risk
  static RiskLevel calculateSmokingRisk(bool isSmoker) {
    return isSmoker ? RiskLevel.high : RiskLevel.normal;
  }

  // Calculate overall risk score
  static RiskLevel calculateOverallRisk(List<RiskFactor> riskFactors) {
    if (riskFactors.isEmpty) {
      return RiskLevel.normal;
    }

    // Calculate total points
    int totalPoints = 0;
    for (var factor in riskFactors) {
      totalPoints += factor.riskLevel.value;
    }

    // Calculate average points
    double averagePoints = totalPoints / riskFactors.length;

    // Convert back to risk level
    if (averagePoints >= 2.5) {
      return RiskLevel.veryHigh;
    } else if (averagePoints >= 1.5) {
      return RiskLevel.high;
    } else if (averagePoints >= 0.5) {
      return RiskLevel.moderate;
    } else {
      return RiskLevel.normal;
    }
  }

  // Generate a UserRiskProfile from health data
  static UserRiskProfile generateRiskProfile(UserHealthData healthData, String userId) {
    // Generate risk factors
    final factors = generateRiskFactors(healthData);
    
    // Calculate overall risk
    final overallRisk = calculateOverallRisk(factors);
    
    // Create map of specific risk factors
    final specificRiskFactors = <String, RiskLevel>{};
    for (final factor in factors) {
      specificRiskFactors[factor.id] = factor.riskLevel;
    }
    
    // Return user risk profile
    return UserRiskProfile(
      userId: userId,
      overallRiskLevel: overallRisk,
      specificRiskFactors: specificRiskFactors,
      lastUpdated: healthData.lastUpdated,
    );
  }
  
  // Generate all risk factors from health data
  static List<RiskFactor> generateRiskFactors(UserHealthData healthData) {
    final List<RiskFactor> factors = [];

    // BMI Risk Factor
    if (healthData.bmi != null) {
      factors.add(
        RiskFactor(
          id: 'bmi',
          title: 'Body Mass Index',
          value: healthData.bmi!,
          unit: 'kg/m²',
          riskLevel: calculateBMIRisk(healthData.bmi!),
          description: 'A measure of body fat based on height and weight.',
          lastUpdated: healthData.lastUpdated,
          iconData: Icons.monitor_weight,
        ),
      );
    }

    // LDL Cholesterol Risk Factor
    if (healthData.ldlCholesterol != null) {
      factors.add(
        RiskFactor(
          id: 'ldl_cholesterol',
          title: 'LDL Cholesterol',
          value: healthData.ldlCholesterol!,
          unit: 'mg/dL',
          riskLevel: calculateLDLCholesterolRisk(healthData.ldlCholesterol!),
          description: 'Low-density lipoprotein, often called "bad" cholesterol.',
          lastUpdated: healthData.lastUpdated,
          iconData: Icons.bloodtype,
        ),
      );
    }

    // HDL Cholesterol Risk Factor
    if (healthData.hdlCholesterol != null) {
      factors.add(
        RiskFactor(
          id: 'hdl_cholesterol',
          title: 'HDL Cholesterol',
          value: healthData.hdlCholesterol!,
          unit: 'mg/dL',
          riskLevel: calculateHDLCholesterolRisk(
            healthData.hdlCholesterol!,
            healthData.gender,
          ),
          description: 'High-density lipoprotein, often called "good" cholesterol.',
          lastUpdated: healthData.lastUpdated,
          iconData: Icons.bloodtype,
        ),
      );
    }

    // Total Cholesterol Risk Factor
    if (healthData.totalCholesterol != null) {
      factors.add(
        RiskFactor(
          id: 'total_cholesterol',
          title: 'Total Cholesterol',
          value: healthData.totalCholesterol!,
          unit: 'mg/dL',
          riskLevel: calculateTotalCholesterolRisk(healthData.totalCholesterol!),
          description: 'The total amount of cholesterol in your blood.',
          lastUpdated: healthData.lastUpdated,
          iconData: Icons.bloodtype,
        ),
      );
    }

    // Triglycerides Risk Factor
    if (healthData.triglycerides != null) {
      factors.add(
        RiskFactor(
          id: 'triglycerides',
          title: 'Triglycerides',
          value: healthData.triglycerides!,
          unit: 'mg/dL',
          riskLevel: calculateTriglyceridesRisk(healthData.triglycerides!),
          description: 'A type of fat found in your blood.',
          lastUpdated: healthData.lastUpdated,
          iconData: Icons.bloodtype,
        ),
      );
    }

    // Blood Pressure Risk Factor
    if (healthData.systolicBP != null && healthData.diastolicBP != null) {
      factors.add(
        RiskFactor(
          id: 'blood_pressure',
          title: 'Blood Pressure',
          value: healthData.systolicBP!.toDouble(),
          unit: '/${healthData.diastolicBP} mmHg',
          riskLevel: calculateBloodPressureRisk(
            healthData.systolicBP!,
            healthData.diastolicBP!,
          ),
          description: 'The pressure of blood against the walls of your arteries.',
          lastUpdated: healthData.lastUpdated,
          iconData: Icons.favorite,
        ),
      );
    }

    // Blood Sugar Risk Factor
    if (healthData.bloodSugar != null) {
      factors.add(
        RiskFactor(
          id: 'blood_sugar',
          title: 'Blood Sugar',
          value: healthData.bloodSugar!,
          unit: 'mg/dL',
          riskLevel: calculateBloodSugarRisk(healthData.bloodSugar!),
          description: 'The amount of glucose in your blood.',
          lastUpdated: healthData.lastUpdated,
          iconData: Icons.water_drop,
        ),
      );
    }

    // Smoking Risk Factor
    factors.add(
      RiskFactor(
        id: 'smoking',
        title: 'Smoking',
        value: healthData.isSmoker ? 1.0 : 0.0,
        unit: '',
        riskLevel: calculateSmokingRisk(healthData.isSmoker),
        description: healthData.isSmoker
            ? 'Current smoker - increased risk for NCDs.'
            : 'Non-smoker - reduced risk for NCDs.',
        lastUpdated: healthData.lastUpdated,
        iconData: healthData.isSmoker ? Icons.smoking_rooms : Icons.smoke_free,
      ),
    );

    return factors;
  }
}