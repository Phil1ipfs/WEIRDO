// import 'package:flutter/material.dart';

// // ⬇️ Directly define models here
// class AppointmentEntry {
//   final String withWhom;
//   final String status;
//   final DateTime dateTime;

//   AppointmentEntry({
//     required this.withWhom,
//     required this.status,
//     required this.dateTime,
//   });
// }

// class Doctor {
//   final String name;
//   final String specialty;
//   final String status;
//   final String imageUrl;
//   final List<AppointmentEntry> appointments;

//   Doctor({
//     required this.name,
//     required this.specialty,
//     required this.status,
//     required this.imageUrl,
//     required this.appointments,
//   });
// }

// class DoctorProfilePage extends StatelessWidget {
//   final dynamic doctor; // or Object, if you want stronger typing

//   const DoctorProfilePage({super.key, required this.doctor});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFB36CC6),
//         title: Text(
//           doctor.name,
//           style: TextStyle(
//             fontFamily: 'Sahitya',
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // Doctor Info
//             Card(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               elevation: 4,
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 40,
//                       backgroundImage: NetworkImage(doctor.imageUrl),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             doctor.name,
//                             style: const TextStyle(
//                               fontFamily: 'Poppins',
//                               fontSize: 18,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           Text(
//                             doctor.specialty,
//                             style: const TextStyle(
//                               fontFamily: 'Poppins',
//                               fontSize: 14,
//                               color: Colors.grey,
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 4,
//                             ),
//                             decoration: BoxDecoration(
//                               color: doctor.status == 'Active'
//                                   ? Colors.green.shade100
//                                   : Colors.red.shade100,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               doctor.status,
//                               style: TextStyle(
//                                 fontFamily: 'Poppins',
//                                 fontSize: 12,
//                                 color: doctor.status == 'Active'
//                                     ? Colors.green.shade800
//                                     : Colors.red.shade800,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Appointments Header
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 'Appointments',
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey.shade800,
//                 ),
//               ),
//             ),

//             const SizedBox(height: 12),

//             // Appointments List
//             doctor.appointments.isEmpty
//                 ? const Text(
//                     'No appointments yet.',
//                     style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
//                   )
//                 : ListView.builder(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: doctor.appointments.length,
//                     itemBuilder: (context, index) {
//                       final appt = doctor.appointments[index];
//                       return Card(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         margin: const EdgeInsets.only(bottom: 12),
//                         child: ListTile(
//                           leading: Icon(
//                             Icons.person,
//                             color: Colors.grey.shade700,
//                           ),
//                           title: Text(
//                             appt.withWhom,
//                             style: const TextStyle(
//                               fontFamily: 'Poppins',
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           subtitle: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 '${appt.dateTime.year}-${appt.dateTime.month.toString().padLeft(2, '0')}-${appt.dateTime.day.toString().padLeft(2, '0')} '
//                                 '${appt.dateTime.hour.toString().padLeft(2, '0')}:${appt.dateTime.minute.toString().padLeft(2, '0')}',
//                                 style: const TextStyle(fontFamily: 'Poppins'),
//                               ),
//                               const SizedBox(height: 4),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 4,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: _statusColor(appt.status).shade100,
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: Text(
//                                   appt.status,
//                                   style: TextStyle(
//                                     fontFamily: 'Poppins',
//                                     fontSize: 12,
//                                     color: _statusColor(appt.status).shade800,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Utility to color appointment status
//   MaterialColor _statusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmed':
//         return Colors.green;
//       case 'pending':
//         return Colors.orange;
//       case 'completed':
//         return Colors.blue;
//       case 'cancelled':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:myriad/models/doctor_model.dart';

// UI WIDGET
class DoctorProfilePage extends StatelessWidget {
  final Doctor doctor;

  const DoctorProfilePage({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB36CC6),
        foregroundColor: Colors.white,
        title: Text(
          doctor.name,
          style: const TextStyle(
            fontFamily: 'Sahitya',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Doctor Info Card
            _buildDoctorInfoCard(),
            const SizedBox(height: 20),

            // Appointments Header
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Appointments',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Appointment List
            doctor.appointments.isEmpty
                ? const Text(
                    'No appointments yet.',
                    style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: doctor.appointments.length,
                    itemBuilder: (context, index) {
                      final appt = doctor.appointments[index];
                      return _buildAppointmentCard(appt);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // ---------- UI HELPERS ----------

  Widget _buildDoctorInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(doctor.imageUrl),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    doctor.specialty,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: doctor.status.toLowerCase() == 'active'
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      doctor.status,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: doctor.status.toLowerCase() == 'active'
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentEntry appt) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(appt.patient.profilePicture),
        ),
        title: Text(
          appt.patient.email,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appt.date, style: const TextStyle(fontFamily: 'Poppins')),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(appt.status).shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                appt.status,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: _statusColor(appt.status).shade800,
                ),
              ),
            ),
            if (appt.remarks.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                "Remarks: ${appt.remarks}",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Status Color Utility
  MaterialColor _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
