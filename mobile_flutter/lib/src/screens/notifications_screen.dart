import 'dart:convert';
import 'package:flutter/material.dart';
import '../auth/api_client.dart';
import '../auth/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.get('/notifications/');
      if (res.statusCode == 200) {
        setState(() {
          _data = jsonDecode(res.body) as Map<String, dynamic>;
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
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...(((_data?['upcoming_appointments']) as List? ?? [])).map((e) => ListTile(
                          leading: const Icon(Icons.event),
                          title: Text(e['title']?.toString() ?? ''),
                          subtitle: Text(e['scheduled_for']?.toString() ?? ''),
                        )),
                    const SizedBox(height: 12),
                    const Text('Medication', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...(((_data?['medication_reminders']) as List? ?? [])).map((e) => ListTile(
                          leading: const Icon(Icons.medication),
                          title: Text(e['name']?.toString() ?? ''),
                          subtitle: Text('Time: ${e['reminder_time'] ?? ''}'),
                        )),
                    const SizedBox(height: 12),
                    const Text('Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...(((_data?['alerts']) as List? ?? [])).map((e) {
                      final m = e as Map<String, dynamic>;
                      return ListTile(
                        leading: const Icon(Icons.warning_amber_outlined),
                        title: Text(m['alert_type']?.toString() ?? ''),
                        subtitle: Text(m['message']?.toString() ?? ''),
                        trailing: Wrap(spacing: 8, children: [
                          OutlinedButton(onPressed: () async {
                            final id = m['id'];
                            if (id != null) {
                              await ApiClient.post('/alerts/$id/acknowledge/', {});
                              _load();
                            }
                          }, child: const Text('Acknowledge')),
                          OutlinedButton(onPressed: () async {
                            final id = m['id'];
                            if (id != null) {
                              await ApiClient.post('/alerts/$id/snooze/', {});
                              _load();
                            }
                          }, child: const Text('Snooze')),
                        ]),
                      );
                    })
                  ],
                ),
    );
  }
}


