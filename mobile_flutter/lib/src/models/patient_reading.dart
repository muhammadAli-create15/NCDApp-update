import 'package:flutter/foundation.dart';

/// Represents a patient's medical reading entry
class PatientReading {
  final String? id;
  final String? patientId;
  final String name;
  final String age;
  final String bloodPressure;
  final String heartRate;
  final String respiratoryRate;
  final String temperature;
  final String height;
  final String weight;
  final String bmi;
  final String fastingBloodGlucose;
  final String randomBloodGlucose;
  final String hba1c;
  final String lipidProfile;
  final String serumCreatinine;
  final String bloodUreaNitrogen;
  final String egfr;
  final String electrolytes;
  final String liverFunctionTests;
  final String echocardiography;
  final DateTime? createdAt;
  final String? enteredBy;

  const PatientReading({
    this.id,
    this.patientId,
    required this.name,
    this.age = '',
    this.bloodPressure = '',
    this.heartRate = '',
    this.respiratoryRate = '',
    this.temperature = '',
    this.height = '',
    this.weight = '',
    this.bmi = '',
    this.fastingBloodGlucose = '',
    this.randomBloodGlucose = '',
    this.hba1c = '',
    this.lipidProfile = '',
    this.serumCreatinine = '',
    this.bloodUreaNitrogen = '',
    this.egfr = '',
    this.electrolytes = '',
    this.liverFunctionTests = '',
    this.echocardiography = '',
    this.createdAt,
    this.enteredBy,
  });

  /// Create from Supabase JSON
  factory PatientReading.fromJson(Map<String, dynamic> json) {
    return PatientReading(
      id: json['id']?.toString(),
      patientId: json['patient_id']?.toString(),
      // Default to 'Anonymous' if name doesn't exist
      name: json['name']?.toString() ?? 'Anonymous',
      age: json['age']?.toString() ?? '',
      bloodPressure: json['blood_pressure']?.toString() ?? '',
      heartRate: json['heart_rate']?.toString() ?? '',
      respiratoryRate: json['respiratory_rate']?.toString() ?? '',
      temperature: json['temperature']?.toString() ?? '',
      height: json['height']?.toString() ?? '',
      weight: json['weight']?.toString() ?? '',
      bmi: json['bmi']?.toString() ?? '',
      fastingBloodGlucose: json['fasting_blood_glucose']?.toString() ?? '',
      randomBloodGlucose: json['random_blood_glucose']?.toString() ?? '',
      hba1c: json['hba1c']?.toString() ?? '',
      lipidProfile: json['lipid_profile']?.toString() ?? '',
      serumCreatinine: json['serum_creatinine']?.toString() ?? '',
      bloodUreaNitrogen: json['blood_urea_nitrogen']?.toString() ?? '',
      egfr: json['egfr']?.toString() ?? '',
      electrolytes: json['electrolytes']?.toString() ?? '',
      liverFunctionTests: json['liver_function_tests']?.toString() ?? '',
      echocardiography: json['echocardiography']?.toString() ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      enteredBy: json['entered_by']?.toString(),
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      'name': name,
      'age': age,
      'blood_pressure': bloodPressure,
      'heart_rate': heartRate,
      'respiratory_rate': respiratoryRate,
      'temperature': temperature,
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'fasting_blood_glucose': fastingBloodGlucose,
      'random_blood_glucose': randomBloodGlucose,
      'hba1c': hba1c,
      'lipid_profile': lipidProfile,
      'serum_creatinine': serumCreatinine,
      'blood_urea_nitrogen': bloodUreaNitrogen,
      'egfr': egfr,
      'electrolytes': electrolytes,
      'liver_function_tests': liverFunctionTests,
      'echocardiography': echocardiography,
      if (enteredBy != null) 'entered_by': enteredBy,
    };
  }

