import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'sub-pages/client_appointment.dart';
import 'sub-pages/chat_view_screen.dart';

class ClientConsultation extends StatefulWidget {
  const ClientConsultation({super.key});

  @override
  State<ClientConsultation> createState() => _ClientConsultationState();
}

class _ClientConsultationState extends State<ClientConsultation> {
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

      final url = Uri.parse("https://janna-server.onrender.com/api/appointments/client");
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
          appointments = data
              .map((item) => item as Map<String, dynamic>)
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load appointments: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching appointments: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'ongoing':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.grey;

      default:
        return Colors.grey;
    }
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    final formattedDate = DateFormat(
      'MMMM d, y',
    ).format(DateTime.parse(appointment['availability']['date']));

    final startTime = appointment['availability']['start_time'];
    final endTime = appointment['availability']['end_time'];
    final time = "$startTime - $endTime";

    final doctor =
        "${appointment['doctor']['first_name']} ${appointment['doctor']['last_name']}";

    final appointmentDateTime = DateTime.parse(
      "${appointment['availability']['date']} ${appointment['availability']['start_time']}",
    );
    final now = DateTime.now();

    final status = appointment['status'].toString().toLowerCase();

    final isBefore = now.isBefore(appointmentDateTime);
    final isDuring =
        now.isAfter(appointmentDateTime.subtract(const Duration(minutes: 5))) &&
        now.isBefore(appointmentDateTime.add(const Duration(minutes: 30))) &&
        status != 'completed'; // only show Start Consultation if not completed
    final isAfter = now.isAfter(
      appointmentDateTime.add(const Duration(minutes: 30)),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Appointment Details",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Dr. $doctor",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(formattedDate, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 20),
                    const Icon(Icons.access_time, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Text(time, style: const TextStyle(fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 16),

                if (appointment['remarks'] != null &&
                    appointment['remarks'].isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notes, color: Colors.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            appointment['remarks'],
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // ✅ Action Section
                if (status == 'pending' && isBefore)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _cancelAppointment(appointment['appointment_id']);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB36CC6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: const Text(
                        "Cancel Appointment",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                else if (status == 'ongoing')
                  Column(
                    children: [
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatViewScreen(
                                  currentUserId: appointment['user_id'],
                                  userId: appointment['doctor']['user_id'],
                                  name:
                                      "Dr. ${appointment['doctor']['first_name']} ${appointment['doctor']['last_name']}",
                                  status: status,
                                  appointmentId: appointment['appointment_id'],
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5C6BC0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.chat_bubble, color: Colors.white),
                          label: const Text(
                            "Open Chat",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _completeAppointment(appointment['appointment_id']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          icon:
                              const Icon(Icons.check_circle, color: Colors.white),
                          label: const Text(
                            "Close Appointment",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (isDuring)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _markAppointmentOngoing(
                          appointment['appointment_id'],
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatViewScreen(
                              currentUserId: appointment['user_id'],
                              userId: appointment['doctor']['user_id'],
                              name:
                                  "Dr. ${appointment['doctor']['first_name']} ${appointment['doctor']['last_name']}",
                              status: 'ongoing',
                              appointmentId: appointment['appointment_id'],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.video_call, color: Colors.white),
                      label: const Text(
                        "Start Consultation",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                else if ((status == 'completed' || isAfter) &&
                    status != 'missed')
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatViewScreen(
                              currentUserId: appointment['user_id'],
                              userId: appointment['doctor']['user_id'],
                              name:
                                  "Dr. ${appointment['doctor']['first_name']} ${appointment['doctor']['last_name']}",
                              status: status,
                              appointmentId: appointment['appointment_id'],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: const Text(
                        "Open Chat",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "No actions available at this time.",
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _markAppointmentOngoing(int appointmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final url = Uri.parse(
        "https://janna-server.onrender.com/api/appointments/$appointmentId/ongoing",
      );
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appointment is now Ongoing.")),
        );
        fetchAppointments();
      } else {
        throw Exception("Failed to mark appointment as ongoing");
      }
    } catch (e) {
      debugPrint("Error marking appointment as ongoing: $e");
    }
  }

  Future<void> _completeAppointment(int appointmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final url = Uri.parse(
        "https://janna-server.onrender.com/api/appointments/$appointmentId/complete",
      );
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appointment completed successfully.")),
        );
        fetchAppointments();
      } else {
        throw Exception("Failed to complete appointment");
      }
    } catch (e) {
      debugPrint("Error completing appointment: $e");
    }
  }

  Future<void> _cancelAppointment(int appointmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final url = Uri.parse(
        "https://janna-server.onrender.com/api/appointments/$appointmentId/cancel",
      );
      final response = await http.put(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        fetchAppointments();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Appointment cancelled.")));
      } else {
        throw Exception("Failed to cancel appointment");
      }
    } catch (e) {
      print("Error cancelling appointment: $e");
    }
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
        backgroundColor: const Color(0xFFB36CC6),
        foregroundColor: Colors.white,
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
                          final availability = appointment['availability'];
                          final formattedDate = DateFormat(
                            'MMMM d, y',
                          ).format(DateTime.parse(availability['date']));
                          final timeRange =
                              "${availability['start_time']} - ${availability['end_time']}";
                          final statusColor = getStatusColor(
                            appointment['status'],
                          );

                          return InkWell(
                            onTap: () => _showAppointmentDetails(appointment),
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
                                              timeRange,
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
                                                "${appointment['doctor']['first_name']} ${appointment['doctor']['last_name']}",
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
                                    Text(
                                      appointment['remarks'] ?? '',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => const FractionallySizedBox(
              heightFactor: 0.95,
              child: ClientAppointmentPage(),
            ),
          );
        },
        backgroundColor: const Color(0xFFB36CC6),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Schedule Appointment',
      ),
    );
  }
}
