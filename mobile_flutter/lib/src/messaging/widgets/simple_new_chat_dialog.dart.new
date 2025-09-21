import 'package:flutter/material.dart';
import '../screens/screens.dart';
import '../models/models.dart';

// A simplified version of the NewChatDialog that will work without errors
class SimpleNewChatDialog extends StatefulWidget {
  const SimpleNewChatDialog({super.key});

  @override
  State<SimpleNewChatDialog> createState() => _SimpleNewChatDialogState();
}

class _SimpleNewChatDialogState extends State<SimpleNewChatDialog> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _mockUsers = [
    'Dr. John Smith',
    'Nurse Mary Johnson',
    'Patient Support Group',
    'Diabetes Care Team',
    'Heart Health Specialists',
    'Community Health Educators'
  ];
  List<String> _filteredUsers = [];
  String _selectedUser = '';

  @override
  void initState() {
    super.initState();
    _filteredUsers = List.from(_mockUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_mockUsers);
      } else {
        _filteredUsers = _mockUsers
            .where((user) => user.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _startChat() {
    if (_selectedUser.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user to chat with')),
      );
      return;
    }
    
    // In a real app, we would create a chat with the selected user
    Navigator.pop(context);
    
    // Mock chat data
    final mockChat = Chat(
      id: 'mock-chat-${DateTime.now().millisecondsSinceEpoch}',
      name: _selectedUser,
      type: ChatType.direct,
      participantIds: ['current-user', 'selected-user'],
      createdAt: DateTime.now(),
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomMessagingScreen(chatId: mockChat.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'New Conversation',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          
          // Info text
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.blue),
                  SizedBox(height: 16),
                  Text(
                    'Coming Soon',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Direct messaging functionality is under development',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  Text(
                    'You can use Support Groups for community discussions',
                    style: TextStyle(fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/support-groups');
              },
              child: const Text('Go to Support Groups'),
            ),
          )
        ],
      ),
    );
  }
}