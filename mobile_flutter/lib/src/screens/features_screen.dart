import 'package:flutter/material.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NCD App')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Welcome!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Choose a feature:'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/readings'),
            child: const Text('Readings'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/risk'),
            child: const Text('Risk'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/alerts'),
            child: const Text('Alerts'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            child: const Text('Notifications'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/medications'),
            child: const Text('Medications'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/appointments'),
            child: const Text('Appointments'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/analytics'),
            child: const Text('Analytics'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/education'),
            child: const Text('Education'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/questionnaires'),
            child: const Text('Questionnaires'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/support-groups'),
            child: const Text('Support Groups'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/quizzes'),
            child: const Text('Quizzes'),
          ),
        ],
      ),
    );
  }
}


