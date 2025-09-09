import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  final int? patientId;
  const AnalyticsScreen({super.key, this.patientId});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _series;
  bool _loading = true;
  String? _error;

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
      final q = widget.patientId != null ? '?patient_id=${widget.patientId}' : '';
      final res = await http.get(Uri.parse('${AuthProvider.baseUrl}/analytics/$q'), headers: await _authHeaders()).timeout(const Duration(seconds: 15));
      final ts = await http.get(Uri.parse('${AuthProvider.baseUrl}/analytics/timeseries/$q'), headers: await _authHeaders()).timeout(const Duration(seconds: 15));
      setState(() {
        _summary = res.statusCode == 200 ? jsonDecode(res.body) : null;
        _series = ts.statusCode == 200 ? jsonDecode(ts.body) : null;
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
      appBar: AppBar(title: const Text('Analytics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Glucose avg: ${_summary?['glucose']?['avg'] ?? '-'}'),
                    Text('BP max: ${_summary?['blood_pressure']?['max_sys'] ?? '-'} / ${_summary?['blood_pressure']?['max_dia'] ?? '-'}'),
                    const SizedBox(height: 16),
                    const Text('Series (latest)', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Glucose points: ${(_series?['glucose'] as List?)?.length ?? 0}'),
                    Text('BP points: ${(_series?['bp'] as List?)?.length ?? 0}'),
                  ],
                ),
    );
  }
}


