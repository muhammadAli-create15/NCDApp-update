import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class SupportGroupsScreen extends StatefulWidget {
  const SupportGroupsScreen({super.key});

  @override
  State<SupportGroupsScreen> createState() => _SupportGroupsScreenState();
}

class _SupportGroupsScreenState extends State<SupportGroupsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  
  final List<Map<String, dynamic>> _groups = [
    {
      'id': '1',
      'name': 'Diabetes Warriors',
      'description': 'Support group for individuals living with Type 1 and Type 2 Diabetes',
      'members': 128,
      'category': 'Diabetes',
      'isPublic': true,
      'isMember': true,
      'unreadPosts': 5,
      'lastActive': DateTime.now().subtract(const Duration(hours: 2)),
      'image': 'assets/support_diabetes.jpg',
      'color': Colors.blue.shade100,
      'posts': 347,
      'moderators': ['Dr. Sarah Johnson', 'Michael Chen'],
      'upcomingMeeting': DateTime.now().add(const Duration(days: 3, hours: 4)),
      'meetingType': 'Virtual',
    },
    {
      'id': '2',
      'name': 'Heart Health Network',
      'description': 'For those recovering from or managing cardiovascular conditions',
      'members': 94,
      'category': 'Cardiovascular',
      'isPublic': true,
      'isMember': false,
      'lastActive': DateTime.now().subtract(const Duration(days: 1, hours: 8)),
      'image': 'assets/support_heart.jpg',
      'color': Colors.red.shade100,
      'posts': 215,
      'moderators': ['Dr. James Wilson', 'Emma Taylor'],
      'upcomingMeeting': DateTime.now().add(const Duration(days: 7, hours: 2)),
      'meetingType': 'In Person',
    },
    {
      'id': '3',
      'name': 'Hypertension Support Circle',
      'description': 'Sharing experiences and strategies for managing high blood pressure',
      'members': 76,
      'category': 'Hypertension',
      'isPublic': true,
      'isMember': true,
      'unreadPosts': 0,
      'lastActive': DateTime.now().subtract(const Duration(days: 2, hours: 14)),
      'image': 'assets/support_hypertension.jpg',
      'color': Colors.orange.shade100,
      'posts': 183,
      'moderators': ['Dr. Patricia Lee', 'Robert Brown'],
      'upcomingMeeting': DateTime.now().add(const Duration(days: 5, hours: 6)),
      'meetingType': 'Virtual',
    },
    {
      'id': '4',
      'name': 'Obesity Management Group',
      'description': 'Support for weight management and healthy lifestyle changes',
      'members': 112,
      'category': 'Obesity',
      'isPublic': false,
      'isMember': false,
      'lastActive': DateTime.now().subtract(const Duration(days: 3, hours: 5)),
      'image': 'assets/support_obesity.jpg',
      'color': Colors.green.shade100,
      'posts': 278,
      'moderators': ['Dr. Lisa Murphy', 'Thomas Garcia'],
      'upcomingMeeting': DateTime.now().add(const Duration(days: 10, hours: 3)),
      'meetingType': 'In Person',
    },
    {
      'id': '5',
      'name': 'Mental Health & Chronic Disease',
      'description': 'Addressing mental health challenges while managing chronic conditions',
      'members': 67,
      'category': 'Mental Health',
      'isPublic': true,
      'isMember': true,
      'unreadPosts': 12,
      'lastActive': DateTime.now().subtract(const Duration(hours: 6)),
      'image': 'assets/support_mental.jpg',
      'color': Colors.purple.shade100,
      'posts': 152,
      'moderators': ['Dr. Michelle Wong', 'Daniel Smith'],
      'upcomingMeeting': DateTime.now().add(const Duration(days: 2, hours: 5)),
      'meetingType': 'Virtual',
    },
  ];

  final List<Map<String, dynamic>> _myEvents = [
    {
      'id': '1',
      'title': 'Diabetes Warriors Weekly Check-in',
      'group': 'Diabetes Warriors',
      'datetime': DateTime.now().add(const Duration(days: 3, hours: 4)),
      'duration': 60,
      'isVirtual': true,
      'link': 'https://meet.example.com/diabeteswarriors',
      'description': 'Weekly support group meeting to discuss challenges and successes in diabetes management.',
      'attendees': 18,
    },
    {
      'id': '2',
      'title': 'Mental Health Discussion Circle',
      'group': 'Mental Health & Chronic Disease',
      'datetime': DateTime.now().add(const Duration(days: 2, hours: 5)),
      'duration': 90,
      'isVirtual': true,
      'link': 'https://zoom.us/j/1234567890',
      'description': 'Group discussion on managing anxiety and depression while dealing with chronic health conditions.',
      'attendees': 12,
    },
    {
      'id': '3',
      'title': 'Hypertension Management Workshop',
      'group': 'Hypertension Support Circle',
      'datetime': DateTime.now().add(const Duration(days: 5, hours: 6)),
      'duration': 120,
      'isVirtual': true,
      'link': 'https://teams.microsoft.com/hypertension-group',
      'description': 'Workshop with Dr. Lee on lifestyle modifications for better blood pressure control.',
      'attendees': 25,
    },
  ];

  final List<Map<String, dynamic>> _samplePosts = [
    {
      'id': '1',
      'groupId': '1',
      'title': 'New research on continuous glucose monitoring',
      'content': 'Has anyone seen the latest research paper on CGM accuracy? It looks promising for more affordable options coming soon.',
      'author': 'Mark Wilson',
      'postedAt': DateTime.now().subtract(const Duration(hours: 2)),
      'comments': 5,
      'likes': 12,
    },
    {
      'id': '2',
      'groupId': '5',
      'title': 'Coping strategies that worked for me',
      'content': 'I\'ve been dealing with both diabetes and anxiety for 5+ years. Here are some techniques that have really helped me manage both conditions effectively...',
      'author': 'Jennifer Adams',
      'postedAt': DateTime.now().subtract(const Duration(hours: 6)),
      'comments': 8,
      'likes': 21,
    },
    {
      'id': '3',
      'groupId': '3',
      'title': 'DASH diet experiences',
      'content': 'I\'ve been following the DASH diet for hypertension for 3 months now. Has anyone else tried this? I\'m seeing some improvements in my numbers.',
      'author': 'Carlos Rodriguez',
      'postedAt': DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      'comments': 12,
      'likes': 8,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Groups'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Groups'),
            Tab(text: 'Discover'),
            Tab(text: 'Events'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Group messages feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyGroupsTab(),
          _buildDiscoverGroupsTab(),
          _buildEventsTab(),
        ],
      ),
      floatingActionButton: _selectedIndex == 2 
        ? null
        : FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Join Group'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Group joining feature coming soon!')),
              );
            },
          ),
    );
  }

  Widget _buildMyGroupsTab() {
    final myGroups = _groups.where((group) => group['isMember'] == true).toList();
    
    if (myGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('You haven\'t joined any groups yet'),
            SizedBox(height: 8),
            Text('Switch to the Discover tab to find groups'),
          ],
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildUnreadUpdatesCard(myGroups),
        const SizedBox(height: 16),
        ...myGroups.map((group) => _buildGroupCard(group)),
      ],
    );
  }

  Widget _buildUnreadUpdatesCard(List<Map<String, dynamic>> myGroups) {
    final totalUnread = myGroups.fold<int>(
      0, 
      (prev, group) => prev + (group['unreadPosts'] as int? ?? 0)
    );
    
    if (totalUnread == 0) {
      return const SizedBox.shrink();
    }
    
    return Card(
      color: Colors.teal.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal,
              child: Text(
                '$totalUnread',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'You have unread posts in your groups',
                style: TextStyle(fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This feature is coming soon!')),
                );
              },
              child: const Text('VIEW ALL'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupHeader(group),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group['description']),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(
                      Icons.people, 
                      '${group['members']} members'
                    ),
                    _buildInfoChip(
                      Icons.forum, 
                      '${group['posts']} posts'
                    ),
                    if (group['upcomingMeeting'] != null)
                      _buildInfoChip(
                        Icons.event, 
                        'Meeting in ${_getDaysUntil(group['upcomingMeeting'])}'
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active ${_getTimeAgo(group['lastActive'])}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (group['unreadPosts'] != null && group['unreadPosts'] > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${group['unreadPosts']} new',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.forum),
                        label: const Text('View Posts'),
                        onPressed: () => _showGroupPosts(group),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.event),
                        label: const Text('Join Meeting'),
                        onPressed: () => _showMeetingDetails(group),
                      ),
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

  Widget _buildGroupHeader(Map<String, dynamic> group) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: group['color'],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              _getCategoryIcon(group['category']),
              size: 48,
              color: Colors.white70,
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(group['name'][0], style: TextStyle(color: Colors.teal.shade700)),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Text(
              group['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
          ),
          if (group['isPublic'] == false)
            const Positioned(
              top: 16,
              right: 16,
              child: Icon(Icons.lock, color: Colors.white70),
            ),
        ],
      ),
    );
  }

  Widget _buildDiscoverGroupsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search support groups',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _searchController.clear(),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              ..._groups.where((group) => !group['isMember']).map((group) => _buildGroupCard(group)),
              const SizedBox(height: 80), // Extra padding at bottom for FAB
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildUpcomingEventCard(),
        const SizedBox(height: 16),
        const Text(
          'My Events',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._myEvents.map((event) => _buildEventCard(event)),
      ],
    );
  }

  Widget _buildUpcomingEventCard() {
    // Find the next upcoming event
    final nextEvent = _myEvents.reduce((a, b) => 
      a['datetime'].isBefore(b['datetime']) ? a : b);
    
    return Card(
      color: Colors.teal.shade50,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_available, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Next Upcoming Event',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              nextEvent['title'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Group: ${nextEvent['group']}'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEEE, MMM d • h:mm a').format(nextEvent['datetime']),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  nextEvent['isVirtual'] ? Icons.videocam : Icons.location_on,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  nextEvent['isVirtual'] ? 'Virtual Meeting' : 'In-person Meeting',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => _showEventDetails(nextEvent),
                  child: const Text('View Details'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Join event feature coming soon!')),
                    );
                  },
                  child: const Text('Join Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final isToday = event['datetime'].day == DateTime.now().day;
    final formattedDate = isToday
        ? 'Today, ${DateFormat('h:mm a').format(event['datetime'])}'
        : DateFormat('EEE, MMM d • h:mm a').format(event['datetime']);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isToday ? Colors.teal : Colors.grey.shade200,
          child: Icon(
            event['isVirtual'] ? Icons.videocam : Icons.event,
            color: isToday ? Colors.white : Colors.grey,
          ),
        ),
        title: Text(event['title']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(formattedDate),
            Text('Group: ${event["group"]}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () => _showEventDetails(event),
        ),
        onTap: () => _showEventDetails(event),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Diabetes':
        return Icons.monitor_heart;
      case 'Cardiovascular':
        return Icons.favorite;
      case 'Hypertension':
        return Icons.trending_up;
      case 'Obesity':
        return Icons.accessibility_new;
      case 'Mental Health':
        return Icons.psychology;
      default:
        return Icons.health_and_safety;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  String _getDaysUntil(DateTime dateTime) {
    final difference = dateTime.difference(DateTime.now());
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'tomorrow';
    } else {
      return '${difference.inDays} days';
    }
  }

  void _showGroupPosts(Map<String, dynamic> group) {
    final groupPosts = _samplePosts.where((post) => post['groupId'] == group['id']).toList();
    
    if (groupPosts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No posts available in this group')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        group['name'] + ' Posts',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: groupPosts.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final post = groupPosts[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                child: Text(post['author'][0]),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post['author'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _getTimeAgo(post['postedAt']),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            post['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(post['content']),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.thumb_up_outlined),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Like feature coming soon!')),
                                  );
                                },
                              ),
                              Text('${post['likes']}'),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.comment_outlined),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Comments feature coming soon!')),
                                  );
                                },
                              ),
                              Text('${post['comments']}'),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMeetingDetails(Map<String, dynamic> group) {
    final event = _myEvents.firstWhere(
      (e) => e['group'] == group['name'],
      orElse: () => {
        'title': '${group['name']} Meeting',
        'datetime': group['upcomingMeeting'],
        'duration': 60,
        'isVirtual': group['meetingType'] == 'Virtual',
        'link': 'https://meet.example.com/${group['id']}',
        'description': 'Regular support group meeting.',
        'attendees': Random().nextInt(20) + 5,
      },
    );
    
    _showEventDetails(event);
  }

  void _showEventDetails(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.group),
              title: Text('Group: ${event['group']}'),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(DateFormat('EEEE, MMMM d, yyyy').format(event['datetime'])),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(
                '${DateFormat('h:mm a').format(event['datetime'])} • ${event['duration']} minutes'
              ),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(event['isVirtual'] ? Icons.videocam : Icons.location_on),
              title: Text(event['isVirtual'] ? 'Virtual Meeting' : 'In-person Meeting'),
              subtitle: event['isVirtual'] ? Text('Link: ${event['link']}') : null,
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: Text('${event['attendees']} attending'),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(event['description']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (event['isVirtual'])
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Join meeting feature coming soon!')),
                );
              },
              child: const Text('Join Meeting'),
            ),
        ],
      ),
    );
  }
}


