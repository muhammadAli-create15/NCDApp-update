import 'package:flutter/material.dart';
import 'features_screen.dart';
import '../utils/responsive_helper.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/responsive_scaffold.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _features = [
    {'title': 'Dashboard', 'icon': Icons.dashboard, 'route': '/'},
    {'title': 'Readings', 'icon': Icons.bar_chart, 'route': '/readings'},
    {'title': 'Risk', 'icon': Icons.health_and_safety, 'route': '/risk'},
    {'title': 'Alerts', 'icon': Icons.notifications_active, 'route': '/alerts'},
    {'title': 'Notifications', 'icon': Icons.notifications, 'route': '/notifications'},
    {'title': 'Messages', 'icon': Icons.chat, 'route': '/messages'},
    {'title': 'Medications', 'icon': Icons.medication, 'route': '/medications'},
    {'title': 'Appointments', 'icon': Icons.event, 'route': '/appointments'},
    {'title': 'Analytics', 'icon': Icons.analytics, 'route': '/analytics'},
    {'title': 'Education', 'icon': Icons.school, 'route': '/education'},
    {'title': 'Questionnaires', 'icon': Icons.assignment, 'route': '/questionnaires'},
    {'title': 'Support Groups', 'icon': Icons.group, 'route': '/support-groups'},
    {'title': 'Quizzes', 'icon': Icons.quiz, 'route': '/quizzes'},
  ];

  void _onFeatureTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pushNamed(context, _features[index]['route']);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    
    // Build the drawer content
    Widget drawerContent = ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'NCD App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Health Management',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        ..._features.asMap().entries.map((entry) {
          int idx = entry.key;
              var feature = entry.value;
              return ListTile(
                leading: Icon(feature['icon']),
                title: Text(feature['title']),
                selected: idx == _selectedIndex,
                onTap: () => _onFeatureTap(idx),
              );
            }).toList(),
          ],
        );
    
    // Build feature grid based on screen size
    Widget featureGrid = ResponsiveHelper.responsiveLayout(
      context: context,
      // Mobile view
      mobile: (context) => const FeaturesScreen(),
      // Tablet view
      tablet: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
          ),
          itemCount: _features.length,
          itemBuilder: (context, index) {
            final feature = _features[index];
            return _buildFeatureCard(feature, index);
          },
        ),
      ),
      // Desktop view
      desktop: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.5,
            crossAxisSpacing: 24.0,
            mainAxisSpacing: 24.0,
          ),
          itemCount: _features.length,
          itemBuilder: (context, index) {
            final feature = _features[index];
            return _buildFeatureCard(feature, index);
          },
        ),
      ),
    );
    
    // Use our custom responsive scaffold
    if (isDesktop || isTablet) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('NCD App'),
          centerTitle: true,
          elevation: isDesktop ? 4.0 : 2.0,
        ),
        body: isDesktop
            ? Row(
                children: [
                  SizedBox(
                    width: 250,
                    child: Drawer(
                      child: drawerContent,
                    ),
                  ),
                  Expanded(child: featureGrid),
                ],
              )
            : featureGrid,
        drawer: isDesktop ? null : Drawer(child: drawerContent),
      );
    }
    
    // Mobile layout
    return Scaffold(
      appBar: AppBar(title: const Text('NCD App')),
      drawer: Drawer(child: drawerContent),
      body: featureGrid,
    );
  }
  
  Widget _buildFeatureCard(Map<String, dynamic> feature, int index) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () => _onFeatureTap(index),
        borderRadius: BorderRadius.circular(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(feature['icon'], size: 36, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            Text(
              feature['title'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}


