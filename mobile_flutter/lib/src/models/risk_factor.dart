import 'package:flutter/material.dart';
import 'risk_level.dart';

class RiskFactor {
  final String id;
  final String title;
  final double value;
  final String unit;
  final RiskLevel riskLevel;
  final String description;
  final DateTime lastUpdated;
  final IconData iconData;

  RiskFactor({
    required this.id,
    required this.title,
    required this.value,
    required this.unit,
    required this.riskLevel,
    required this.description,
    required this.lastUpdated,
    required this.iconData,
  });

  // Create a copy with some fields changed
  RiskFactor copyWith({
    String? id,
    String? title,
    double? value,
    String? unit,
    RiskLevel? riskLevel,
    String? description,
    DateTime? lastUpdated,
    IconData? iconData,
  }) {
    return RiskFactor(
      id: id ?? this.id,
      title: title ?? this.title,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      riskLevel: riskLevel ?? this.riskLevel,
      description: description ?? this.description,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      iconData: iconData ?? this.iconData,
    );
  }

  // Convert to a Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'value': value,
      'unit': unit,
      'riskLevel': riskLevel.index,
      'description': description,
      'lastUpdated': lastUpdated.toIso8601String(),
      'iconData': iconData.codePoint,
    };
  }

  // Create from a Map (JSON deserialization)
  factory RiskFactor.fromMap(Map<String, dynamic> map) {
    return RiskFactor(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      value: map['value']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '',
      riskLevel: RiskLevel.values[map['riskLevel'] ?? 0],
      description: map['description'] ?? '',
      lastUpdated: DateTime.parse(map['lastUpdated']),
      iconData: IconData(map['iconData'] ?? Icons.error.codePoint, fontFamily: 'MaterialIcons'),
    );
  }
}