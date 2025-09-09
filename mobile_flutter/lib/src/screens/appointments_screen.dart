import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  final _title = TextEditingController();
  final _when = TextEditingController(text: '2025-09-15T10:00:00Z');
  final _notes = TextEditingController();

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
          .get(Uri.parse('${AuthProvider.baseUrl}/appointments/'), headers: await _authHeaders())
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
        title: const Text('New appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: _when, decoration: const InputDecoration(labelText: 'Scheduled for (ISO8601)')),
            TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final body = jsonEncode({
                'title': _title.text.trim(),
                'scheduled_for': _when.text.trim(),
                'notes': _notes.text.trim(),
                'status': 'scheduled'
              });
              final res = await http
                  .post(Uri.parse('${AuthProvider.baseUrl}/appointments/'), headers: await _authHeaders(), body: body)
                  .timeout(const Duration(seconds: 15));
              if (!mounted) return;
              Navigator.pop(context);
              if (res.statusCode == 201) {
                _title.clear();
                _notes.clear();
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
      appBar: AppBar(title: const Text('Appointments')),
      floatingActionButton: FloatingActionButton(onPressed: _create, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _items.isEmpty
                  ? const Center(child: Text('No appointments'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final a = _items[i] as Map<String, dynamic>;
                        return ListTile(
                          leading: const Icon(Icons.event_outlined),
                          title: Text(a['title']?.toString() ?? ''),
                          subtitle: Text('${a['scheduled_for'] ?? ''} • ${a['status'] ?? ''}'),
                        );
                      },
                    ),
    );
  }
}

