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
import 'src/screens/analytics_screen.dart';
import 'src/screens/education_screen.dart';
import 'src/screens/questionnaires_screen.dart';
import 'src/screens/support_groups_screen.dart';
import 'src/screens/quizzes_screen.dart';
import 'src/screens/quiz_attempt_screen.dart';
import 'src/screens/quizzes_history_screen.dart';
import 'src/pages/appointment_page.dart';
import 'src/messaging/screens/screens.dart';
import 'src/messaging/services/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  // Initialize storage buckets for attachments
  await _initializeStorage();
  
  runApp(const NcdApp());
}

Future<void> _initializeStorage() async {
  try {
    // Import helper to initialize storage buckets for attachments
    // Will be called after user authentication as well
    await Future.delayed(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('Error initializing storage: $e');
  }
}

class NcdApp extends StatelessWidget {
  const NcdApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create instances to be shared
    final mediaService = MediaService();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SupabaseAuthProvider()),
        Provider<MediaService>.value(value: mediaService),
        ChangeNotifierProvider(create: (_) => OfflineMessageProvider()),
        ChangeNotifierProxyProvider<OfflineMessageProvider, ChatProvider>(
          // Create the ChatProvider with a ChatService
          create: (_) => ChatProvider(
            chatService: ChatService(),
          ),
          // Update the ChatProvider whenever OfflineMessageProvider changes
          update: (_, offlineProvider, chatProvider) {
            // Initialize if not already initialized
            if (chatProvider != null && !chatProvider.isInitialized) {
              chatProvider.initialize(
                offlineService: offlineProvider.offlineMessageService
              );
            }
            return chatProvider ?? ChatProvider(chatService: ChatService());
          },
        ),
        ChangeNotifierProvider(
          create: (_) => MediaUploadProvider(
            mediaService: mediaService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'NCD Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          // Make app fonts responsive
          textTheme: Typography.material2018().black.apply(
            fontSizeFactor: 1.0, // Base font size (will be adjusted by responsive helper)
          ),
          // Use adaptive components where possible
          appBarTheme: AppBarTheme(
            elevation: 2.0,
            centerTitle: true,
          ),
          cardTheme: const CardThemeData(
            elevation: 2.0,
            margin: EdgeInsets.symmetric(vertical: 8.0),
          ),
        ),
        builder: (context, child) {
          // Apply a responsive font scale based on device size
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: MediaQuery.of(context).size.width > 768 ? 1.1 : 1.0,
            ),
            child: child!,
          );
        },
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
          '/messages': (_) => const ChatSelectionScreen(),
          '/custom-messaging': (_) => const CustomMessagingScreen(chatId: 'default'),
          '/analytics': (_) => const AnalyticsScreen(),
        },
      ),
    );
  }
}


