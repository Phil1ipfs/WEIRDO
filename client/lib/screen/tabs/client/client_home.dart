import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'sub-pages/notification_page.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({super.key});

  @override
  State<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  int eventCount = 0;
  int unreadMessages = 0;
  int appointmentCount = 0;
  List<dynamic> upcomingEvents = [];
  List<dynamic> recentArticles = [];
  Map<String, dynamic>? recentMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final res = await http.get(
        Uri.parse('https://janna-server.onrender.com/api/clients/dashboard'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        setState(() {
          upcomingEvents = data['upcomingEvents'] ?? [];
          recentArticles = data['recentArticles'] ?? [];
          recentMessage = data['recentMessage'];
          appointmentCount = (data['upcomingAppointments'] ?? []).length;
          eventCount = upcomingEvents.length;
          unreadMessages = (recentMessage != null && recentMessage!.isNotEmpty)
              ? 1
              : 0;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load dashboard data");
      }
    } catch (e) {
      print("Error fetching dashboard: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Client Dashboard",
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

      backgroundColor: const Color(0xFFF9FAFB),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // 📊 Stats (Now Clickable)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard('Events', eventCount, Icons.event),
                        _buildStatCard(
                          'Messages',
                          unreadMessages,
                          Icons.message,
                        ),
                        _buildStatCard(
                          'Appointments',
                          appointmentCount,
                          Icons.calendar_today,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🕒 Upcoming Events
                  _sectionTitle('Upcoming Events'),
                  _buildHorizontalList(
                    upcomingEvents,
                    itemBuilder: (event) => _buildEventCard(event),
                  ),

                  const SizedBox(height: 24),

                  // 📰 Recent Articles
                  _sectionTitle('Recent Articles'),
                  _buildHorizontalList(
                    recentArticles,
                    itemBuilder: (article) => _buildArticleCard(article),
                  ),

                  const SizedBox(height: 24),

                  // 💬 Recent Message
                  _sectionTitle('Recent Message'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child:
                            recentMessage != null && recentMessage!.isNotEmpty
                            ? Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage: NetworkImage(
                                      recentMessage?['sender']?['profile_picture'] ??
                                          'https://via.placeholder.com/150',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          recentMessage?['sender']?['email'] ??
                                              'Unknown sender',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          recentMessage?['content'] ?? '',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                "No recent messages",
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
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

  Future<void> _showStatDetails(String label) async {
    Future<List<Map<String, dynamic>>> Function()? apiCall;

    if (label == 'Events') apiCall = _fetchEventStats;
    if (label == 'Messages') apiCall = _fetchMessageStats;
    if (label == 'Appointments') apiCall = _fetchAppointmentStats;

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
            return FutureBuilder<List<Map<String, dynamic>>>(
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
                      ),
                    ),
                  );
                }

                final data = snapshot.data ?? [];

                if (data.isEmpty) {
                  return const Center(child: Text("No data available"));
                }

                return Column(
                  children: [
                    // 🟣 Modal Header Title
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFB36CC6),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // 📋 List Content
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final item = data[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: Icon(
                                label == 'Events'
                                    ? Icons.event
                                    : label == 'Messages'
                                    ? Icons.message
                                    : Icons.calendar_today,
                                color: const Color(0xFFB36CC6),
                              ),
                              title: Text(item['title'] ?? 'Unknown'),
                              subtitle: Text(item['content'] ?? ''),
                            ),
                          );
                        },
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

  // 🧱 Safe JSON Decode
  dynamic _safeJsonDecode(String body) {
    try {
      if (body.isEmpty) return [];
      final decoded = json.decode(body);
      if (decoded is Map || decoded is List) return decoded;
      return [];
    } catch (e) {
      print("❌ JSON Decode Error: $e");
      print("Response body: $body");
      return [];
    }
  }

  // 📊 FETCH FUNCTIONS
  Future<List<Map<String, dynamic>>> _fetchEventStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('https://janna-server.onrender.com/api/events/stats-2'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = _safeJsonDecode(response.body);
      if (data is Map) {
        return data.entries
            .map(
              (e) => {
                'title': e.key.toUpperCase(),
                'content': e.value.toString(),
              },
            )
            .toList();
      }
    }
    throw Exception('Failed to load event stats');
  }

  Future<List<Map<String, dynamic>>> _fetchAppointmentStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('https://janna-server.onrender.com/api/appointments/client'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = _safeJsonDecode(response.body);
      if (data is List) {
        return data.map((a) {
          final doctor = a['doctor'] ?? {};
          final availability = a['availability'] ?? {};
          return {
            'title':
                'Dr. ${doctor['first_name'] ?? ''} ${doctor['last_name'] ?? ''}',
            'content':
                'Date: ${a['date']} | Time: ${availability['start_time']} | Status: ${a['status']}',
          };
        }).toList();
      }
    }
    throw Exception('Failed to load appointment stats');
  }

  Future<List<Map<String, dynamic>>> _fetchMessageStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('https://janna-server.onrender.com/api/messages/stats'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = _safeJsonDecode(response.body);
      if (data is Map) {
        return data.entries
            .map(
              (e) => {
                'title': e.key.toUpperCase(),
                'content': e.value.toString(),
              },
            )
            .toList();
      }
    }
    throw Exception('Failed to load message stats');
  }

  // 🧱 Section Builders
  Widget _sectionTitle(String title) {
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

  Widget _buildHorizontalList(
    List<dynamic> items, {
    required Widget Function(dynamic item) itemBuilder,
  }) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text("No items available"),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: items.length,
        itemBuilder: (context, index) => itemBuilder(items[index]),
      ),
    );
  }

  Widget _buildEventCard(dynamic event) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                event['image'] ?? 'https://via.placeholder.com/600x200',
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
                    event['title'] ?? 'Untitled Event',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFFB36CC6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Date: ${event['date'] ?? 'TBA'}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(dynamic article) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article['title'] ?? 'Untitled Article',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFFB36CC6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                (article['excerpt'] ??
                    article['content'] ??
                    'No description available'),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
