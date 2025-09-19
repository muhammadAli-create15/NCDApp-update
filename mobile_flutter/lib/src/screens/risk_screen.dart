import 'package:flutter/material.dart';
import '../models/risk_factor.dart';
import '../models/risk_level.dart';
import '../models/user_health_data.dart';
import '../utils/risk_calculator.dart';
import '../utils/risk_profile_converter.dart';
import '../widgets/risk_factor_card.dart';
import 'risk_detail_screen.dart';
import 'education_screen.dart';

class RiskScreen extends StatefulWidget {
  const RiskScreen({super.key});

  @override
  _RiskScreenState createState() => _RiskScreenState();
}

class _RiskScreenState extends State<RiskScreen> {
  late UserHealthData _userData;
  late List<RiskFactor> _riskFactors;
  late RiskLevel _overallRisk;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // In a real app, this would fetch data from an API or database
  Future<void> _loadUserData() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Create sample user health data
    _userData = UserHealthData(
      weight: 85, // kg
      height: 1.75, // meters
      totalCholesterol: 210, // mg/dL
      hdlCholesterol: 45, // mg/dL
      ldlCholesterol: 140, // mg/dL
      triglycerides: 180, // mg/dL
      systolicBP: 135, // mmHg
      diastolicBP: 85, // mmHg
      bloodSugar: 105, // mg/dL (fasting)
      isSmoker: false,
      age: 45,
      gender: Gender.male,
      lastUpdated: DateTime.now().subtract(const Duration(days: 30)),
    );
    
    // Calculate risk factors
    _riskFactors = RiskCalculator.generateRiskFactors(_userData);
    
    // Calculate overall risk
    _overallRisk = RiskCalculator.calculateOverallRisk(_riskFactors);
    
    // Update state
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToDetail(RiskFactor factor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RiskDetailScreen(riskFactor: factor),
      ),
    );
  }
  
  void _navigateToEducation() {
    // Create a risk profile from the risk factors
    final userRiskProfile = RiskProfileConverter.fromRiskFactors(
      'user_${DateTime.now().millisecondsSinceEpoch}', // Generate temporary user ID
      _riskFactors,
      _overallRisk,
    );
    
    // Navigate to education screen with the risk profile
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EducationScreen(initialRiskProfile: userRiskProfile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Assessment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadUserData();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildOverallRiskCard(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'Risk Factors',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _riskFactors.length,
                    itemBuilder: (context, index) {
                      final factor = _riskFactors[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: RiskFactorCard(
                          riskFactor: factor,
                          onTap: () => _navigateToDetail(factor),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16.0),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Update Health Data'),
                      onPressed: () {
                        // TODO: Navigate to a form to update health data
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Update Health Data - Not yet implemented'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.school),
                      label: const Text('View Personalized Health Education'),
                      onPressed: () => _navigateToEducation(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            ),
    );
  }

  Widget _buildOverallRiskCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 4.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _overallRisk.color.withOpacity(0.7),
              _overallRisk.color,
            ],
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getRiskIcon(_overallRisk),
                    color: Colors.white,
                    size: 28.0,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Overall Risk Assessment',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Text(
                _overallRisk.level,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                _overallRisk.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRiskCounter(
                      RiskLevel.normal, _countRiskLevel(RiskLevel.normal)),
                  _buildRiskCounter(
                      RiskLevel.moderate, _countRiskLevel(RiskLevel.moderate)),
                  _buildRiskCounter(
                      RiskLevel.high, _countRiskLevel(RiskLevel.high)),
                  _buildRiskCounter(
                      RiskLevel.veryHigh, _countRiskLevel(RiskLevel.veryHigh)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskCounter(RiskLevel level, int count) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: level.color,
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          level.level,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.0,
          ),
        ),
      ],
    );
  }

  int _countRiskLevel(RiskLevel level) {
    return _riskFactors.where((factor) => factor.riskLevel == level).length;
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
