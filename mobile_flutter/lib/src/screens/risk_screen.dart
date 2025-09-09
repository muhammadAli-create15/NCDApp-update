import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';

class RiskScreen extends StatefulWidget {
  final int patientId;
  const RiskScreen({super.key, required this.patientId});

  @override
  State<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends State<RiskScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _rb;
  Map<String, dynamic>? _ml;

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString('access');
    return {
      'Authorization': 'Bearer ${access ?? ''}',
      'Content-Type': 'application/json'
    };
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rb = await http.get(Uri.parse('${AuthProvider.baseUrl}/risk/${widget.patientId}/'), headers: await _authHeaders()).timeout(const Duration(seconds: 15));
      final ml = await http.get(Uri.parse('${AuthProvider.baseUrl}/risk-ml/${widget.patientId}/'), headers: await _authHeaders()).timeout(const Duration(seconds: 15));
      setState(() {
        _rb = rb.statusCode == 200 ? jsonDecode(rb.body) : null;
        _ml = ml.statusCode == 200 ? jsonDecode(ml.body) : null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Network error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Risk Assessment')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Rule-based scores', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Diabetes: ${_rb?['diabetes_risk_score'] ?? '-'}'),
                    Text('Hypertension: ${_rb?['hypertension_risk_score'] ?? '-'}'),
                    const SizedBox(height: 16),
                    const Text('ML-inspired risk', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Risk %: ${_ml?['risk_percent'] ?? '-'}'),
                  ]),
                ),
    );
  }
}

