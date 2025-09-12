import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth/auth_provider.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  List<String> _recs = [];
  bool _loading = false;
  String? _error;
  List<dynamic> _items = [];
  List<dynamic> _topics = [];
  String _filter = 'all';

  Future<void> _loadRecommendations() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final token = auth.access;
      final res = await ApiClient.get('/recommendations/');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final List<dynamic> tips = data['recommendations'] ?? [];
        setState(() {
          _recs = tips.map((e) => e.toString()).toList();
        });
      } else {
        setState(() {
          _error = 'Failed to load recommendations (${res.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error loading recommendations';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.get('/education/');
      final tp = await ApiClient.get('/education/topics/');
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
      body: RefreshIndicator(
        onRefresh: _loadRecommendations,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Personalized Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_recs.isNotEmpty)
              ..._recs.map((r) => ListTile(leading: const Icon(Icons.check_circle_outline, color: Colors.teal), title: Text(r))).toList(),
            if (!_loading && _recs.isEmpty && _error == null)
              const Text('No recommendations yet. Pull to refresh.'),
            const SizedBox(height: 24),
            const Text('Education Library', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Explore articles, videos, and quizzes to support your health journey.'),
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
            ...filtered.map((e) {
              final m = e as Map<String, dynamic>;
              final media = m['media_url']?.toString() ?? '';
              return ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(m['title']?.toString() ?? ''),
                subtitle: Text((m['content']?.toString() ?? '').isEmpty ? media : m['content']?.toString() ?? ''),
                trailing: Text(m['topic']?.toString() ?? ''),
                onTap: () async {
                  if (media.startsWith('http')) {
                    final uri = Uri.parse(media);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}


