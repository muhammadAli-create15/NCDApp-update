import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/chat_provider.dart';
import '../screens/screens.dart';

class NewChatDialog extends StatefulWidget {
  const NewChatDialog({Key? key}) : super(key: key);

  @override
  State<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<NewChatDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<ChatUser> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    
    if (_searchQuery.length >= 2) {
      _searchUsers(_searchQuery);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) return;
    
    setState(() => _isLoading = true);
    
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final users = await chatProvider.chatService.searchUsers(query);
      
      if (mounted) {
        setState(() {
          _searchResults = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching users: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startChat(ChatUser user) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final chat = await chatProvider.chatService.createDirectChat(user.id);
      
      // Pop loading dialog
      Navigator.of(context).pop();
      
      if (chat != null) {
        // Pop the new chat dialog
        Navigator.of(context).pop();
        
        // Navigate to the chat screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MessagingScreen(chatId: chat.id),
          ),
        );
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create chat')),
        );
      }
    } catch (e) {
      // Pop loading dialog
      Navigator.of(context).pop();
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
            children: [
              const Text(
                'New Message',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          
          // Search field
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search for users...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
              ),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16.0),
          
          // Results
          Expanded(
            child: _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_searchQuery.isEmpty || _searchQuery.length < 2) {
      return const Center(child: Text('Type at least 2 characters to search'));
    }
    
    if (_searchResults.isEmpty) {
      return const Center(child: Text('No users found'));
    }
    
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(user.firstName[0] + user.lastName[0])
                : null,
          ),
          title: Text(user.fullName),
          onTap: () => _startChat(user),
        );
      },
    );
  }
}