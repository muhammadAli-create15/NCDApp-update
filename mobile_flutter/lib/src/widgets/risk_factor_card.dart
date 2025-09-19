import 'package:flutter/material.dart';
import '../models/risk_factor.dart';
import '../models/risk_level.dart';
import 'package:intl/intl.dart';

class RiskFactorCard extends StatelessWidget {
  final RiskFactor riskFactor;
  final VoidCallback onTap;
  
  const RiskFactorCard({
    Key? key,
    required this.riskFactor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: riskFactor.riskLevel.color.withOpacity(0.8),
          width: 2.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              // Left accent bar with risk color
              Container(
                width: 8.0,
                height: 80.0,
                decoration: BoxDecoration(
                  color: riskFactor.riskLevel.color,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              const SizedBox(width: 16.0),
              
              // Icon with risk level background
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: riskFactor.riskLevel.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  riskFactor.iconData,
                  size: 28.0,
                  color: riskFactor.riskLevel.color,
                ),
              ),
              const SizedBox(width: 16.0),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            riskFactor.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                        _buildRiskLevelBadge(riskFactor.riskLevel),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Text(
                          '${riskFactor.value.toStringAsFixed(1)}${riskFactor.unit}',
                          style: const TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          '• ${DateFormat('MMM d, yyyy').format(riskFactor.lastUpdated)}',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      riskFactor.description,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Arrow
              const Icon(
                Icons.arrow_forward_ios,
                size: 16.0,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskLevelBadge(RiskLevel level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: level.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRiskIcon(level),
            size: 12.0,
            color: level.color,
          ),
          const SizedBox(width: 4.0),
          Text(
            level.level,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              color: level.color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRiskIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.veryHigh:
        return Icons.error;
      case RiskLevel.high:
        return Icons.warning;
      case RiskLevel.moderate:
        return Icons.info;
      case RiskLevel.normal:
        return Icons.check_circle;
    }
  }
}