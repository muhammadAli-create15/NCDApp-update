import 'dart:convert';
import 'package:flutter/material.dart';
import '../auth/api_client.dart';
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
  List<dynamic> _templates = [];


  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resMy = await ApiClient.get('/questionnaires/my/');
      final tp = await ApiClient.get('/questionnaire-templates/');
      var items = <dynamic>[];
      if (resMy.statusCode == 200) {
        items = (jsonDecode(resMy.body) as List<dynamic>);
      } else {
        // Fallback to generic endpoint for older backends
        final resAll = await ApiClient.get('/questionnaires/');
        if (resAll.statusCode == 200) {
          items = (jsonDecode(resAll.body) as List<dynamic>);
        }
      }
      setState(() {
        _items = items;
        _templates = tp.statusCode == 200 ? (jsonDecode(tp.body) as List<dynamic>) : [];
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
            Semantics(
              label: 'exercise_days_per_week',
              child: TextField(
                controller: _exercise,
                decoration: const InputDecoration(labelText: 'Exercise days/week', helperText: 'exercise_days_per_week'),
                keyboardType: TextInputType.number,
                enableSuggestions: false,
                autocorrect: false,
              ),
            ),
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
              final res = await ApiClient.post('/questionnaires/', jsonDecode(body) as Map<String, dynamic>);
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

  void _openTemplateForm(dynamic tpl) {
    final tplMap = Map<String, dynamic>.from((tpl as Map));
    final schema = Map<String, dynamic>.from((tplMap['schema'] ?? {}) as Map);
    final props = Map<String, dynamic>.from((schema['properties'] ?? {}) as Map);
    final controllers = <String, TextEditingController>{};
    final boolValues = <String, bool>{};
    final enumValues = <String, String>{};
    props.forEach((key, def) {
      final m = def as Map<String, dynamic>;
      final type = (m['type'] ?? '').toString();
      if (type == 'boolean') {
        boolValues[key] = false;
      } else if (m['enum'] is List) {
        enumValues[key] = (m['enum'] as List).first.toString();
      } else {
        controllers[key] = TextEditingController();
      }
    });
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: Text(tplMap['name']?.toString() ?? 'Questionnaire'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...props.entries.map((e) {
                  final key = e.key;
                  final def = e.value as Map<String, dynamic>;
                  final type = (def['type'] ?? '').toString();
                  if (type == 'boolean') {
                    return SwitchListTile(
                      value: boolValues[key] ?? false,
                      onChanged: (v) => setS(() => boolValues[key] = v),
                      title: Text(key.replaceAll('_', ' ')),
                    );
                  } else if (def['enum'] is List) {
                    final opts = (def['enum'] as List).map((v) => v.toString()).toList();
                    return DropdownButtonFormField<String>(
                      value: enumValues[key] ?? opts.first,
                      items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                      onChanged: (v) => setS(() => enumValues[key] = v ?? opts.first),
                      decoration: InputDecoration(labelText: key.replaceAll('_', ' ')),
                    );
                  } else {
                    return Semantics(
                      label: key,
                      child: TextField(
                        controller: controllers[key],
                        decoration: InputDecoration(labelText: key.replaceAll('_', ' '), helperText: key),
                        keyboardType: TextInputType.number,
                        enableSuggestions: false,
                        autocorrect: false,
                      ),
                    );
                  }
                }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final answers = <String, dynamic>{};
                props.forEach((key, def) {
                  final m = def as Map<String, dynamic>;
                  if ((m['type'] ?? '') == 'boolean') {
                    answers[key] = boolValues[key] ?? false;
                  } else if (m['enum'] is List) {
                    answers[key] = enumValues[key];
                  } else {
                    final val = controllers[key]?.text ?? '';
                    answers[key] = int.tryParse(val) ?? val;
                  }
                });
                final payload = {
                  'category': tplMap['category']?.toString() ?? 'general',
                  'answers': answers,
                };
                final res = await ApiClient.post('/questionnaires/', payload);
                if (!mounted) return;
                Navigator.pop(context);
                if (res.statusCode == 201) {
                  _load();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res.statusCode}')));
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Questionnaires')),
      floatingActionButton: PopupMenuButton<Map<String, dynamic>>(
        icon: const Icon(Icons.add_comment_outlined),
        onSelected: (tpl) => _openTemplateForm(tpl),
        itemBuilder: (_) => [
          ..._templates.map((t) => PopupMenuItem<Map<String, dynamic>>(
            value: t as Map<String, dynamic>,
            child: Text((t['name'] ?? t['category'] ?? 'Template').toString()),
          ))
        ],
      ),
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


