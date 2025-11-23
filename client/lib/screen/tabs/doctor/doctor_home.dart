import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'sub-pages/notification_page.dart';

class DoctorHome extends StatefulWidget {
  const DoctorHome({super.key});

  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome> {
  late Future<Map<String, dynamic>> dashboardData;

  @override
  void initState() {
    super.initState();
    dashboardData = fetchDoctorDashboard();
  }

  Future<Map<String, dynamic>> fetchDoctorDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception("Authorization token not found.");

    const String apiUrl = "https://janna-server.onrender.com/api/doctors/dashboard";

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load dashboard");
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = "${now.month}/${now.day}/${now.year}";

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          "Doctor Dashboard",
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
        ],
      ),

      // BODY
      body: FutureBuilder<Map<String, dynamic>>(
        future: dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No data available"));
          }

          final data = snapshot.data!;
          final appointments = data['appointments'] as List<dynamic>;
          final events = data['events'] as List<dynamic>;
          final recentMessage = data['recentMessage'] ?? {};
          final availabilities = data['availabilities'] as List<dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // 📊 Stats (Now Clickable)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(
                      "Patients",
                      appointments.length,
                      Icons.people,
                    ),
                    _buildStatCard(
                      "Messages",
                      recentMessage.isNotEmpty ? 1 : 0,
                      Icons.message_outlined,
                    ),
                    _buildStatCard("Events", events.length, Icons.event),
                  ],
                ),

                const SizedBox(height: 32),

                const SizedBox(height: 32),

                // 🩺 Upcoming Appointments
                const Text(
                  "Upcoming Appointments",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...appointments.map((app) {
                  final client = app['user']?['clients']?[0];
                  final fullName = client != null
                      ? "${client['first_name']} ${client['last_name']}"
                      : "Unknown";

                  return _buildAppointmentCard(
                    name: fullName,
                    date: app['date'] ?? "",
                    time:
                        app['availability']?['start_time'] ??
                        "", // or format as needed
                    profileColor: Colors.teal,
                  );
                }).toList(),

                const SizedBox(height: 24),

                // 🗓️ Events
                const Text(
                  "Upcoming Events",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 12),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.network(
                                  event['image'] ??
                                      'https://via.placeholder.com/280x120',
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event['title'] ?? "Untitled Event",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Date: ${event['date'] ?? ""}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // 💬 Recent Message
                const Text(
                  "Recent Message",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (recentMessage.isNotEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          recentMessage['imageUrl'] ??
                              'https://via.placeholder.com/100',
                        ),
                        radius: 26,
                      ),
                      title: Text(
                        recentMessage['name'] ?? "Unknown",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        recentMessage['message'] ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ),

                const SizedBox(height: 24),

                // 🕒 Doctor Availabilities
                const Text(
                  "Today's Availability",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    // Filter out past time slots
                    final now = DateTime.now();
                    final currentTime = TimeOfDay.fromDateTime(now);
                    
                    final futureSlots = availabilities.where((slot) {
                      final startTimeStr = slot['start_time'] as String?;
                      if (startTimeStr == null || startTimeStr.isEmpty) return false;
                      
                      try {
                        // Parse time string - handle both "HH:mm" and "HH:mm:ss" formats
                        // Remove any whitespace and split by ':'
                        final cleanTime = startTimeStr.trim();
                        final timeParts = cleanTime.split(':');
                        
                        // Need at least hour and minute (2 parts minimum)
                        if (timeParts.length < 2) return false;
                        
                        final slotHour = int.parse(timeParts[0]);
                        final slotMinute = int.parse(timeParts[1]);
                        
                        // Validate hour and minute ranges
                        if (slotHour < 0 || slotHour > 23) return false;
                        if (slotMinute < 0 || slotMinute > 59) return false;
                        
                        final slotTime = TimeOfDay(hour: slotHour, minute: slotMinute);
                        
                        // Compare with current time
                        // Convert to minutes for easy comparison
                        final slotMinutes = slotTime.hour * 60 + slotTime.minute;
                        final currentMinutes = currentTime.hour * 60 + currentTime.minute;
                        
                        // Show slots that haven't started yet (start_time >= current_time)
                        return slotMinutes >= currentMinutes;
                      } catch (e) {
                        // If parsing fails, exclude the slot
                        print('Error parsing time: $startTimeStr - $e');
                        return false;
                      }
                    }).toList();
                    
                    if (futureSlots.isEmpty)
                      return const Text("No available slots for today.");
                    
                    return Column(
                      children: futureSlots.map((slot) {
                        // Format time display (remove seconds if present)
                        String formatTime(String? timeStr) {
                          if (timeStr == null || timeStr.isEmpty) return '';
                          final parts = timeStr.split(':');
                          if (parts.length >= 2) {
                            return '${parts[0]}:${parts[1]}';
                          }
                          return timeStr;
                        }
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              "${formatTime(slot['start_time'])} - ${formatTime(slot['end_time'])}",
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              "Status: ${slot['status'] ?? 'available'}",
                            ),
                            leading: const Icon(Icons.access_time),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showStatDetails(String label) async {
    Future<dynamic> Function()? apiCall;

    if (label == 'Messages') {
      apiCall = _fetchMessageStats;
    } else if (label == 'Events') {
      apiCall = _fetchEventStats;
    } else if (label == 'Patients') {
      apiCall = _fetchAppointmentStats;
    }

    if (apiCall == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return FutureBuilder<dynamic>(
              future: apiCall!(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        '⚠️ Error loading $label data:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Text(
                      "No data available",
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  );
                }

                final data = snapshot.data;

                return Column(
                  children: [
                    // ───── Header Bar ─────
                    Container(
                      width: 60,
                      height: 5,
                      margin: const EdgeInsets.only(top: 12, bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            label == 'Patients'
                                ? Icons.people
                                : label == 'Messages'
                                ? Icons.message_outlined
                                : Icons.event,
                            color: const Color(0xFFB36CC6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "$label Details",
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B3B3B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // ───── Content ─────
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: data is List
                            ? _buildListModal(data, scrollController)
                            : _buildMapModal(data, scrollController),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildListModal(
    List<dynamic> data,
    ScrollController scrollController,
  ) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final client = item['user']?['clients']?[0];
        final availability = item['availability'];
        final status = item['status'] ?? "Unknown";

        Color statusColor;
        switch (status) {
          case 'Completed':
            statusColor = Colors.green;
            break;
          case 'Pending':
            statusColor = Colors.orange;
            break;
          case 'Cancelled':
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.grey;
        }

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.black12,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(
                        0xFFB36CC6,
                      ).withOpacity(0.15),
                      child: const Icon(Icons.person, color: Color(0xFFB36CC6)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "${client?['first_name']} ${client?['last_name']}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Date: ${availability?['date'] ?? 'N/A'}",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      "Time: ${availability?['start_time'] ?? ''} - ${availability?['end_time'] ?? ''}",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapModal(
    Map<String, dynamic> data,
    ScrollController controller,
  ) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        ...data.entries.map((entry) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
            shadowColor: Colors.black12,
            child: ListTile(
              leading: const Icon(Icons.bar_chart, color: Color(0xFFB36CC6)),
              title: Text(
                entry.key,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Text(
                '${entry.value}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B3B3B),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showStatDetails(label),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Icon(icon, color: const Color(0xFFB36CC6)),
                const SizedBox(height: 8),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔸 APPOINTMENT CARD
  Widget _buildAppointmentCard({
    required String name,
    required String date,
    required String time,
    required Color profileColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: profileColor,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("$date • $time"),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchMessageStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('https://janna-server.onrender.com/api/messages/stats'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load message stats');
    }
  }

  Future<Map<String, dynamic>> _fetchEventStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('https://janna-server.onrender.com/api/events/stats-2'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load event stats');
    }
  }

  Future<List<dynamic>> _fetchAppointmentStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('https://janna-server.onrender.com/api/appointments/stats'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data;
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      throw Exception('Failed to load appointment stats');
    }
  }
}
