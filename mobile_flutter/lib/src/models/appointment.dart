class Appointment {
  final String? id;
  final String title;
  final DateTime date;
  final String description;
  final String? userId;
  final String? doctorName;
  final String? location;
  final String? status; // 'scheduled', 'completed', 'cancelled'

  Appointment({
    this.id,
    required this.title,
    required this.date,
    required this.description,
    this.userId,
    this.doctorName,
    this.location,
    this.status = 'scheduled',
  });

  // Convert Appointment to Map for database or API
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'description': description,
      if (userId != null) 'user_id': userId,
      if (doctorName != null) 'doctor_name': doctorName,
      if (location != null) 'location': location,
      if (status != null) 'status': status,
    };
  }

  // Create Appointment from Map
  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id']?.toString(),
      title: map['title'] ?? '',
      date: map['date'] != null 
          ? DateTime.parse(map['date']) 
          : DateTime.now(),
      description: map['description'] ?? '',
      userId: map['user_id']?.toString(),
      doctorName: map['doctor_name'],
      location: map['location'],
      status: map['status'] ?? 'scheduled',
    );
  }

  // Create a copy with some fields changed
  Appointment copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? description,
    String? userId,
    String? doctorName,
    String? location,
    String? status,
  }) {
    return Appointment(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      doctorName: doctorName ?? this.doctorName,
      location: location ?? this.location,
      status: status ?? this.status,
    );
  }
}