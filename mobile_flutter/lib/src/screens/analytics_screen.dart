import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../utils/responsive_helper.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Mock data for the charts
  final List<Map<String, dynamic>> _bloodPressureData = List.generate(
    30,
    (index) => {
      'date': DateTime.now().subtract(Duration(days: 30 - index)),
      'systolic': Random().nextInt(40) + 100, // Random value between 100-140
      'diastolic': Random().nextInt(20) + 60, // Random value between 60-80
    },
  );

  final List<Map<String, dynamic>> _bloodGlucoseData = List.generate(
    30,
    (index) => {
      'date': DateTime.now().subtract(Duration(days: 30 - index)),
      'value': Random().nextInt(50) + 70, // Random value between 70-120
    },
  );

  final List<Map<String, dynamic>> _weightData = List.generate(
    10,
    (index) => {
      'date': DateTime.now().subtract(Duration(days: 90 - (index * 10))),
      'value': Random().nextInt(10) + 65, // Random value between 65-75 kg
    },
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    
    // Adjust text sizes based on screen size
    final titleSize = ResponsiveHelper.responsiveValue(
      context: context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );
    
    final tabLabelSize = ResponsiveHelper.responsiveValue(
      context: context,
      mobile: 14.0,
      tablet: 16.0,
      desktop: 18.0,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Health Analytics',
          style: TextStyle(fontSize: titleSize),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Blood Pressure', height: isDesktop ? 48 : (isTablet ? 40 : null)),
            Tab(text: 'Blood Glucose', height: isDesktop ? 48 : (isTablet ? 40 : null)),
            Tab(text: 'Weight', height: isDesktop ? 48 : (isTablet ? 40 : null)),
          ],
          labelStyle: TextStyle(
            fontSize: tabLabelSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBloodPressureTab(),
          _buildBloodGlucoseTab(),
          _buildWeightTab(),
        ],
      ),
    );
  }

  Widget _buildBloodPressureTab() {
    // Adjust padding based on screen size
    final padding = ResponsiveHelper.responsiveValue(
      context: context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
    
    final chartHeight = ResponsiveHelper.responsiveValue(
      context: context,
      mobile: 250.0,
      tablet: 350.0,
      desktop: 450.0,
    );
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blood Pressure Trends (Last 30 days)',
            style: TextStyle(
              fontSize: ResponsiveHelper.responsiveValue(
                context: context,
                mobile: 18.0,
                tablet: 22.0,
                desktop: 26.0,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveHelper.responsiveValue(
            context: context,
            mobile: 16.0,
            tablet: 20.0,
            desktop: 24.0,
          )),
          _buildBloodPressureSummary(),
          SizedBox(height: ResponsiveHelper.responsiveValue(
            context: context,
            mobile: 24.0,
            tablet: 32.0,
            desktop: 40.0,
          )),
          SizedBox(
            height: chartHeight,
            child: _buildBloodPressureChart(),
          ),
          SizedBox(height: ResponsiveHelper.responsiveValue(
            context: context,
            mobile: 24.0,
            tablet: 32.0,
            desktop: 40.0,
          )),
          _buildBloodPressureRecords(),
        ],
      ),
    );
  }

  Widget _buildBloodPressureSummary() {
    // Calculate averages
    double avgSystolic = _bloodPressureData.map((e) => e['systolic'] as int).reduce((a, b) => a + b) / _bloodPressureData.length;
    double avgDiastolic = _bloodPressureData.map((e) => e['diastolic'] as int).reduce((a, b) => a + b) / _bloodPressureData.length;
    
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveHelper.responsiveValue(
            context: context,
            mobile: 16.0,
            tablet: 20.0,
            desktop: 24.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average Readings', 
              style: TextStyle(
                fontSize: ResponsiveHelper.responsiveValue(
                  context: context,
                  mobile: 16.0,
                  tablet: 18.0,
                  desktop: 20.0,
                ),
                fontWeight: FontWeight.w500
              ),
            ),
            SizedBox(height: ResponsiveHelper.responsiveValue(
              context: context,
              mobile: 16.0,
              tablet: 20.0,
              desktop: 24.0,
            )),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Systolic', '${avgSystolic.toStringAsFixed(0)} mmHg', 
                  avgSystolic > 120 ? Colors.orange : Colors.green),
                _buildSummaryItem('Diastolic', '${avgDiastolic.toStringAsFixed(0)} mmHg',
                  avgDiastolic > 80 ? Colors.orange : Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title, 
          style: TextStyle(
            fontSize: ResponsiveHelper.responsiveValue(
              context: context,
              mobile: 14.0,
              tablet: 16.0,
              desktop: 18.0,
            ), 
            color: Colors.grey
          )
        ),
        SizedBox(height: ResponsiveHelper.responsiveValue(
          context: context,
          mobile: 8.0,
          tablet: 10.0,
          desktop: 12.0,
        )),
        Text(
          value, 
          style: TextStyle(
            fontSize: ResponsiveHelper.responsiveValue(
              context: context,
              mobile: 18.0,
              tablet: 22.0,
              desktop: 26.0,
            ), 
            fontWeight: FontWeight.bold, 
            color: color
          )
        ),
      ],
    );
  }

  Widget _buildBloodPressureChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 5 != 0) return const Text('');
                final date = _bloodPressureData[value.toInt().clamp(0, _bloodPressureData.length-1)]['date'] as DateTime;
                return Text(DateFormat('MMM d').format(date), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          // Systolic line
          LineChartBarData(
            spots: List.generate(_bloodPressureData.length, (index) {
              return FlSpot(index.toDouble(), _bloodPressureData[index]['systolic'].toDouble());
            }),
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Diastolic line
          LineChartBarData(
            spots: List.generate(_bloodPressureData.length, (index) {
              return FlSpot(index.toDouble(), _bloodPressureData[index]['diastolic'].toDouble());
            }),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        minY: 50,
        maxY: 150,
      ),
    );
  }

  Widget _buildBloodPressureRecords() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Readings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5, // Show only the last 5 readings
          itemBuilder: (context, index) {
            final reading = _bloodPressureData[_bloodPressureData.length - 1 - index];
            final date = reading['date'] as DateTime;
            final systolic = reading['systolic'] as int;
            final diastolic = reading['diastolic'] as int;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('${systolic}/${diastolic} mmHg'),
                subtitle: Text(DateFormat('MMMM d, yyyy, h:mm a').format(date)),
                trailing: Icon(
                  _getBPStatusIcon(systolic, diastolic),
                  color: _getBPStatusColor(systolic, diastolic),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  IconData _getBPStatusIcon(int systolic, int diastolic) {
    if (systolic >= 140 || diastolic >= 90) {
      return Icons.warning_rounded;
    } else if (systolic >= 120 || diastolic >= 80) {
      return Icons.info_outline;
    } else {
      return Icons.check_circle_outline;
    }
  }

  Color _getBPStatusColor(int systolic, int diastolic) {
    if (systolic >= 140 || diastolic >= 90) {
      return Colors.red;
    } else if (systolic >= 120 || diastolic >= 80) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Widget _buildBloodGlucoseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Blood Glucose Trends (Last 30 days)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Average Blood Glucose', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    '${(_bloodGlucoseData.map((e) => e['value'] as int).reduce((a, b) => a + b) / _bloodGlucoseData.length).toStringAsFixed(0)} mg/dL',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: _buildBloodGlucoseChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodGlucoseChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 5 != 0) return const Text('');
                final date = _bloodGlucoseData[value.toInt().clamp(0, _bloodGlucoseData.length-1)]['date'] as DateTime;
                return Text(DateFormat('MMM d').format(date), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(_bloodGlucoseData.length, (index) {
              return FlSpot(index.toDouble(), _bloodGlucoseData[index]['value'].toDouble());
            }),
            isCurved: true,
            color: Colors.purple,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        minY: 60,
        maxY: 140,
      ),
    );
  }

  Widget _buildWeightTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weight History (Last 3 months)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeightSummary('Current', '${_weightData.last['value']} kg'),
                  _buildWeightSummary('3 Month Change', '${(_weightData.last['value'] - _weightData.first['value']).toStringAsFixed(1)} kg'),
                  _buildWeightSummary('BMI', '${((_weightData.last['value'] / (1.7 * 1.7)).toStringAsFixed(1))}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: _buildWeightChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSummary(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildWeightChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        minY: 50,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value >= _weightData.length) return const Text('');
                final date = _weightData[value.toInt()]['date'] as DateTime;
                return Text(DateFormat('MMM d').format(date), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 10,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(_weightData.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: _weightData[index]['value'].toDouble(),
                color: Colors.teal,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }
}
