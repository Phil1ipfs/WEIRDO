import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'sub-pages/chat_view_screen.dart';
import 'sub-pages/notification_page.dart';

class DoctorConsultation extends StatefulWidget {
  const DoctorConsultation({super.key});

  @override
  State<DoctorConsultation> createState() => _DoctorConsultationState();
}

class _DoctorConsultationState extends State<DoctorConsultation> {
  List<Map<String, dynamic>> appointments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() => isLoading = false);
        return;
      }

      final url = Uri.parse("https://janna-server.onrender.com/api/appointments/doctor");
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          appointments = data.map((item) {
            final clientData =
                item['user']?['clients'] != null &&
                    item['user']['clients'].isNotEmpty
                ? item['user']['clients'][0]
                : item['user'];

            final patientName =
                "${clientData['first_name']} ${clientData['last_name']}";

            final availability = item['availability'] ?? {};
            final timeRange = availability.isNotEmpty
                ? "${availability['start_time'] ?? ''} - ${availability['end_time'] ?? ''}"
                : '';

            return {
              'patientName': patientName,
              'remarks': item['remarks'] ?? '',
              'date': item['date'],
              'time': timeRange,
              'status': item['status'] ?? 'Ongoing',
              'user_id': item['user_id'],
              'doctor_id': item['doctor']['doctor_id'],
              'doctor_user_id': item['doctor']['user_id'],
              'appointment_id': item['appointment_id'],
            };
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load appointments: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching appointments: $e");
      setState(() => isLoading = false);
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _openChat(Map<String, dynamic> appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatViewScreen(
          currentUserId: appointment['doctor_user_id'],
          userId: appointment['user_id'],
          name: appointment['patientName'],
          status: appointment['status'],
          appointmentId: appointment['appointment_id'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Consultations",
          style: TextStyle(
            fontFamily: 'Sahitya',
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFB36CC6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationPage()),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchAppointments,
              color: const Color(0xFFB36CC6),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: appointments.isEmpty
                    ? const Center(child: Text("No appointments found."))
                    : ListView.builder(
                        itemCount: appointments.length,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                        final appointment = appointments[index];
                        final formattedDate = DateFormat(
                          'MMMM d, y',
                        ).format(DateTime.parse(appointment['date']));
                        final statusColor = getStatusColor(
                          appointment['status'],
                        );

                        return InkWell(
                          onTap: () => _openChat(appointment),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFFB36CC6),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            appointment['time'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              appointment['patientName'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),
                                  if (appointment['remarks'].isNotEmpty)
                                    Text(
                                      appointment['remarks'],
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          border: Border.all(
                                            color: statusColor,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          appointment['status'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ),
    );
  }
}
