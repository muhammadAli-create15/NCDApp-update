import 'dart:convert';
import 'package:flutter/material.dart';
import '../auth/api_client.dart';

class QuizAttemptScreen extends StatefulWidget {
  const QuizAttemptScreen({super.key});

  @override
  State<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends State<QuizAttemptScreen> {
  Map<String, dynamic>? _quiz;
  final Map<int, int> _answers = {};
  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _quiz = Map<String, dynamic>.from(args as Map);
    }
  }

  Future<void> _submit() async {
    if (_quiz == null) return;
    setState(() { _submitting = true; });
    final quizId = _quiz!['id'] as int;
    final ordered = _answers.keys.toList()..sort();
    final answers = ordered.map((k) => _answers[k] ?? 0).toList();
    final resp = await ApiClient.post('/quiz-responses/', {
      'quiz': quizId,
      'answers': answers,
    });
    setState(() { _submitting = false; });
    if (!mounted) return;
    if (resp.statusCode == 201) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final score = (data['score'] as int?) ?? 0;
      final total = (data['total'] as int?) ?? ((_quiz?['questions'] as List?)?.length ?? 0);
      final passed = total > 0 ? (score / total) >= 0.7 : false;
      final explanations = (data['explanations'] as List?) ?? [];
      final suggestions = (data['education_suggestions'] as List?) ?? [];
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('Quiz Result'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Score: $score / $total\n${passed ? 'Pass' : 'Keep learning'}'),
              const SizedBox(height: 12),
              const Text('Review', style: TextStyle(fontWeight: FontWeight.bold)),
              ...explanations.map((e){
                final m = Map<String, dynamic>.from(e as Map);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('${m['is_correct']==true? '✓':'✗'} ${m['question']}\nCorrect: ${m['correct_choice'] ?? ''}'),
                );
              }).toList(),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Suggested reading', style: TextStyle(fontWeight: FontWeight.bold)),
                ...suggestions.map((s){
                  final m = Map<String, dynamic>.from(s as Map);
                  return Text('• ${m['title'] ?? ''}');
                }).toList(),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pushReplacementNamed(context, '/education'); }, child: const Text('See Education')),
        ],
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit failed: ${resp.statusCode}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = (_quiz?['questions'] as List?) ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(_quiz?['title']?.toString() ?? 'Quiz')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (_, i) {
          final q = Map<String, dynamic>.from(questions[i] as Map);
          final choices = (q['choices'] as List?)?.cast<String>() ?? [];
          final selected = _answers[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q${i+1}. ${q['text']?.toString() ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...choices.asMap().entries.map((e){
                    final idx = e.key;
                    final label = e.value;
                    return RadioListTile<int>(
                      value: idx,
                      groupValue: selected,
                      onChanged: (v)=> setState(()=> _answers[i] = v ?? 0),
                      title: Text(label),
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submitting ? null : _submit,
        child: _submitting ? const CircularProgressIndicator() : const Icon(Icons.send),
      ),
    );
  }
}


