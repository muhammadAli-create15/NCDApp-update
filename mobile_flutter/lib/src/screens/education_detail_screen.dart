import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/educational_content.dart';
import '../services/education_service.dart';

class EducationDetailScreen extends StatefulWidget {
  final EducationalContent content;
  
  const EducationDetailScreen({
    Key? key,
    required this.content,
  }) : super(key: key);
  
  @override
  _EducationDetailScreenState createState() => _EducationDetailScreenState();
}

class _EducationDetailScreenState extends State<EducationDetailScreen> {
  late EducationalContent _content;
  final EducationService _educationService = EducationService();
  
  @override
  void initState() {
    super.initState();
    _content = widget.content;
    // Mark content as read when opened
    _markAsRead();
  }
  
  Future<void> _markAsRead() async {
    await _educationService.markAsRead(_content.contentId);
    if (mounted) {
      setState(() {
        _content = _content.copyWith(isRead: true);
      });
    }
  }
  
  void _toggleSaved() async {
    final newSavedState = !_content.isSaved;
    await _educationService.saveContent(_content.contentId, newSavedState);
    
    if (mounted) {
      setState(() {
        _content = _content.copyWith(isSaved: newSavedState);
      });
      
      // Show feedback to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newSavedState 
              ? 'Saved to your favorites' 
              : 'Removed from favorites'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _content.category.name,
          style: const TextStyle(fontSize: 16.0),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _content.isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _content.isSaved ? Colors.amber : null,
            ),
            onPressed: _toggleSaved,
            tooltip: _content.isSaved ? 'Remove from saved' : 'Save for later',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality would be implemented here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon!')),
              );
            },
            tooltip: 'Share this advice',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                _content.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              
              // Main content
              Text(
                _content.body,
                style: const TextStyle(
                  fontSize: 16.0,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24.0),
              
              // Actionable steps section
              if (_content.actionableSteps.isNotEmpty) ...[
                _buildSectionTitle('What You Can Do'),
                const SizedBox(height: 8.0),
                _buildActionableSteps(),
                const SizedBox(height: 24.0),
              ],
              
              // References section
              if (_content.references.isNotEmpty) ...[
                _buildSectionTitle('Learn More'),
                const SizedBox(height: 8.0),
                _buildReferences(),
                const SizedBox(height: 24.0),
              ],
              
              // Last updated info
              Text(
                'Last updated: ${_formatDate(_content.lastUpdated)}',
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
  
  Widget _buildActionableSteps() {
    return Column(
      children: _content.actionableSteps.map((step) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 20.0,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  step,
                  style: const TextStyle(fontSize: 16.0),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildReferences() {
    return Column(
      children: _content.references.map((reference) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: GestureDetector(
            onTap: () => _launchURL(reference),
            child: Row(
              children: [
                const Icon(Icons.link, size: 16.0, color: Colors.blue),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    _formatUrl(reference),
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildBottomActionBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.calendar_today,
              label: 'Set Reminder',
              onTap: () {
                // Reminder functionality would be implemented here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder functionality coming soon!')),
                );
              },
            ),
            const SizedBox(width: 16),
            _buildActionButton(
              icon: Icons.track_changes,
              label: 'Track Progress',
              onTap: () {
                // Progress tracking functionality would be implemented here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Progress tracking coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18.0),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
        ),
      ),
    );
  }
  
  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  // Helper method to format URL for display
  String _formatUrl(String url) {
    // Remove http/https prefix and trailing slash for display
    return url.replaceAll(RegExp(r'(https?:\/\/)|(www\.)'), '').replaceAll(RegExp(r'\/$'), '');
  }
  
  // Helper method to launch URL
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    }
  }
}