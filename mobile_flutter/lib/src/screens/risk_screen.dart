import 'dart:convert';
import 'package:flutter/material.dart';
import '../auth/api_client.dart';
import '../auth/auth_provider.dart';

class RiskScreen extends StatefulWidget {
  final int? patientId;
  const RiskScreen({super.key, this.patientId});

  @override
  State<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends State<RiskScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _rb;
  Map<String, dynamic>? _ml;
  Map<String, dynamic>? _ada;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final useMe = widget.patientId == null;
      final rb = await ApiClient.get(useMe ? '/risk/me/' : '/risk/${widget.patientId}/');
      final ml = await ApiClient.get(useMe ? '/risk-ml/me/' : '/risk-ml/${widget.patientId}/');
      final ada = await ApiClient.get('/risk-ada/me/');
      setState(() {
        _rb = rb.statusCode == 200 ? jsonDecode(rb.body) : null;
        _ml = ml.statusCode == 200 ? jsonDecode(ml.body) : null;
        _ada = ada.statusCode == 200 ? jsonDecode(ada.body) : null;
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
                    Text('Risk %: ${_ml?['ml_risk_score'] ?? '-'}'),
                    if (_ml?['model'] != null) Text('Model: ${_ml?['model']?['framework'] ?? 'heuristic'}'),
                    const SizedBox(height: 16),
                    const Text('ADA Type 2 Diabetes Risk', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Score: ${_ada?['ada_score'] ?? '-'}'),
                    Text('Category: ${_ada?['category'] ?? '-'}'),
                  ]),
                ),
    );
  }
}

