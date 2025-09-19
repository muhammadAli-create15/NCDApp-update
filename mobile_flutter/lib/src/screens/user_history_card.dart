import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../utils/responsive_helper.dart';

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
    // Use ResponsiveHelper to adjust based on screen size
    final horizontalMargin = ResponsiveHelper.responsiveValue(
      context: context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
    
    final verticalMargin = ResponsiveHelper.responsiveValue(
      context: context,
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    );
    
    final padding = ResponsiveHelper.responsiveValue(
      context: context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: verticalMargin),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(padding),
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
                              Icon(Icons.history, 
                                color: Colors.teal,
                                size: ResponsiveHelper.responsiveValue(
                                  context: context,
                                  mobile: 18.0,
                                  tablet: 20.0,
                                  desktop: 24.0,
                                ),
                              ),
                              SizedBox(width: ResponsiveHelper.responsiveValue(
                                context: context,
                                mobile: 8.0,
                                tablet: 10.0,
                                desktop: 12.0,
                              )),
                              Text('Your Recent Activity', 
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.responsiveValue(
                                    context: context,
                                    mobile: 16.0,
                                    tablet: 18.0,
                                    desktop: 20.0,
                                  ),
                                  fontWeight: FontWeight.bold
                                )
                              ),
                            ],
                          ),
                          SizedBox(height: ResponsiveHelper.responsiveValue(
                            context: context,
                            mobile: 12.0,
                            tablet: 16.0,
                            desktop: 20.0,
                          )),
                          if (_history!['last_reading'] != null)
                            _buildHistoryItem(Icons.monitor_heart, 'Last Reading', 
                              _formatDateTime(_history!['last_reading'])),
                          if (_history!['last_appointment'] != null)
                            _buildHistoryItem(Icons.event, 'Last Appointment', 
                              _formatDateTime(_history!['last_appointment'])),
                          if (_history!['last_alert'] != null)
                            _buildHistoryItem(Icons.warning, 'Last Alert', 
                              _formatDateTime(_history!['last_alert'])),
                          SizedBox(height: ResponsiveHelper.responsiveValue(
                            context: context,
                            mobile: 8.0,
                            tablet: 12.0,
                            desktop: 16.0,
                          )),
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
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.responsiveValue(
          context: context,
          mobile: 4.0,
          tablet: 6.0,
          desktop: 8.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon, 
            size: ResponsiveHelper.responsiveValue(
              context: context,
              mobile: 16.0,
              tablet: 18.0,
              desktop: 20.0,
            ),
            color: Colors.grey[600]
          ),
          SizedBox(width: ResponsiveHelper.responsiveValue(
            context: context,
            mobile: 8.0,
            tablet: 10.0,
            desktop: 12.0,
          )),
          Text(
            '$title: ', 
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.responsiveValue(
                context: context,
                mobile: 14.0,
                tablet: 15.0,
                desktop: 16.0,
              ),
            ),
          ),
          Text(
            value, 
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: ResponsiveHelper.responsiveValue(
                context: context,
                mobile: 14.0,
                tablet: 15.0,
                desktop: 16.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(), 
          style: TextStyle(
            fontSize: ResponsiveHelper.responsiveValue(
              context: context,
              mobile: 18.0,
              tablet: 20.0,
              desktop: 24.0,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.teal
          )
        ),
        Text(
          label, 
          style: TextStyle(
            fontSize: ResponsiveHelper.responsiveValue(
              context: context,
              mobile: 12.0,
              tablet: 13.0,
              desktop: 14.0,
            ),
            color: Colors.grey[600]
          ),
        ),
      ],
    );
  }
}
