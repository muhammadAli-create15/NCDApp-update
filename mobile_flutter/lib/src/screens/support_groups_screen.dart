import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';

class SupportGroupsScreen extends StatefulWidget {
  const SupportGroupsScreen({super.key});

  @override
  State<SupportGroupsScreen> createState() => _SupportGroupsScreenState();
}

class _SupportGroupsScreenState extends State<SupportGroupsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _groups = [];
  final _message = TextEditingController();
  int? _selectedGroupId;

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
      final res = await http
          .get(Uri.parse('${AuthProvider.baseUrl}/support-groups/'), headers: await _authHeaders())
          .timeout(const Duration(seconds: 15));
      setState(() {
        _groups = res.statusCode == 200 ? (jsonDecode(res.body) as List<dynamic>) : [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Network error';
        _loading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_selectedGroupId == null || _message.text.trim().isEmpty) return;
    final res = await http
        .post(Uri.parse('${AuthProvider.baseUrl}/support-group-messages/'), headers: await _authHeaders(), body: jsonEncode({
      'group': _selectedGroupId,
      // backend will use current user as author if enforced; otherwise this fails unless author provided
      'message': _message.text.trim()
    }))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 201) {
      _message.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message sent')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res.statusCode}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support Groups')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    DropdownButton<int>(
                      value: _selectedGroupId,
                      hint: const Text('Select group'),
                      items: _groups.map((g) {
                        final m = g as Map<String, dynamic>;
                        return DropdownMenuItem<int>(
                          value: m['id'] as int?,
                          child: Text(m['name']?.toString() ?? ''),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedGroupId = v),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(children: [
                        Expanded(child: TextField(controller: _message, decoration: const InputDecoration(labelText: 'Message'))),
                        IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send))
                      ]),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _groups.length,
                        itemBuilder: (_, i) {
                          final m = _groups[i] as Map<String, dynamic>;
                          return ListTile(
                            leading: const Icon(Icons.group_outlined),
                            title: Text(m['name']?.toString() ?? ''),
                            subtitle: Text(m['description']?.toString() ?? ''),
                          );
                        },
                      ),
                    )
                  ],
                ),
    );
  }
}


