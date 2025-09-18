import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class UserHistoryCard extends StatefulWidget {
  const UserHistoryCard({super.key});

  @override
  State<UserHistoryCard> createState() => _UserHistoryCardState();
}

class _UserHistoryCardState extends State<UserHistoryCard> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _history;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await SupabaseService.getUserHistory();
      setState(() {
        _history = history;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load history';
        _loading = false;
      });
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'Never';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                )
              )
            : _error != null
                ? Column(
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      TextButton(
                        onPressed: _loadHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : _history == null
                    ? const Text('No history found.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history, color: Colors.teal),
                              const SizedBox(width: 8),
                              const Text('Your Recent Activity', 
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_history!['last_reading'] != null)
                            _buildHistoryItem(Icons.monitor_heart, 'Last Reading', 
                              _formatDateTime(_history!['last_reading'])),
                          if (_history!['last_appointment'] != null)
                            _buildHistoryItem(Icons.event, 'Last Appointment', 
                              _formatDateTime(_history!['last_appointment'])),
                          if (_history!['last_alert'] != null)
                            _buildHistoryItem(Icons.warning, 'Last Alert', 
                              _formatDateTime(_history!['last_alert'])),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Readings', _history!['total_readings'] ?? 0),
                              _buildStatItem('Appointments', _history!['total_appointments'] ?? 0),
                              _buildStatItem('Alerts', _history!['total_alerts'] ?? 0),
                            ],
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildHistoryItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(count.toString(), 
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
