import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sub-pages/notification_page.dart';
import 'sub-pages/pending_doctors_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedYear = DateTime.now().year;
  final List<int> years = [2023, 2024, 2025, 2026];

  int doctorCount = 0;
  int eventCount = 0;
  int unreadMessages = 0;

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  // 🔹 Fetch event stats for graph
  Future<Map<int, int>> fetchEventStats(int year) async {
    final url = Uri.parse('https://janna-server.onrender.com/api/events/stats/$year');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> dataList = decoded['data'] ?? [];
      final Map<int, int> monthCounts = {};
      for (var item in dataList) {
        final monthName = item['month'];
        final count = item['count'];
        monthCounts[_monthNameToNumber(monthName)] = count ?? 0;
      }
      return monthCounts;
    } else {
      throw Exception("Failed to load event stats: ${response.statusCode}");
    }
  }

  // 🔹 Fetch appointment stats for graph
  Future<Map<int, int>> fetchAppointmentStats(int year) async {
    final url = Uri.parse('https://janna-server.onrender.com/api/appointments/stats/$year');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> dataList = decoded['data'] ?? [];
      final Map<int, int> monthCounts = {};
      for (var item in dataList) {
        final monthName = item['month'];
        final count = item['count'];
        monthCounts[_monthNameToNumber(monthName)] = count ?? 0;
      }
      return monthCounts;
    } else {
      throw Exception(
        "Failed to load appointment stats: ${response.statusCode}",
      );
    }
  }

  Future<void> fetchCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    final url = Uri.parse('https://janna-server.onrender.com/api/dashboard/counts');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      setState(() {
        doctorCount = decoded['doctorCount'] ?? 0;
        eventCount = decoded['eventCount'] ?? 0;
        unreadMessages = decoded['unreadMessages'] ?? 0;
      });
    } else {
      throw Exception("Failed to load counts");
    }
  }

  Future<List<Map<String, dynamic>>> fetchUpcomingEvents() async {
    final url = Uri.parse('https://janna-server.onrender.com/api/events/upcoming');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List events = decoded['events'] ?? decoded['data'] ?? [];
      return events.map<Map<String, dynamic>>((e) {
        return {
          'title': e['title'] ?? 'Untitled Event',
          'date': e['date'] ?? 'TBA',
          'imageUrl': e['image'],
        };
      }).toList();
    } else {
      throw Exception("Failed to load upcoming events");
    }
  }

  int _monthNameToNumber(String month) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    return months[month] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = "${now.month}/${now.day}/${now.year}";

    final recentMessage = {
      'name': 'Dr. Emily Santos',
      'message': 'Hello! Just wanted to confirm our meeting tomorrow.',
      'imageUrl': 'https://picsum.photos/seed/doctor1/100',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(
            fontFamily: 'Sahitya', // ✅ Custom font
            fontWeight: FontWeight.w700, // ✅ Bold weight
            fontSize: 22, // optional, looks better for title
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(
          0xFFB36CC6,
        ), // ✅ same as your footer tabs color
        foregroundColor: Colors.white, // for title and icons
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // 🔽 Year Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Year:',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  DropdownButton<int>(
                    value: selectedYear,
                    items: years.map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(
                          '$year',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                    style: const TextStyle(color: Colors.black87),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedYear = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            // 📊 Stats Overview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard(
                    'Doctors',
                    doctorCount,
                    Icons.medical_services,
                  ),
                  _buildStatCard('Events', eventCount, Icons.event),
                  _buildStatCard('Messages', unreadMessages, Icons.message),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Pending Doctors Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PendingDoctorsPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.pending_actions, color: Colors.white),
                  label: const Text(
                    'View Pending Doctor Applications',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB36CC6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 📊 Appointment Graph
            _buildGraphSection(
              'Monthly Appointments ($selectedYear)',
              fetchAppointmentStats(selectedYear),
              const Color(0xFFB36CC6),
            ),

            // 📊 Event Graph
            _buildGraphSection(
              'Monthly Events ($selectedYear)',
              fetchEventStats(selectedYear),
              Colors.orangeAccent,
            ),

            const SizedBox(height: 24),

            // 🕒 Upcoming Events
            _buildSectionTitle('Upcoming Events'),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchUpcomingEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                  );
                }

                final events = snapshot.data ?? [];
                if (events.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "No upcoming events this month.",
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  );
                }

                return SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16),
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
                                  event['imageUrl'],
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
                                      event['title'],
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Color(0xFFB36CC6),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Date: ${event['date']}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
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
                );
              },
            ),

            const SizedBox(height: 24),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 🔹 Graph Section Builder
  Widget _buildGraphSection(
    String title,
    Future<Map<int, int>> future,
    Color color,
  ) {
    return FutureBuilder<Map<int, int>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Error loading $title: ${snapshot.error}",
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
          );
        }

        final stats = snapshot.data ?? {};
        if (stats.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "No data available for $title.",
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
          );
        }

        final barGroups = stats.entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.toDouble(),
                color: color,
                width: 16,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }).toList();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const months = [
                                '',
                                'Jan',
                                'Feb',
                                'Mar',
                                'Apr',
                                'May',
                                'Jun',
                                'Jul',
                                'Aug',
                                'Sep',
                                'Oct',
                                'Nov',
                                'Dec',
                              ];
                              return Text(
                                months[value.toInt()],
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'Poppins',
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: barGroups,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon) {
    Future<Map<String, dynamic>> Function()? apiCall;

    if (label == 'Doctors') {
      apiCall = fetchDoctorStats;
    } else if (label == 'Events') {
      apiCall = fetchEventStatsDetails;
    } else if (label == 'Messages') {
      apiCall = fetchMessageStats;
    }

    return Expanded(
      child: InkWell(
        onTap: apiCall != null
            ? () => _showStatsModal(
                title: '$label Statistics',
                future: apiCall!(),
                icon: icon,
              )
            : null,
        borderRadius: BorderRadius.circular(12),
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
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showStatsModal({
    required String title,
    required Future<Map<String, dynamic>> future,
    required IconData icon,
  }) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return FutureBuilder<Map<String, dynamic>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: Color(0xFFB36CC6),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                  );
                }

                final stats = snapshot.data ?? {};
                if (stats.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No data available.',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  );
                }

                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🟣 Top drag handle
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // 🩺 Title
                      Row(
                        children: [
                          Icon(icon, color: const Color(0xFFB36CC6)),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 📊 Stats List
                      ...stats.entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F4FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFB36CC6).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _capitalize(entry.key),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${entry.value}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFFB36CC6),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),

                      // ✖️ Close button
                      Center(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB36CC6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _capitalize(String text) =>
      text.isNotEmpty ? '${text[0].toUpperCase()}${text.substring(1)}' : text;

  Future<Map<String, dynamic>> fetchDoctorStats() async {
    final url = Uri.parse('https://janna-server.onrender.com/api/doctors/stats');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load doctor stats');
    }
  }

  Future<Map<String, dynamic>> fetchEventStatsDetails() async {
    final url = Uri.parse('https://janna-server.onrender.com/api/events/stats-2');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load event stats');
    }
  }

  Future<Map<String, dynamic>> fetchMessageStats() async {
    //get token from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('https://janna-server.onrender.com/api/messages/stats');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load message stats');
    }
  }
}
