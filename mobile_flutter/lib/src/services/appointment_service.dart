import 'package:flutter/material.dart';
import '../models/appointment.dart';

class AppointmentService {
  final List<Appointment> _appointments = [];

  List<Appointment> getAppointments() {
    return _appointments;
  }

  void addAppointment(Appointment appointment) {
    _appointments.add(appointment);
  }

  void editAppointment(String id, Appointment updatedAppointment) {
    final index = _appointments.indexWhere((appointment) => appointment.id == id);
    if (index != -1) {
      _appointments[index] = updatedAppointment;
    }
  }

  void deleteAppointment(String id) {
    _appointments.removeWhere((appointment) => appointment.id == id);
  }
}