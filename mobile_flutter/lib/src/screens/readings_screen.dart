import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';

class ReadingsScreen extends StatefulWidget {
  const ReadingsScreen({super.key});

  @override
  State<ReadingsScreen> createState() => _ReadingsScreenState();
}

class _ReadingsScreenState extends State<ReadingsScreen> {
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
      final prefs = await SharedPreferences.getInstance();
      final access = prefs.getString('access');
      final res = await http
          .get(Uri.parse('${AuthProvider.baseUrl}/device-readings/'), headers: {
        'Authorization': 'Bearer ${access ?? ''}',
      }).timeout(const Duration(seconds: 15));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Readings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _items.isEmpty
                  ? const Center(child: Text('No readings'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final r = _items[i] as Map<String, dynamic>;
                        final type = r['reading_type']?.toString() ?? '';
                        final value = r['value']?.toString() ?? '';
                        final unit = r['unit']?.toString() ?? '';
                        final t = r['recorded_at']?.toString() ?? '';
                        return ListTile(
                          leading: const Icon(Icons.monitor_heart_outlined),
                          title: Text('$type  $value$unit'),
                          subtitle: Text(t),
                        );
                      },
                    ),
    );
  }
}


