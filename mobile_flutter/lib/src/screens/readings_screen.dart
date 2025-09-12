import 'dart:convert';
import 'package:flutter/material.dart';
import '../auth/api_client.dart';
import '../auth/auth_provider.dart';

class ReadingsScreen extends StatefulWidget {
  const ReadingsScreen({super.key});

  @override
  State<ReadingsScreen> createState() => _ReadingsScreenState();
}

class _ReadingsScreenState extends State<ReadingsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];
  final _glucose = TextEditingController();
  final _bpSys = TextEditingController();
  final _bpDia = TextEditingController();
  final _weight = TextEditingController();
  final _bmi = TextEditingController();
  final _waist = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.get('/device-readings/');
      if (res.statusCode == 200) {
        setState(() {
          _items = jsonDecode(res.body) as List<dynamic>;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Error ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error';
        _loading = false;
      });
    }
  }

  Future<void> _addReadingDialog() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add readings', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(controller: _glucose, decoration: const InputDecoration(labelText: 'Glucose (mg/dL)')), 
                Row(children: [
                  Expanded(child: TextField(controller: _bpSys, decoration: const InputDecoration(labelText: 'BP Systolic'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _bpDia, decoration: const InputDecoration(labelText: 'BP Diastolic'))),
                ]),
                TextField(controller: _weight, decoration: const InputDecoration(labelText: 'Weight (kg)')),
                TextField(controller: _bmi, decoration: const InputDecoration(labelText: 'BMI')),
                TextField(controller: _waist, decoration: const InputDecoration(labelText: 'Waist (cm)')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const Spacer(),
                    ElevatedButton(onPressed: () async {
                      // Submit non-empty fields
                      final futures = <Future>[];
                      if (_glucose.text.trim().isNotEmpty) {
                        futures.add(ApiClient.post('/device-readings/', {
                          'reading_type': 'glucose',
                          'value': double.tryParse(_glucose.text.trim()) ?? 0,
                          'unit': 'mg/dL',
                        }));
                      }
                      if (_bpSys.text.trim().isNotEmpty && _bpDia.text.trim().isNotEmpty) {
                        futures.add(ApiClient.post('/device-readings/', {
                          'reading_type': 'bp',
                          'value': 0,
                          'unit': 'mmHg',
                          'systolic': int.tryParse(_bpSys.text.trim()) ?? 0,
                          'diastolic': int.tryParse(_bpDia.text.trim()) ?? 0,
                        }));
                      }
                      if (_weight.text.trim().isNotEmpty) {
                        futures.add(ApiClient.post('/device-readings/', {
                          'reading_type': 'weight',
                          'value': double.tryParse(_weight.text.trim()) ?? 0,
                          'unit': 'kg',
                        }));
                      }
                      if (_bmi.text.trim().isNotEmpty) {
                        futures.add(ApiClient.post('/device-readings/', {
                          'reading_type': 'bmi',
                          'value': double.tryParse(_bmi.text.trim()) ?? 0,
                          'unit': 'kg/m2',
                        }));
                      }
                      if (_waist.text.trim().isNotEmpty) {
                        futures.add(ApiClient.post('/device-readings/', {
                          'reading_type': 'waist',
                          'value': double.tryParse(_waist.text.trim()) ?? 0,
                          'unit': 'cm',
                        }));
                      }
                      await Future.wait(futures);
                      if (!mounted) return;
                      Navigator.pop(context);
                      _glucose.clear(); _bpSys.clear(); _bpDia.clear(); _weight.clear(); _bmi.clear(); _waist.clear();
                      _load();
                    }, child: const Text('Save')),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Readings')),
      floatingActionButton: FloatingActionButton(onPressed: _addReadingDialog, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _items.isEmpty
                  ? const Center(child: Text('No readings'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final r = _items[i] as Map<String, dynamic>;
                        final type = r['reading_type']?.toString() ?? '';
                        final value = r['value']?.toString() ?? '';
                        final unit = r['unit']?.toString() ?? '';
                        final t = r['recorded_at']?.toString() ?? '';
                        return ListTile(
                          leading: const Icon(Icons.monitor_heart_outlined),
                          title: Text('$type  $value$unit'),
                          subtitle: Text(t),
                        );
                      },
                    ),
    );
  }
}


