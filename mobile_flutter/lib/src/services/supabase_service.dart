import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get current user
  static User? get currentUser => _client.auth.currentUser;

  // Readings
  static Future<List<Map<String, dynamic>>> getReadings() async {
    if (currentUser == null) return [];
    
    try {
      final response = await _client
          .from(SupabaseConfig.readingsTable)
          .select()
          .eq('user_id', currentUser!.id)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addReading(Map<String, dynamic> reading) async {
    if (currentUser == null) return false;
    
    try {
      reading['user_id'] = currentUser!.id;
      reading['created_at'] = DateTime.now().toIso8601String();
      
      await _client.from(SupabaseConfig.readingsTable).insert(reading);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Appointments
  static Future<List<Map<String, dynamic>>> getAppointments() async {
    if (currentUser == null) return [];
    
    try {
      final response = await _client
          .from(SupabaseConfig.appointmentsTable)
          .select()
          .eq('user_id', currentUser!.id)
          .order('scheduled_for', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Medications
  static Future<List<Map<String, dynamic>>> getMedications() async {
    if (currentUser == null) return [];
    
    try {
      final response = await _client
          .from(SupabaseConfig.medicationsTable)
          .select()
          .eq('user_id', currentUser!.id)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Alerts
  static Future<List<Map<String, dynamic>>> getAlerts() async {
    if (currentUser == null) return [];
    
    try {
      final response = await _client
          .from(SupabaseConfig.alertsTable)
          .select()
          .eq('user_id', currentUser!.id)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Quizzes
  static Future<List<Map<String, dynamic>>> getQuizzes() async {
    try {
      final response = await _client
          .from(SupabaseConfig.quizzesTable)
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // User History Summary
  static Future<Map<String, dynamic>?> getUserHistory() async {
    if (currentUser == null) return null;
    
    try {
      // Get latest from each category
      final readings = await getReadings();
      final appointments = await getAppointments();
      final alerts = await getAlerts();
      
      return {
        'last_reading': readings.isNotEmpty 
            ? readings.first['created_at']?.toString() 
            : null,
        'last_appointment': appointments.isNotEmpty 
            ? appointments.first['scheduled_for']?.toString() 
            : null,
        'last_alert': alerts.isNotEmpty 
            ? alerts.first['created_at']?.toString() 
            : null,
        'total_readings': readings.length,
        'total_appointments': appointments.length,
        'total_alerts': alerts.length,
      };
    } catch (e) {
      return null;
    }
  }

  // Education Content
  static Future<List<Map<String, dynamic>>> getEducationContent() async {
    try {
      final response = await _client
          .from(SupabaseConfig.educationTable)
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Support Groups
  static Future<List<Map<String, dynamic>>> getSupportGroups() async {
    try {
      final response = await _client
          .from(SupabaseConfig.supportGroupsTable)
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}