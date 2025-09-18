import 'package:flutter/material.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final List<Map<String, String>> _alerts = [
    {'title': 'Blood Pressure Check Due', 'message': 'Your next blood pressure reading is due today.', 'time': '2 hours ago'},
    {'title': 'Medication Reminder', 'message': 'Time to take your morning medications.', 'time': '30 minutes ago'},
    {'title': 'Appointment Tomorrow', 'message': 'Doctor appointment at 10:00 AM tomorrow.', 'time': '1 day ago'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _alerts.isEmpty
          ? const Center(
              child: Text('No alerts available', style: TextStyle(fontSize: 16)),
            )
          : ListView.builder(
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      alert['title']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert['message']!),
                        const SizedBox(height: 4),
                        Text(
                          alert['time']!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}


