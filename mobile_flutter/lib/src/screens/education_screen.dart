import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/supabase_auth_provider.dart';
import '../models/user_risk_profile.dart';
import '../models/risk_level.dart';
import 'education_dashboard_screen.dart';

class EducationScreen extends StatefulWidget {
  final UserRiskProfile? initialRiskProfile;
  
  const EducationScreen({
    super.key, 
    this.initialRiskProfile,
  });

  @override
  _EducationScreenState createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  UserRiskProfile? _userRiskProfile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userRiskProfile = widget.initialRiskProfile;
    
    if (_userRiskProfile == null) {
      _createDefaultRiskProfile();
    }
  }

  // Create a default risk profile if none is provided
  void _createDefaultRiskProfile() async {
    final auth = Provider.of<SupabaseAuthProvider>(context, listen: false);
    final userId = auth.user?.id ?? 'guest_user';
    
    setState(() {
      _isLoading = true;
    });
    
    // Create a default risk profile for testing purposes
    final defaultRiskProfile = UserRiskProfile(
      userId: userId,
      overallRiskLevel: RiskLevel.moderate,
      specificRiskFactors: {
        'bmi': RiskLevel.moderate,
        'ldl_cholesterol': RiskLevel.moderate,
        'blood_pressure': RiskLevel.normal,
        'blood_sugar': RiskLevel.normal,
        'smoking': RiskLevel.normal,
      },
      lastUpdated: DateTime.now(),
    );
    
    setState(() {
      _userRiskProfile = defaultRiskProfile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Health Education')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return EducationDashboardScreen(userRiskProfile: _userRiskProfile);
  }
}

