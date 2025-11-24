import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PendingDoctorsPage extends StatefulWidget {
  const PendingDoctorsPage({super.key});

  @override
  State<PendingDoctorsPage> createState() => _PendingDoctorsPageState();
}

class _PendingDoctorsPageState extends State<PendingDoctorsPage> {
  List<dynamic> _pendingDoctors = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadPendingDoctors();
  }

  Future<void> _loadPendingDoctors() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('https://janna-server.onrender.com/api/auth/doctors/pending'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pendingDoctors = data['doctors'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load pending doctors');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _approveDoctor(int doctorId) async {
    try {
      final response = await http.put(
        Uri.parse('https://janna-server.onrender.com/api/auth/doctors/$doctorId/approve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Doctor approved successfully')),
          );
        }
        _loadPendingDoctors(); // Reload the list
      } else {
        throw Exception('Failed to approve doctor');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rejectDoctor(int doctorId) async {
    try {
      final response = await http.put(
        Uri.parse('https://janna-server.onrender.com/api/auth/doctors/$doctorId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Doctor rejected')),
          );
        }
        _loadPendingDoctors(); // Reload the list
      } else {
        throw Exception('Failed to reject doctor');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F0),
      appBar: AppBar(
        title: const Text(
          'Pending Doctors',
          style: TextStyle(
            fontFamily: 'Sahitya',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB36CC6),
          ),
        ),
        backgroundColor: const Color(0xFFF6F4F0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFB36CC6)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingDoctors.isEmpty
              ? const Center(
                  child: Text(
                    'No pending doctors',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPendingDoctors,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingDoctors.length,
                    itemBuilder: (context, index) {
                      final doctor = _pendingDoctors[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${doctor['first_name']} ${doctor['middle_name'] ?? ''} ${doctor['last_name']}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB36CC6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Email: ${doctor['user']?['email'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Field: ${doctor['field']?['name'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Contact: ${doctor['contact_number']}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              if (doctor['valid_id'] != null)
                                Text(
                                  'Valid ID: ${doctor['valid_id']}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => _rejectDoctor(doctor['doctor_id']),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _approveDoctor(doctor['doctor_id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFB36CC6),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Approve'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
