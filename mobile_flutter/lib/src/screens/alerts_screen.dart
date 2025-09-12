import 'dart:convert';
import 'package:flutter/material.dart';
import '../auth/api_client.dart';
import '../auth/auth_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
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
      final res = await ApiClient.get('/alerts/');
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
      appBar: AppBar(title: const Text('Alerts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _items.isEmpty
                  ? const Center(child: Text('No alerts'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final a = _items[i] as Map<String, dynamic>;
                        return ListTile(
                          leading: const Icon(Icons.warning_amber_outlined),
                          title: Text(a['alert_type']?.toString() ?? ''),
                          subtitle: Text(a['message']?.toString() ?? ''),
                          trailing: Text(a['severity']?.toString() ?? ''),
                        );
                      },
                    ),
    );
  }
}


