import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/config/supabase_config.dart';
import 'src/auth/supabase_auth_provider.dart';
import 'src/auth_wrapper.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/register_screen.dart';
import 'src/screens/home_shell.dart';
import 'src/screens/readings_screen.dart';
import 'src/screens/alerts_screen.dart';
import 'src/screens/notifications_screen.dart';
import 'src/screens/medications_screen.dart';
import 'src/screens/risk_screen.dart';
import 'src/screens/education_screen.dart';
import 'src/screens/questionnaires_screen.dart';
import 'src/screens/support_groups_screen.dart';
import 'src/screens/quizzes_screen.dart';
import 'src/screens/quiz_attempt_screen.dart';
import 'src/screens/quizzes_history_screen.dart';
import 'src/pages/appointment_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  runApp(const NcdApp());
}

class NcdApp extends StatelessWidget {
  const NcdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SupabaseAuthProvider(),
      child: MaterialApp(
        title: 'NCD Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.teal),
        routes: {
          '/': (_) => const AuthWrapper(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const HomeShell(),
          '/readings': (_) => const ReadingsScreen(),
          '/alerts': (_) => const AlertsScreen(),
          '/notifications': (_) => const NotificationsScreen(),
          '/medications': (_) => const MedicationsScreen(),
          '/risk': (_) => const RiskScreen(),
          '/education': (_) => const EducationScreen(),
          '/questionnaires': (_) => const QuestionnairesScreen(),
          '/support-groups': (_) => const SupportGroupsScreen(),
          '/quizzes': (_) => const QuizzesScreen(),
          '/quiz': (_) => const QuizAttemptScreen(),
          '/quiz-history': (_) => const QuizzesHistoryScreen(),
          '/appointments': (_) => const AppointmentPage(),
        },
      ),
    );
  }
}


