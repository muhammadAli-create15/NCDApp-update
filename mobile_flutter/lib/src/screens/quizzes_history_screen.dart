import 'dart:convert';
import 'package:flutter/material.dart';
import '../auth/api_client.dart';

class QuizzesHistoryScreen extends StatefulWidget {
  const QuizzesHistoryScreen({super.key});

  @override
  State<QuizzesHistoryScreen> createState() => _QuizzesHistoryScreenState();
}

class _QuizzesHistoryScreenState extends State<QuizzesHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.get('/quiz-responses/');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final m = Map<String, dynamic>.from(_items[i] as Map);
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text('Score: ${m['score'] ?? '-'}'),
                      subtitle: Text('Submitted: ${m['submitted_at'] ?? ''}'),
                    );
                  },
                ),
    );
  }
}


