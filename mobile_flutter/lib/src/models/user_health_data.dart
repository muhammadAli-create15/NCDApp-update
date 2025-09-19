enum Gender {
  male,
  female,
  other
}

class UserHealthData {
  final double? weight; // in kg
  final double? height; // in meters
  final double? totalCholesterol; // in mg/dL
  final double? hdlCholesterol; // in mg/dL
  final double? ldlCholesterol; // in mg/dL
  final double? triglycerides; // in mg/dL
  final int? systolicBP; // in mmHg
  final int? diastolicBP; // in mmHg
  final double? bloodSugar; // in mg/dL (fasting)
  final bool isSmoker;
  final int? age;
  final Gender? gender;
  final DateTime lastUpdated;

  UserHealthData({
    this.weight,
    this.height,
    this.totalCholesterol,
    this.hdlCholesterol,
    this.ldlCholesterol,
    this.triglycerides,
    this.systolicBP,
    this.diastolicBP,
    this.bloodSugar,
    this.isSmoker = false,
    this.age,
    this.gender,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Calculate BMI if weight and height are available
  double? get bmi {
    if (weight != null && height != null && height! > 0) {
      return weight! / (height! * height!);
    }
    return null;
  }

  // Create a copy with some fields changed
  UserHealthData copyWith({
    double? weight,
    double? height,
    double? totalCholesterol,
    double? hdlCholesterol,
    double? ldlCholesterol,
    double? triglycerides,
    int? systolicBP,
    int? diastolicBP,
    double? bloodSugar,
    bool? isSmoker,
    int? age,
    Gender? gender,
    DateTime? lastUpdated,
  }) {
    return UserHealthData(
      weight: weight ?? this.weight,
      height: height ?? this.height,
      totalCholesterol: totalCholesterol ?? this.totalCholesterol,
      hdlCholesterol: hdlCholesterol ?? this.hdlCholesterol,
      ldlCholesterol: ldlCholesterol ?? this.ldlCholesterol,
      triglycerides: triglycerides ?? this.triglycerides,
      systolicBP: systolicBP ?? this.systolicBP,
      diastolicBP: diastolicBP ?? this.diastolicBP,
      bloodSugar: bloodSugar ?? this.bloodSugar,
      isSmoker: isSmoker ?? this.isSmoker,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Convert to a Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'height': height,
      'totalCholesterol': totalCholesterol,
      'hdlCholesterol': hdlCholesterol,
      'ldlCholesterol': ldlCholesterol,
      'triglycerides': triglycerides,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'bloodSugar': bloodSugar,
      'isSmoker': isSmoker,
      'age': age,
      'gender': gender?.index,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Create from a Map (JSON deserialization)
  factory UserHealthData.fromMap(Map<String, dynamic> map) {
    return UserHealthData(
      weight: map['weight']?.toDouble(),
      height: map['height']?.toDouble(),
      totalCholesterol: map['totalCholesterol']?.toDouble(),
      hdlCholesterol: map['hdlCholesterol']?.toDouble(),
      ldlCholesterol: map['ldlCholesterol']?.toDouble(),
      triglycerides: map['triglycerides']?.toDouble(),
      systolicBP: map['systolicBP'],
      diastolicBP: map['diastolicBP'],
      bloodSugar: map['bloodSugar']?.toDouble(),
      isSmoker: map['isSmoker'] ?? false,
      age: map['age'],
      gender: map['gender'] != null ? Gender.values[map['gender']] : null,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'])
          : DateTime.now(),
    );
  }
}