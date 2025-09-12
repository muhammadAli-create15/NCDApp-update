import 'dart:convert';
import 'package:flutter/material.dart';
import '../auth/api_client.dart';

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.get('/quizzes/');
      setState(() {
        _quizzes = res.statusCode == 200 ? (jsonDecode(res.body) as List<dynamic>) : [];
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
      appBar: AppBar(title: const Text('Quizzes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  itemCount: _quizzes.length,
                  itemBuilder: (_, i) {
                    final q = _quizzes[i] as Map<String, dynamic>;
                    final title = q['title']?.toString() ?? 'Quiz';
                    final n = (q['questions'] as List?)?.length ?? 0;
                    return ListTile(
                      leading: const Icon(Icons.quiz_outlined),
                      title: Text(title),
                      subtitle: Text('$n questions'),
                      trailing: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/quiz', arguments: q),
                        child: const Text('Start'),
                      ),
                    );
                  },
                ),
    );
  }
}


