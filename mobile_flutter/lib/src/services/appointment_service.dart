import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment.dart';

class AppointmentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Get all appointments for the current user
  Future<List<Appointment>> getAppointments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];
      
      final response = await _supabase
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: true);
      
      return (response as List)
          .map((appointment) => Appointment.fromMap(appointment))
          .toList();
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      return [];
    }
  }

  // Add a new appointment
  Future<bool> addAppointment(Appointment appointment) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      
      await _supabase.from('appointments').insert({
        'user_id': userId,
        'title': appointment.title,
        'date': appointment.date.toIso8601String(),
        'description': appointment.description,
        'doctor_name': appointment.doctorName,
        'location': appointment.location,
        'status': appointment.status ?? 'scheduled',
      });
      
      return true;
    } catch (e) {
      debugPrint('Error adding appointment: $e');
      return false;
    }
  }

  // Update an existing appointment
  Future<bool> editAppointment(String id, Appointment updatedAppointment) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      
      await _supabase.from('appointments').update({
        'title': updatedAppointment.title,
        'date': updatedAppointment.date.toIso8601String(),
        'description': updatedAppointment.description,
        'doctor_name': updatedAppointment.doctorName,
        'location': updatedAppointment.location,
        'status': updatedAppointment.status ?? 'scheduled',
      }).eq('id', id).eq('user_id', userId);
      
      return true;
    } catch (e) {
      debugPrint('Error updating appointment: $e');
      return false;
    }
  }

  // Delete an appointment
  Future<bool> deleteAppointment(String id) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      
      await _supabase
          .from('appointments')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
      
      return true;
    } catch (e) {
      debugPrint('Error deleting appointment: $e');
      return false;
    }
  }
}