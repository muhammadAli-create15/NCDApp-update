import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Get Supabase credentials from environment variables
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // Database table names
  static const String usersTable = 'users';
  static const String patientsTable = 'patients';
  static const String readingsTable = 'readings';
  static const String appointmentsTable = 'appointments';
  static const String medicationsTable = 'medications';
  static const String quizzesTable = 'quizzes';
  static const String questionnairesTable = 'questionnaires';
  static const String alertsTable = 'alerts';
  static const String educationTable = 'education_content';
  static const String supportGroupsTable = 'support_groups';
  static const String analyticsTable = 'analytics';
}