  /// Create a copy with updated fields
  PatientReading copyWith({
    String? id,
    String? patientId,
    String? name,
    String? age,
    String? bloodPressure,
    String? heartRate,
    String? respiratoryRate,
    String? temperature,
    String? height,
    String? weight,
    String? bmi,
    String? fastingBloodGlucose,
    String? randomBloodGlucose,
    String? hba1c,
    String? lipidProfile,
    String? serumCreatinine,
    String? bloodUreaNitrogen,
    String? egfr,
    String? electrolytes,
    String? liverFunctionTests,
    String? echocardiography,
    DateTime? createdAt,
    String? enteredBy,
  }) {
    return PatientReading(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      age: age ?? this.age,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      heartRate: heartRate ?? this.heartRate,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      temperature: temperature ?? this.temperature,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bmi: bmi ?? this.bmi,
      fastingBloodGlucose: fastingBloodGlucose ?? this.fastingBloodGlucose,
      randomBloodGlucose: randomBloodGlucose ?? this.randomBloodGlucose,
      hba1c: hba1c ?? this.hba1c,
      lipidProfile: lipidProfile ?? this.lipidProfile,
      serumCreatinine: serumCreatinine ?? this.serumCreatinine,
      bloodUreaNitrogen: bloodUreaNitrogen ?? this.bloodUreaNitrogen,
      egfr: egfr ?? this.egfr,
      electrolytes: electrolytes ?? this.electrolytes,
      liverFunctionTests: liverFunctionTests ?? this.liverFunctionTests,
      echocardiography: echocardiography ?? this.echocardiography,
      createdAt: createdAt ?? this.createdAt,
      enteredBy: enteredBy ?? this.enteredBy,
    );
  }

  @override
  String toString() {
    return 'PatientReading(id: $id, name: $name, createdAt: $createdAt)';
  }
}

/// Utility class for flexible data validation and parsing
class ReadingValidator {
  /// Validates and parses numeric input (supports int, double, or string)
  static String? validateNumeric(String? value, String fieldName, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? '$fieldName is required' : null;
    }

    // Try parsing as number for validation, but store as string
    final trimmed = value.trim();
    
    // Allow common medical formats
    if (fieldName.toLowerCase().contains('blood pressure')) {
      // Allow formats like "120/80"
      final bpRegex = RegExp(r'^\d+\/\d+$');
      if (bpRegex.hasMatch(trimmed)) return null;
    }
    
    if (fieldName.toLowerCase().contains('temperature')) {
      // Allow formats like "98.6°F" or "37°C"
      final tempRegex = RegExp(r'^\d+\.?\d*\s?[°]?[CFcf]?$');
      if (tempRegex.hasMatch(trimmed)) return null;
    }
    
    // Try parsing as number
    if (double.tryParse(trimmed) != null || int.tryParse(trimmed) != null) {
      return null;
    }
    
    // If it's not a number, allow it as string (for medical notes/formats)
    return null;
  }

  /// Calculate BMI from height and weight strings
  static String calculateBMI(String heightStr, String weightStr) {
    try {
      // Extract numbers from strings
      final heightMatch = RegExp(r'\d+\.?\d*').firstMatch(heightStr);
      final weightMatch = RegExp(r'\d+\.?\d*').firstMatch(weightStr);
      
      if (heightMatch == null || weightMatch == null) return '';
      
      final height = double.parse(heightMatch.group(0)!);
      final weight = double.parse(weightMatch.group(0)!);
      
      if (height <= 0 || weight <= 0) return '';
      
      // BMI = weight (kg) / (height (m))^2
      final heightInMeters = height / 100; // Convert cm to m
      final bmi = weight / (heightInMeters * heightInMeters);
      
      return bmi.toStringAsFixed(1);
    } catch (e) {
      debugPrint('BMI calculation error: $e');
      return '';
    }
  }

  /// Get BMI category
  static String getBMICategory(String bmiStr) {
    try {
      final bmi = double.parse(bmiStr);
      if (bmi < 18.5) return 'Underweight';
      if (bmi < 25) return 'Normal';
      if (bmi < 30) return 'Overweight';
      return 'Obese';
    } catch (e) {
      return '';
    }
  }

  /// Parse flexible input to extract numeric value
  static double? parseNumeric(String value) {
    try {
      // Remove common units and symbols
      final cleaned = value
          .replaceAll(RegExp(r'[^\d\.-]'), '')
          .trim();
      return double.tryParse(cleaned);
    } catch (e) {
      return null;
    }
  }
}

