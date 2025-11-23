// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'sub-pages/doctor_view_screen.dart';
// import 'sub-pages/create_doctor_page.dart';
// import 'sub-pages/notification_page.dart';

// /// Doctor model
// class Doctor {
//   final String name;
//   final String specialty;
//   final String status;
//   final String imageUrl;
//   final List<AppointmentEntry> appointments;

//   const Doctor({
//     required this.name,
//     required this.specialty,
//     required this.status,
//     required this.imageUrl,
//     required this.appointments,
//   });

//   factory Doctor.fromJson(Map<String, dynamic> json) {
//     return Doctor(
//       name: json['name'] ?? 'Unknown Doctor',
//       specialty: json['specialty'] ?? 'General',
//       status: json['status'] ?? 'Unknown',
//       imageUrl:
//           json['imageUrl'] ?? 'https://picsum.photos/seed/defaultdoctor/200',
//       appointments:
//           (json['appointments'] as List<dynamic>?)
//               ?.map((a) => AppointmentEntry.fromJson(a))
//               .toList() ??
//           [],
//     );
//   }
// }

// /// Appointment model
// class AppointmentEntry {
//   final String withWhom;
//   final String status;
//   final DateTime dateTime;

//   const AppointmentEntry({
//     required this.withWhom,
//     required this.status,
//     required this.dateTime,
//   });

//   factory AppointmentEntry.fromJson(Map<String, dynamic> json) {
//     return AppointmentEntry(
//       withWhom: json['withWhom'] ?? 'Unknown',
//       status: json['status'] ?? 'Pending',
//       dateTime: DateTime.tryParse(json['dateTime'] ?? '') ?? DateTime.now(),
//     );
//   }
// }

// class DoctorScreen extends StatefulWidget {
//   const DoctorScreen({super.key});

//   @override
//   State<DoctorScreen> createState() => _DoctorScreenState();
// }

// class _DoctorScreenState extends State<DoctorScreen> {
//   List<Doctor> _doctors = [];
//   bool _isLoading = true;
//   String _searchQuery = '';
//   String _filterStatus = 'All';

//   // Replace with your API URL
//   final String apiUrl = 'https://janna-server.onrender.com/api/doctors/all';

//   @override
//   void initState() {
//     super.initState();
//     fetchDoctors();
//   }

//   Future<void> fetchDoctors() async {
//     try {
//       final response = await http.get(Uri.parse(apiUrl));
//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         setState(() {
//           _doctors = data.map((d) => Doctor.fromJson(d)).toList();
//           _isLoading = false;
//         });
//       } else {
//         throw Exception('Failed to load doctors');
//       }
//     } catch (e) {
//       debugPrint('Error fetching doctors: $e');
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to load doctors. Please try again.'),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filteredDoctors = _doctors.where((doc) {
//       final matchName = doc.name.toLowerCase().contains(
//         _searchQuery.toLowerCase(),
//       );
//       final matchStatus =
//           _filterStatus == 'All' ||
//           doc.status.toLowerCase() == _filterStatus.toLowerCase();
//       return matchName && matchStatus;
//     }).toList();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Doctors',
//           style: TextStyle(
//             fontFamily: 'Sahitya', // ✅ Custom font
//             fontWeight: FontWeight.w700, // ✅ Bold weight
//             fontSize: 22, // optional, looks better for title
//           ),
//         ),
//         elevation: 0,
//         backgroundColor: const Color(
//           0xFFB36CC6,
//         ), // ✅ same as your footer tabs color
//         foregroundColor: Colors.white, // for title and icons
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications_none),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const NotificationPage(),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),

//       backgroundColor: Colors.grey.shade100,

//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             child: Row(
//               children: [
//                 // Search bar
//                 Expanded(
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black12,
//                           blurRadius: 6,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: TextField(
//                       onChanged: (value) =>
//                           setState(() => _searchQuery = value),
//                       decoration: InputDecoration(
//                         hintText: 'Search doctors...',
//                         prefixIcon: Icon(
//                           Icons.search,
//                           color: Colors.grey.shade600,
//                         ),
//                         border: InputBorder.none,
//                         contentPadding: const EdgeInsets.symmetric(
//                           vertical: 14,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),

