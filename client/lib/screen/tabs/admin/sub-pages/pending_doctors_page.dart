import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';

class PendingDoctorsPage extends StatefulWidget {
  const PendingDoctorsPage({super.key});

  @override
  State<PendingDoctorsPage> createState() => _PendingDoctorsPageState();
}

class _PendingDoctorsPageState extends State<PendingDoctorsPage> {
  List<dynamic> pendingDoctors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPendingDoctors();
  }

  Future<void> fetchPendingDoctors() async {
    setState(() => isLoading = true);
    try {
      final doctors = await AuthService.getPendingDoctors();
      setState(() {
        pendingDoctors = doctors;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> approveDoctor(int doctorId) async {
    final result = await AuthService.approveDoctor(doctorId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    }
    if (result['success']) {
      fetchPendingDoctors();
    }
  }

  Future<void> rejectDoctor(int doctorId) async {
    final result = await AuthService.rejectDoctor(doctorId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    }
    if (result['success']) {
      fetchPendingDoctors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pending Doctor Approvals',
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
          : pendingDoctors.isEmpty
              ? const Center(
                  child: Text(
                    'No pending doctor approvals',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchPendingDoctors,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pendingDoctors.length,
                    itemBuilder: (context, index) {
                      final doctor = pendingDoctors[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFB36CC6),
                                    child: Text(
                                      '${doctor['first_name'][0]}${doctor['last_name'][0]}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${doctor['first_name']} ${doctor['last_name']}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          doctor['user']['email'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.medical_services, 'Field', doctor['field']['field_name']),
                              _buildInfoRow(Icons.phone, 'Contact', doctor['contact_number']),
                              _buildInfoRow(Icons.person, 'Gender', doctor['gender']),
                              if (doctor['id_number'] != null)
                                _buildInfoRow(Icons.badge, 'ID Number', doctor['id_number']),

                              // Valid ID Image
                              if (doctor['valid_id'] != null) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Valid ID:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        child: Image.network(
                                          'https://janna-server.onrender.com${doctor['valid_id']}',
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Text('Failed to load image'),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        'https://janna-server.onrender.com${doctor['valid_id']}',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Center(child: Icon(Icons.error)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => rejectDoctor(doctor['doctor_id']),
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    label: const Text(
                                      'Reject',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.red.shade50,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () => approveDoctor(doctor['doctor_id']),
                                    icon: const Icon(Icons.check, color: Colors.white),
                                    label: const Text(
                                      'Approve',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
