import 'package:flutter/material.dart';

import '../models/models.dart';
import '../repositories/support_group_repository.dart';
import 'support_group_detail_screen.dart';

/// Screen for browsing all available support groups
class SupportGroupsScreen extends StatefulWidget {
  const SupportGroupsScreen({Key? key}) : super(key: key);

  @override
  State<SupportGroupsScreen> createState() => _SupportGroupsScreenState();
}

class _SupportGroupsScreenState extends State<SupportGroupsScreen> {
  final SupportGroupRepository _repository = SupportGroupRepository();
  bool _isLoading = true;
  List<SupportGroup> _groups = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final groups = await _repository.fetchGroups();
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load support groups: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Support Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchGroups,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchGroups,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_groups.isEmpty) {
      return const Center(
        child: Text('No support groups available at this time.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return _buildGroupCard(group);
        },
      ),
    );
  }

  Widget _buildGroupCard(SupportGroup group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to group detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SupportGroupDetailScreen(
                groupId: group.groupId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header with icon
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Image.asset(
                      group.iconUrl,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback icon if the image fails to load
                        return Icon(
                          Icons.group,
                          size: 32,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last updated: ${_formatDate(group.lastUpdated)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Group description
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: Text(
                group.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Join button
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to group detail screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SupportGroupDetailScreen(
                            groupId: group.groupId,
                          ),
                        ),
                      );
                    },
                    child: const Text('View Discussion'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to group guidelines screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SupportGroupGuidelinesScreen(
                            group: group,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Guidelines'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple date formatting
    return '${date.day}/${date.month}/${date.year}';
  }
}

