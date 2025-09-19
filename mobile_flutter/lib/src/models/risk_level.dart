import 'package:flutter/material.dart';

enum RiskLevel {
  veryHigh(
    level: 'Very High',
    color: Color(0xFFFF5252),
    value: 3,
    description: 'Immediate attention required',
  ),
  high(
    level: 'High',
    color: Color(0xFFFF9800),
    value: 2,
    description: 'Action needed soon',
  ),
  moderate(
    level: 'Moderate',
    color: Color(0xFFFFEB3B),
    value: 1,
    description: 'Monitor closely',
  ),
  normal(
    level: 'Normal',
    color: Color(0xFF4CAF50),
    value: 0,
    description: 'Healthy range',
  );

  final String level;
  final Color color;
  final int value;
  final String description;

  const RiskLevel({
    required this.level,
    required this.color,
    required this.value,
    required this.description,
  });
}