import 'package:flutter/material.dart';
import 'dart:math';

class QuestionnairesScreen extends StatefulWidget {
  const QuestionnairesScreen({super.key});

  @override
  State<QuestionnairesScreen> createState() => _QuestionnairesScreenState();
}

class _QuestionnairesScreenState extends State<QuestionnairesScreen> {
  final List<Map<String, dynamic>> _questionnaires = [
    {
      'id': '1',
      'title': 'Diabetes Risk Assessment',
      'description': 'Assess your risk for developing Type 2 Diabetes',
      'questions': 8,
      'status': 'completed',
      'completedDate': DateTime.now().subtract(const Duration(days: 15)),
      'icon': Icons.monitor_heart_outlined,
      'color': Colors.red.shade100,
      'iconColor': Colors.red,
    },
    {
      'id': '2',
      'title': 'Cardiovascular Health Assessment',
      'description': 'Evaluate your heart health and cardiovascular risks',
      'questions': 10,
      'status': 'in_progress',
      'icon': Icons.favorite_outline,
      'color': Colors.blue.shade100,
      'iconColor': Colors.blue,
    },
    {
      'id': '3',
      'title': 'Mental Health Screening',
      'description': 'Screen for anxiety, depression and overall mental wellbeing',
      'questions': 12,
      'status': 'not_started',
      'icon': Icons.psychology_outlined,
      'color': Colors.purple.shade100,
      'iconColor': Colors.purple,
    },
    {
      'id': '4',
      'title': 'Lifestyle & Habits Assessment',
      'description': 'Assess your lifestyle habits that impact health',
      'questions': 15,
      'status': 'not_started',
      'icon': Icons.self_improvement_outlined,
      'color': Colors.green.shade100,
      'iconColor': Colors.green,
    },
    {
      'id': '5',
      'title': 'Hypertension Risk Assessment',
      'description': 'Evaluate your risk factors for high blood pressure',
      'questions': 7,
      'status': 'not_started',
      'icon': Icons.trending_up,
      'color': Colors.orange.shade100,
      'iconColor': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Questionnaires'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showCompletedHistory(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          ..._questionnaires.map((questionnaire) => _buildQuestionnaireCard(questionnaire)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final completedCount = _questionnaires.where((q) => q['status'] == 'completed').length;
    
    return Card(
      elevation: 3,
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Health Assessment Tools',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                const Spacer(),
                Text(
                  '$completedCount/${_questionnaires.length} completed',
                  style: TextStyle(color: Colors.teal.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete these questionnaires to help us assess your health status and risk factors. Your responses will help create personalized health recommendations.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionnaireCard(Map<String, dynamic> questionnaire) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: questionnaire['color'],
              child: Icon(questionnaire['icon'], color: questionnaire['iconColor']),
            ),
            title: Text(questionnaire['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${questionnaire['questions']} questions'),
            trailing: _getStatusIcon(questionnaire['status']),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(questionnaire['description']),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusChip(questionnaire['status']),
                    if (questionnaire['status'] == 'completed')
                      Text(
                        'Completed on ${_formatDate(questionnaire['completedDate'])}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => _onQuestionnaireSelected(questionnaire),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getButtonColor(questionnaire['status']),
                      ),
                      child: Text(_getButtonText(questionnaire['status'])),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'in_progress':
        return const Icon(Icons.access_time, color: Colors.orange);
      default:
        return const Icon(Icons.circle_outlined, color: Colors.grey);
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'completed':
        color = Colors.green;
        text = 'Completed';
        break;
      case 'in_progress':
        color = Colors.orange;
        text = 'In Progress';
        break;
      default:
        color = Colors.grey;
        text = 'Not Started';
    }
    
    return Chip(
      label: Text(text),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color, fontSize: 12),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Color _getButtonColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.teal;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _getButtonText(String status) {
    switch (status) {
      case 'completed':
        return 'View Results';
      case 'in_progress':
        return 'Continue';
      default:
        return 'Start';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _onQuestionnaireSelected(Map<String, dynamic> questionnaire) {
    // In a real app, navigate to the questionnaire
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(questionnaire['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(questionnaire['description']),
            const SizedBox(height: 16),
            Text('Status: ${_statusToString(questionnaire['status'])}'),
            const SizedBox(height: 8),
            if (questionnaire['status'] == 'completed')
              Text('Completed on: ${_formatDate(questionnaire['completedDate'])}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, navigate to the questionnaire or results screen
              _showQuestionnairePreview(questionnaire);
            },
            child: Text(_getButtonText(questionnaire['status'])),
          ),
        ],
      ),
    );
  }

  String _statusToString(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      default:
        return 'Not Started';
    }
  }

  void _showCompletedHistory(BuildContext context) {
    final completed = _questionnaires.where((q) => q['status'] == 'completed').toList();
    
    if (completed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No completed questionnaires yet')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completed Questionnaires'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: completed.length,
            itemBuilder: (context, index) {
              final item = completed[index];
              return ListTile(
                leading: Icon(item['icon'], color: item['iconColor']),
                title: Text(item['title']),
                subtitle: Text('Completed on ${_formatDate(item['completedDate'])}'),
                onTap: () {
                  Navigator.pop(context);
                  _onQuestionnaireSelected(item);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showQuestionnairePreview(Map<String, dynamic> questionnaire) {
    // Generate sample questions based on questionnaire type
    List<Map<String, dynamic>> questions = [];
    
    if (questionnaire['title'].contains('Diabetes')) {
      questions = [
        {'question': 'Do you have a family history of diabetes?', 'options': ['Yes', 'No']},
        {'question': 'What is your age range?', 'options': ['Under 40', '40-60', 'Over 60']},
        {'question': 'Is your BMI above 25?', 'options': ['Yes', 'No', 'I don\'t know']},
      ];
    } else if (questionnaire['title'].contains('Cardiovascular')) {
      questions = [
        {'question': 'Do you smoke?', 'options': ['Yes', 'No', 'Formerly']},
        {'question': 'Do you exercise regularly?', 'options': ['Yes', 'No', 'Occasionally']},
        {'question': 'Do you have high blood pressure?', 'options': ['Yes', 'No', 'Not sure']},
      ];
    } else {
      // Generic questions
      questions = [
        {'question': 'How would you rate your overall health?', 'options': ['Excellent', 'Good', 'Fair', 'Poor']},
        {'question': 'How many hours of sleep do you get per night?', 'options': ['Less than 6', '6-8', 'More than 8']},
        {'question': 'Do you follow any specific diet?', 'options': ['No special diet', 'Low-carb', 'Vegetarian', 'Other']},
      ];
    }
    
    // Show sample question
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(questions[0]['question']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.generate(questions[0]['options'].length, (index) {
              return RadioListTile(
                title: Text(questions[0]['options'][index]),
                value: index,
                groupValue: null,
                onChanged: (_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This is just a preview. Full functionality coming soon!')),
                  );
                },
              );
            }),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: 1 / questionnaire['questions']),
            const SizedBox(height: 4),
            Text('Question 1 of ${questionnaire['questions']}', 
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This is just a preview. Full functionality coming soon!')),
              );
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

