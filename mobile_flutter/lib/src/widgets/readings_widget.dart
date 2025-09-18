import 'package:flutter/material.dart';
import '../models/patient_reading.dart';
import '../services/supabase_readings_service.dart';
import '../widgets/readings_entry_form.dart';
import '../widgets/readings_list_view.dart';

/// Main readings management component with role-based access
class ReadingsWidget extends StatefulWidget {
  const ReadingsWidget({super.key});

  @override
  State<ReadingsWidget> createState() => _ReadingsWidgetState();
}

class _ReadingsWidgetState extends State<ReadingsWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  bool _hasReadPermission = false;
  bool _hasWritePermission = false;
  bool _isCheckingPermissions = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkPermissions();
    _loadStats();
  }

  Future<void> _checkPermissions() async {
    // Always grant all permissions to all users
    if (mounted) {
      setState(() {
        _hasReadPermission = true;
        _hasWritePermission = true;
        _isCheckingPermissions = false;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await SupabaseReadingsService.getReadingsStats();
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  void _showNewReadingForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingsEntryForm(
          onSuccess: () {
            _loadStats();
            // Refresh the list view if it's the current tab
            if (_tabController.index == 1) {
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Skip loading state and permission checks
    // Always grant access to all features
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Readings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(
              icon: Icon(Icons.dashboard),
              text: 'Dashboard',
            ),
            const Tab(
              icon: Icon(Icons.list),
              text: 'View Records',
            ),
            // Always show the tab regardless of write permission
            const Tab(
              icon: Icon(Icons.add_circle),
              text: 'New Reading',
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Skip permission check, just reload stats
              _loadStats();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboard(),
          ReadingsListView(
            onRefresh: _loadStats,
          ),
          // Always show the new reading tab
          _buildNewReadingTab(),
        ],
      ),
      floatingActionButton: true // Always show the FAB
          ? FloatingActionButton(
              onPressed: _showNewReadingForm,
              tooltip: 'Add New Reading',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Statistics cards
            _buildStatsGrid(),
            
            const SizedBox(height: 24),
            
            // Quick actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildQuickActions(),
            
            const SizedBox(height: 24),
            
            // Recent readings preview
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          title: 'Total Readings',
          value: _stats['totalReadings']?.toString() ?? '0',
          icon: Icons.medical_information,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'This Month',
          value: _stats['recentReadings']?.toString() ?? '0',
          icon: Icons.calendar_today,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Unique Patients',
          value: _stats['uniquePatients']?.toString() ?? '0',
          icon: Icons.people,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Avg per Day',
          value: _calculateDailyAverage(),
          icon: Icons.trending_up,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Flexible(
      child: Card(
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
          vertical: MediaQuery.of(context).size.height * 0.01,
        ),
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        if (_hasWritePermission) ...[
          Expanded(
            child: _buildActionCard(
              title: 'New Reading',
              subtitle: 'Record patient vitals',
              icon: Icons.add_circle_outline,
              color: Colors.green,
              onTap: _showNewReadingForm,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _buildActionCard(
            title: 'Search Records',
            subtitle: 'Find patient data',
            icon: Icons.search,
            color: Colors.blue,
            onTap: () {
              _tabController.animateTo(1);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            title: 'Export Data',
            subtitle: 'Download reports',
            icon: Icons.file_download,
            color: Colors.orange,
            onTap: _showExportOptions,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latest Entries',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<PatientReading>>(
              future: SupabaseReadingsService.getAllReadings(limit: 3),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Text(
                    'Error loading recent readings',
                    style: TextStyle(color: Colors.grey.shade600),
                  );
                }
                
                final readings = snapshot.data ?? [];
                if (readings.isEmpty) {
                  return Text(
                    'No recent readings',
                    style: TextStyle(color: Colors.grey.shade600),
                  );
                }
                
                return Column(
                  children: readings.map((reading) => 
                    _buildRecentReadingItem(reading)
                  ).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReadingItem(PatientReading reading) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(
              reading.name.isNotEmpty ? reading.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reading.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatRecentDate(reading.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildNewReadingTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Use the form below or tap the floating action button to add a new patient reading.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ReadingsEntryForm(
              onSuccess: () {
                _loadStats();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reading saved successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPermissionView() {
    // This method will never be called now, but we'll keep it simple
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Readings'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we set up your access.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkPermissions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateDailyAverage() {
    final totalReadings = _stats['totalReadings'] as int? ?? 0;
    if (totalReadings == 0) return '0';
    
    // Assuming 30 days for monthly average
    final average = totalReadings / 30;
    return average.toStringAsFixed(1);
  }

  String _formatRecentDate(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.file_copy),
              title: const Text('Export All Readings'),
              subtitle: const Text('Download CSV file with all data'),
              onTap: () {
                Navigator.pop(context);
                _exportAllReadings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Export by Patient'),
              subtitle: const Text('Choose specific patient data'),
              onTap: () {
                Navigator.pop(context);
                _showPatientExportDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Export by Date Range'),
              subtitle: const Text('Select time period'),
              onTap: () {
                Navigator.pop(context);
                _showDateRangeExportDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportAllReadings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showPatientExportDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Patient-specific export coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showDateRangeExportDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Date range export coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}