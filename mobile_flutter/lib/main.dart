import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/auth/auth_provider.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/register_screen.dart';
import 'src/screens/home_shell.dart';
import 'src/screens/readings_screen.dart';
import 'src/screens/alerts_screen.dart';
import 'src/screens/notifications_screen.dart';
import 'src/screens/medications_screen.dart';
import 'src/screens/appointments_screen.dart';
import 'src/screens/analytics_screen.dart';
import 'src/screens/education_screen.dart';
import 'src/screens/questionnaires_screen.dart';
import 'src/screens/support_groups_screen.dart';

void main() {
  runApp(const NcdApp());
}

class NcdApp extends StatelessWidget {
  const NcdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..loadTokens(),
      child: MaterialApp(
        title: 'NCD Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.teal),
        routes: {
          '/': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const HomeShell(),
          '/readings': (_) => const ReadingsScreen(),
          '/alerts': (_) => const AlertsScreen(),
          '/notifications': (_) => const NotificationsScreen(),
          '/medications': (_) => const MedicationsScreen(),
          '/appointments': (_) => const AppointmentsScreen(),
          '/analytics': (_) => const AnalyticsScreen(),
          '/education': (_) => const EducationScreen(),
          '/questionnaires': (_) => const QuestionnairesScreen(),
          '/support-groups': (_) => const SupportGroupsScreen(),
        },
      ),
    );
  }
}


