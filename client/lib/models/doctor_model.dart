class Patient {
  final int userId;
  final String email;
  final String profilePicture;

  Patient({
    required this.userId,
    required this.email,
    required this.profilePicture,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      userId: json['user_id'] ?? 0,
      email: json['email'] ?? 'Unknown',
      profilePicture:
          json['profile_picture'] ??
          'https://picsum.photos/seed/defaultpatient/200',
    );
  }
}

class AppointmentEntry {
  final int appointmentId;
  final String status;
  final String date;
  final String remarks;
  final Patient patient;

  AppointmentEntry({
    required this.appointmentId,
    required this.status,
    required this.date,
    required this.remarks,
    required this.patient,
  });

  factory AppointmentEntry.fromJson(Map<String, dynamic> json) {
    return AppointmentEntry(
      appointmentId: json['appointment_id'] ?? 0,
      status: json['status'] ?? 'Unknown',
      date: json['date'] ?? '',
      remarks: json['remarks'] ?? '',
      patient: Patient.fromJson(json['patient'] ?? {}),
    );
  }
}

class DoctorAvailability {
  final String date;
  final String startTime;
  final String endTime;
  final String status;

  DoctorAvailability({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory DoctorAvailability.fromJson(Map<String, dynamic> json) {
    return DoctorAvailability(
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      status: json['status'] ?? 'unknown',
    );
  }
}

class Doctor {
  final int doctorId;
  final int userId;
  final String name;
  final String specialty;
  final String status;
  final String imageUrl;
  final List<DoctorAvailability> availability;
  final List<AppointmentEntry> appointments;

  Doctor({
    required this.doctorId,
    required this.userId,
    required this.name,
    required this.specialty,
    required this.status,
    required this.imageUrl,
    required this.availability,
    required this.appointments,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      doctorId: json['doctor_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? 'Unknown Doctor',
      specialty: json['specialty'] ?? 'General',
      status: json['status'] ?? 'Inactive',
      imageUrl:
          json['imageUrl'] ?? 'https://picsum.photos/seed/defaultdoctor/200',
      availability: (json['availability'] as List<dynamic>? ?? [])
          .map((a) => DoctorAvailability.fromJson(a))
          .toList(),
      appointments: (json['appointments'] as List<dynamic>? ?? [])
          .map((a) => AppointmentEntry.fromJson(a))
          .toList(),
    );
  }
}
