class Appointment {
  final String id;
  final String title;
  final DateTime date;
  final String description;

  Appointment({
    required this.id,
    required this.title,
    required this.date,
    required this.description,
  });

  // Convert Appointment to Map for database or API
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  // Create Appointment from Map
  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      description: map['description'],
    );
  }
}