/// Field configuration for the readings form
class ReadingField {
  final String key;
  final String label;
  final String hint;
  final String unit;
  final bool required;
  final String icon;

  const ReadingField({
    required this.key,
    required this.label,
    required this.hint,
    this.unit = '',
    this.required = false,
    required this.icon,
  });
}

/// Configuration for all medical reading fields
class ReadingFields {
  static const List<ReadingField> allFields = [
    ReadingField(
      key: 'name',
      label: 'Patient Name',
      hint: 'Enter patient\'s full name',
      required: true,
      icon: '👤',
    ),
    ReadingField(
      key: 'age',
      label: 'Age',
      hint: 'e.g., 45 or 45.5 years',
      unit: 'years',
      required: true,
      icon: '📅',
    ),
    ReadingField(
      key: 'bloodPressure',
      label: 'Blood Pressure',
      hint: 'e.g., 120/80',
      unit: 'mmHg',
      icon: '🩺',
    ),
    ReadingField(
      key: 'heartRate',
      label: 'Heart Rate',
      hint: 'e.g., 72',
      unit: 'bpm',
      icon: '❤️',
    ),
    ReadingField(
      key: 'respiratoryRate',
      label: 'Respiratory Rate',
      hint: 'e.g., 16',
      unit: '/min',
      icon: '🫁',
    ),
    ReadingField(
      key: 'temperature',
      label: 'Temperature',
      hint: 'e.g., 98.6°F or 37°C',
      unit: '°F/°C',
      icon: '🌡️',
    ),
    ReadingField(
      key: 'height',
      label: 'Height',
      hint: 'e.g., 170.5',
      unit: 'cm',
      icon: '📏',
    ),
    ReadingField(
      key: 'weight',
      label: 'Weight',
      hint: 'e.g., 70.0',
      unit: 'kg',
      icon: '⚖️',
    ),
    ReadingField(
      key: 'bmi',
      label: 'BMI',
      hint: 'Auto-calculated or manual entry',
      unit: 'kg/m²',
      icon: '📊',
    ),
    ReadingField(
      key: 'fastingBloodGlucose',
      label: 'Fasting Blood Glucose',
      hint: 'e.g., 90',
      unit: 'mg/dL',
      icon: '🩸',
    ),
    ReadingField(
      key: 'randomBloodGlucose',
      label: 'Random Blood Glucose',
      hint: 'e.g., 120',
      unit: 'mg/dL',
      icon: '🩸',
    ),
    ReadingField(
      key: 'hba1c',
      label: 'HbA1c',
      hint: 'e.g., 5.7',
      unit: '%',
      icon: '🔬',
    ),
    ReadingField(
      key: 'lipidProfile',
      label: 'Lipid Profile',
      hint: 'e.g., TC:200, LDL:130, HDL:50, TG:150',
      unit: 'mg/dL',
      icon: '🧪',
    ),
    ReadingField(
      key: 'serumCreatinine',
      label: 'Serum Creatinine',
      hint: 'e.g., 1.0',
      unit: 'mg/dL',
      icon: '🔬',
    ),
    ReadingField(
      key: 'bloodUreaNitrogen',
      label: 'Blood Urea Nitrogen',
      hint: 'e.g., 15',
      unit: 'mg/dL',
      icon: '🧪',
    ),
    ReadingField(
      key: 'egfr',
      label: 'eGFR',
      hint: 'e.g., 90',
      unit: 'mL/min',
      icon: '🫘',
    ),
    ReadingField(
      key: 'electrolytes',
      label: 'Electrolytes',
      hint: 'e.g., Na:140, K:4.0, Cl:100',
      unit: 'mEq/L',
      icon: '⚡',
    ),
    ReadingField(
      key: 'liverFunctionTests',
      label: 'Liver Function Tests',
      hint: 'e.g., ALT:30, AST:25',
      unit: 'U/L',
      icon: '🫀',
    ),
    ReadingField(
      key: 'echocardiography',
      label: 'Echocardiography',
      hint: 'e.g., Normal ejection fraction',
      icon: '🏥',
    ),
  ];
}