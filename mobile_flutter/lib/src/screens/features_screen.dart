import 'package:flutter/material.dart';
import 'user_history_card.dart';
import '../utils/responsive_helper.dart';
import '../widgets/responsive_grid.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  final List<Map<String, dynamic>> _features = const [
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    
    // Determine grid properties based on screen size
    int crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
    double iconSize = isDesktop ? 48.0 : (isTablet ? 44.0 : 40.0);
    double titleSize = isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0);
    EdgeInsetsGeometry padding = EdgeInsets.all(
      ResponsiveHelper.responsiveValue(
        context: context,
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
      ),
    );
    
    return Container(
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(ResponsiveHelper.responsiveValue(
              context: context,
              mobile: 16.0,
              tablet: 24.0,
              desktop: 32.0,
            )),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.responsiveValue(
                      context: context,
                      mobile: 24.0,
                      tablet: 28.0,
                      desktop: 32.0,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.responsiveValue(
                  context: context,
                  mobile: 8.0,
                  tablet: 12.0,
                  desktop: 16.0,
                )),
                Text(
                  'Choose a feature:',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.responsiveValue(
                      context: context,
                      mobile: 16.0,
                      tablet: 18.0,
                      desktop: 20.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // User history card
          const UserHistoryCard(),
          Expanded(
            child: GridView.count(
              crossAxisCount: crossAxisCount,
              padding: padding,
              crossAxisSpacing: ResponsiveHelper.responsiveValue(
                context: context,
                mobile: 16.0,
                tablet: 20.0,
                desktop: 24.0,
              ),
              mainAxisSpacing: ResponsiveHelper.responsiveValue(
                context: context,
                mobile: 16.0,
                tablet: 20.0,
                desktop: 24.0,
              ),
              children: _features.map((feature) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pushNamed(context, feature['route']),
                    child: Padding(
                      padding: EdgeInsets.all(
                        ResponsiveHelper.responsiveValue(
                          context: context,
                          mobile: 12.0,
                          tablet: 16.0,
                          desktop: 20.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(feature['icon'], size: iconSize, color: Theme.of(context).primaryColor),
                          SizedBox(
                            height: ResponsiveHelper.responsiveValue(
                              context: context,
                              mobile: 8.0,
                              tablet: 12.0,
                              desktop: 16.0,
                            )
                          ),
                          Text(
                            feature['title'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}


