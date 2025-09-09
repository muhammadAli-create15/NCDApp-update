import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];
  List<dynamic> _topics = [];
  String _filter = 'all';

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
      final headers = await _authHeaders();
      final itemsF = http.get(Uri.parse('${AuthProvider.baseUrl}/education/'), headers: headers);
      final topicsF = http.get(Uri.parse('${AuthProvider.baseUrl}/education/topics/'), headers: headers);
      final res = await itemsF.timeout(const Duration(seconds: 15));
      final tp = await topicsF.timeout(const Duration(seconds: 15));
      setState(() {
        _items = res.statusCode == 200 ? (jsonDecode(res.body) as List<dynamic>) : [];
        _topics = tp.statusCode == 200 ? (jsonDecode(tp.body) as List<dynamic>) : [];
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
    final filtered = _filter == 'all'
        ? _items
        : _items.where((e) => (e as Map<String, dynamic>)['topic']?.toString() == _filter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Education')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Text('Topic:'),
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: _filter,
                            items: [
                              const DropdownMenuItem(value: 'all', child: Text('All')),
                              ..._topics.map((t) => DropdownMenuItem(value: t.toString(), child: Text(t.toString()))),
                            ],
                            onChanged: (v) => setState(() => _filter = v ?? 'all'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final m = filtered[i] as Map<String, dynamic>;
                          return ListTile(
                            leading: const Icon(Icons.menu_book_outlined),
                            title: Text(m['title']?.toString() ?? ''),
                            subtitle: Text((m['content']?.toString() ?? '').isEmpty ? (m['media_url']?.toString() ?? '') : m['content']?.toString() ?? ''),
                            trailing: Text(m['topic']?.toString() ?? ''),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}


