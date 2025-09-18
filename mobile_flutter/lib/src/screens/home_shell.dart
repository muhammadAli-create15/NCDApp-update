import 'package:flutter/material.dart';
import 'features_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _features = [
    {'title': 'Dashboard', 'icon': Icons.dashboard, 'route': '/'},
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

  void _onFeatureTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pushNamed(context, _features[index]['route']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NCD App')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ..._features.asMap().entries.map((entry) {
              int idx = entry.key;
              var feature = entry.value;
              return ListTile(
                leading: Icon(feature['icon']),
                title: Text(feature['title']),
                selected: idx == _selectedIndex,
                onTap: () => _onFeatureTap(idx),
              );
            }).toList(),
          ],
        ),
      ),
      body: const FeaturesScreen(),
    );
  }
}


