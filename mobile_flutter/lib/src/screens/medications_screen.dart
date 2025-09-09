import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  final _name = TextEditingController();
  final _dosage = TextEditingController();
  final _frequency = TextEditingController();
  final _time = TextEditingController(text: '08:00:00');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString('access');
    return {
      'Authorization': 'Bearer ${access ?? ''}',
      'Content-Type': 'application/json'
    };
  }

  Future<void> _load() async {
    try {
      final res = await http
          .get(Uri.parse('${AuthProvider.baseUrl}/medications/'), headers: await _authHeaders())
          .timeout(const Duration(seconds: 15));
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

  Future<void> _create() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: _dosage, decoration: const InputDecoration(labelText: 'Dosage')),
            TextField(controller: _frequency, decoration: const InputDecoration(labelText: 'Frequency')),
            TextField(controller: _time, decoration: const InputDecoration(labelText: 'Reminder time (HH:MM:SS)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final body = jsonEncode({
                'name': _name.text.trim(),
                'dosage': _dosage.text.trim(),
                'frequency': _frequency.text.trim(),
                'reminder_time': _time.text.trim(),
              });
              final res = await http
                  .post(Uri.parse('${AuthProvider.baseUrl}/medications/'), headers: await _authHeaders(), body: body)
                  .timeout(const Duration(seconds: 15));
              if (!mounted) return;
              Navigator.pop(context);
              if (res.statusCode == 201) {
                _name.clear();
                _dosage.clear();
                _frequency.clear();
                _time.text = '08:00:00';
                _load();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res.statusCode}')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medications')),
      floatingActionButton: FloatingActionButton(onPressed: _create, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _items.isEmpty
                  ? const Center(child: Text('No medications'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final m = _items[i] as Map<String, dynamic>;
                        return ListTile(
                          leading: const Icon(Icons.medication_outlined),
                          title: Text(m['name']?.toString() ?? ''),
                          subtitle: Text('${m['dosage'] ?? ''} • ${m['frequency'] ?? ''}\nTime: ${m['reminder_time'] ?? ''}'),
                          isThreeLine: true,
                        );
                      },
                    ),
    );
  }
}


