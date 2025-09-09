import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';

class QuestionnairesScreen extends StatefulWidget {
  const QuestionnairesScreen({super.key});

  @override
  State<QuestionnairesScreen> createState() => _QuestionnairesScreenState();
}

class _QuestionnairesScreenState extends State<QuestionnairesScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];
  bool _smoke = false;
  final _exercise = TextEditingController();
  bool _family = false;

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
          .get(Uri.parse('${AuthProvider.baseUrl}/questionnaires/'), headers: await _authHeaders())
          .timeout(const Duration(seconds: 15));
      setState(() {
        _items = res.statusCode == 200 ? (jsonDecode(res.body) as List<dynamic>) : [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Network error';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lifestyle questionnaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(value: _smoke, onChanged: (v)=> setState(()=> _smoke = v), title: const Text('Do you smoke?')),
            TextField(controller: _exercise, decoration: const InputDecoration(labelText: 'Exercise days/week'), keyboardType: TextInputType.number),
            SwitchListTile(value: _family, onChanged: (v)=> setState(()=> _family = v), title: const Text('Family history of diabetes?')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final body = jsonEncode({
                'category': 'lifestyle',
                'answers': {
                  'smoke': _smoke,
                  'exercise_days': int.tryParse(_exercise.text) ?? 0,
                  'family_history': _family
                }
              });
              final res = await http
                  .post(Uri.parse('${AuthProvider.baseUrl}/questionnaires/'), headers: await _authHeaders(), body: body)
                  .timeout(const Duration(seconds: 15));
              if (!mounted) return;
              Navigator.pop(context);
              if (res.statusCode == 201) {
                _exercise.clear();
                _smoke = false;
                _family = false;
                _load();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res.statusCode}')));
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Questionnaires')),
      floatingActionButton: FloatingActionButton(onPressed: _submit, child: const Icon(Icons.add_comment_outlined)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _items.isEmpty
                  ? const Center(child: Text('No submissions'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final m = _items[i] as Map<String, dynamic>;
                        return ListTile(
                          leading: const Icon(Icons.article_outlined),
                          title: Text(m['category']?.toString() ?? ''),
                          subtitle: Text((m['answers'] ?? {}).toString()),
                        );
                      },
                    ),
    );
  }
}