//                 // Filter Dropdown
//                 Container(
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFB36CC6),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   child: DropdownButtonHideUnderline(
//                     child: DropdownButton<String>(
//                       value: _filterStatus,
//                       dropdownColor: const Color(0xFFB36CC6),
//                       items: const [
//                         DropdownMenuItem(
//                           value: 'All',
//                           child: Text(
//                             'All',
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ),
//                         DropdownMenuItem(
//                           value: 'Active',
//                           child: Text(
//                             'Active',
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ),
//                         DropdownMenuItem(
//                           value: 'Inactive',
//                           child: Text(
//                             'Inactive',
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ),
//                       ],
//                       onChanged: (value) =>
//                           setState(() => _filterStatus = value!),
//                       icon: const Icon(Icons.filter_list, color: Colors.white),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 12),

//           // 🔹 Doctor List / Loading / Empty
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : filteredDoctors.isEmpty
//                 ? const Center(
//                     child: Text(
//                       'No doctors found',
//                       style: TextStyle(
//                         fontFamily: 'Poppins',
//                         fontSize: 16,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   )
//                 : ListView.builder(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     itemCount: filteredDoctors.length,
//                     itemBuilder: (context, index) {
//                       final doc = filteredDoctors[index];
//                       return Card(
//                         margin: const EdgeInsets.only(bottom: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         elevation: 3,
//                         child: ListTile(
//                           contentPadding: const EdgeInsets.symmetric(
//                             vertical: 12,
//                             horizontal: 16,
//                           ),
//                           leading: CircleAvatar(
//                             radius: 28,
//                             backgroundImage: NetworkImage(doc.imageUrl),
//                           ),
//                           title: Text(
//                             doc.name,
//                             style: const TextStyle(
//                               fontFamily: 'Poppins',
//                               fontWeight: FontWeight.w600,
//                               fontSize: 16,
//                             ),
//                           ),
//                           subtitle: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const SizedBox(height: 4),
//                               Text(
//                                 doc.specialty,
//                                 style: TextStyle(
//                                   fontFamily: 'Poppins',
//                                   color: Colors.grey.shade700,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 4,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: doc.status == 'Active'
//                                       ? Colors.green.shade100
//                                       : Colors.red.shade100,
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Text(
//                                   doc.status,
//                                   style: TextStyle(
//                                     fontFamily: 'Poppins',
//                                     color: doc.status == 'Active'
//                                         ? Colors.green.shade800
//                                         : Colors.red.shade800,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           trailing: Icon(
//                             Icons.arrow_forward_ios,
//                             color: Colors.grey.shade600,
//                             size: 18,
//                           ),
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => DoctorProfilePage(doctor: doc),
//                               ),
//                             );
//                           },
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'sub-pages/doctor_view_screen.dart';
import 'sub-pages/notification_page.dart';
import 'package:myriad/models/doctor_model.dart';

/// Doctor List Screen
class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  List<Doctor> _doctors = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'All';

  final String apiUrl = 'https://janna-server.onrender.com/api/doctors/all'; // 🔹 Your API

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<void> fetchDoctors() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _doctors = data.map((d) => Doctor.fromJson(d)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load doctors');
      }
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load doctors. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredDoctors = _doctors.where((doc) {
      final matchName = doc.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchStatus =
          _filterStatus == 'All' ||
          doc.status.toLowerCase() == _filterStatus.toLowerCase();
      return matchName && matchStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doctors',
          style: TextStyle(
            fontFamily: 'Sahitya',
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFFB36CC6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationPage()),
              );
            },
          ),
        ],
      ),

      backgroundColor: Colors.grey.shade100,

      body: Column(
        children: [
          // 🔍 Search + Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search doctors...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade600,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFB36CC6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterStatus,
                      dropdownColor: const Color(0xFFB36CC6),
                      items: const [
                        DropdownMenuItem(
                          value: 'All',
                          child: Text(
                            'All',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Active',
                          child: Text(
                            'Active',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Inactive',
                          child: Text(
                            'Inactive',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _filterStatus = value!),
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🩺 Doctor List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDoctors.isEmpty
                ? const Center(
                    child: Text(
                      'No doctors found',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredDoctors.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDoctors[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(doc.imageUrl),
                          ),
                          title: Text(
                            doc.name,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                doc.specialty,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: doc.status == 'Active'
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  doc.status,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: doc.status == 'Active'
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey.shade600,
                            size: 18,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorProfilePage(doctor: doc),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
