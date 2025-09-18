import 'package:flutter/material.dart';
import 'user_history_card.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  final List<Map<String, dynamic>> _features = const [
    {'title': 'Readings', 'icon': Icons.bar_chart, 'route': '/readings'},
    {'title': 'Risk', 'icon': Icons.health_and_safety, 'route': '/risk'},
    {'title': 'Alerts', 'icon': Icons.notifications_active, 'route': '/alerts'},
    {'title': 'Notifications', 'icon': Icons.notifications, 'route': '/notifications'},
    {'title': 'Medications', 'icon': Icons.medication, 'route': '/medications'},
    {'title': 'Appointments', 'icon': Icons.event, 'route': '/appointments'},
    {'title': 'Analytics', 'icon': Icons.analytics, 'route': '/analytics'},
    {'title': 'Education', 'icon': Icons.school, 'route': '/education'},
    {'title': 'Questionnaires', 'icon': Icons.assignment, 'route': '/questionnaires'},
    {'title': 'Support Groups', 'icon': Icons.group, 'route': '/support-groups'},
    {'title': 'Quizzes', 'icon': Icons.quiz, 'route': '/quizzes'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Welcome!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Choose a feature:', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          // User history card
          const UserHistoryCard(),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: _features.map((feature) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pushNamed(context, feature['route']),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(feature['icon'], size: 40, color: Theme.of(context).primaryColor),
                          const SizedBox(height: 12),
                          Text(feature['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}


