import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Availability model
class Availability {
  final DateTime date;
  final String time; // "start - end"
  final String status;

  Availability({required this.date, required this.time, required this.status});

  factory Availability.fromJson(Map<String, dynamic> json) {
    final start = json['start_time'] ?? 'N/A';
    final end = json['end_time'] ?? 'N/A';
    return Availability(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      time: '$start - $end',
      status: json['status'] ?? 'available',
    );
  }
}

/// Appointment model
class AppointmentEntry {
  final String doctorName;
  final String status;
  final DateTime date; // appointment date
  final String remarks;
  final Availability? availability;

  AppointmentEntry({
    required this.doctorName,
    required this.status,
    required this.date,
    required this.remarks,
    this.availability,
  });

  factory AppointmentEntry.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'];
    final avail = json['availability'];

    return AppointmentEntry(
      doctorName: doctor != null
          ? '${doctor['first_name']} ${doctor['last_name']}'
          : 'N/A',
      status: json['status'] ?? 'Pending',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      remarks: json['remarks'] ?? '',
      availability: avail != null ? Availability.fromJson(avail) : null,
    );
  }
}

/// Client model
class Client {
  final int id;
  final String name;
  final String email;
  final String contact;
  final String role;
  final DateTime createdAt;
  final List<AppointmentEntry> appointments;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.contact,
    required this.role,
    required this.createdAt,
    required this.appointments,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    final appointments = user['appointments'] as List<dynamic>? ?? [];

    return Client(
      id: json['client_id'],
      name:
          '${json['first_name']} ${json['middle_name'] ?? ''} ${json['last_name']}'
              .trim(),
      email: user['email'] ?? 'N/A',
      contact: json['contact_number'] ?? 'N/A',
      role: user['role'] ?? 'client',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      appointments: appointments
          .map((a) => AppointmentEntry.fromJson(a))
          .toList(),
    );
  }
}

/// Main Client Screen
class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  List<Client> _clients = [];
  bool _isLoading = true;
  String _searchQuery = '';

  final String apiUrl = 'https://janna-server.onrender.com/api/clients/all';

  @override
  void initState() {
    super.initState();
    fetchClients();
  }

  Future<void> fetchClients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _clients = data.map((c) => Client.fromJson(c)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load clients');
      }
    } catch (e) {
      debugPrint('Error fetching clients: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load clients. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredClients = _clients.where((c) {
      return c.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Clients',
          style: TextStyle(
            fontFamily: 'Sahitya',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFB36CC6),
        foregroundColor: Colors.white,
      ),
      body: Column( 
        children: [
          // 🔍 Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search clients...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 👥 Client List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredClients.isEmpty
                ? const Center(child: Text('No clients found'))
                : ListView.builder(
                    itemCount: filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = filteredClients[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFB36CC6),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            client.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _showClientDetailPanel(client),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 🔹 Status Chip (for appointments only)
  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'active':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        break;
      case 'inactive':
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        break;
      case 'pending':
      default:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showClientDetailPanel(Client client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.purple.shade50,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          height: 5,
                          width: 50,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Header with avatar & name
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: const Color(0xFFB36CC6),
                            child: Text(
                              client.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  client.email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      _infoCard(client),

                      const SizedBox(height: 24),
                      const Text(
                        "Appointments",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5A2D82),
                        ),
                      ),
                      const SizedBox(height: 12),

                      client.appointments.isEmpty
                          ? Center(
                              child: Text(
                                "No appointments yet.",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: client.appointments.length,
                              itemBuilder: (context, index) {
                                final appt = client.appointments[index];
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFB36CC6,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.event_note,
                                        color: Color(0xFFB36CC6),
                                      ),
                                    ),
                                    title: Text(
                                      appt.doctorName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${appt.date.year}-${appt.date.month.toString().padLeft(2, '0')}-${appt.date.day.toString().padLeft(2, '0')}',
                                        ),
                                        if (appt.remarks.isNotEmpty)
                                          Text('Remarks: ${appt.remarks}'),
                                        if (appt.availability != null)
                                          Text(
                                            'Availability: ${appt.availability!.date.year}-${appt.availability!.date.month.toString().padLeft(2, '0')}-${appt.availability!.date.day.toString().padLeft(2, '0')} '
                                            '${appt.availability!.time} (${appt.availability!.status})',
                                          ),
                                      ],
                                    ),
                                    trailing: _statusChip(appt.status),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoCard(Client client) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.phone, "Contact", client.contact),
          _infoRow(Icons.verified_user, "Role", client.role),
          _infoRow(
            Icons.calendar_today,
            "Created At",
            client.createdAt.toLocal().toString(),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFB36CC6)),
          const SizedBox(width: 10),
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
