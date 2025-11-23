import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sub-pages/notification_page.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  const DoctorAvailabilityScreen({super.key});

  @override
  State<DoctorAvailabilityScreen> createState() =>
      _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  DateTime? selectedDate;
  bool isLoading = false;
  List<dynamic> slots = [];

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _fetchAvailabilities();
  }

  // 📅 Show Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      _fetchAvailabilities();
    }
  }

  // 🌐 Fetch Doctor Availabilities
  Future<void> _fetchAvailabilities() async {
    if (selectedDate == null) return;
    setState(() => isLoading = true);

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      final url = Uri.parse(
        'https://janna-server.onrender.com/api/doctors/availability?date=$formattedDate',
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          slots = data['slots'] ?? [];
        });
      } else {
        _showSnackBar('Failed to fetch availabilities.');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 🆕 Create Availability
  Future<void> _createAvailability(String start, String end) async {
    if (selectedDate == null) {
      _showSnackBar('Please select a date first.');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        _showSnackBar('User not authenticated. Please log in again.');
        return;
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      final url = Uri.parse('https://janna-server.onrender.com/api/doctors/availability');

      final body = jsonEncode({
        "date": formattedDate,
        "start_time": start,
        "end_time": end,
        "status": "available",
      });

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      if (response.statusCode == 201) {
        _showSnackBar('Availability created successfully!');
        _fetchAvailabilities();
      } else {
        debugPrint('❌ Error: ${response.body}');
        _showSnackBar('Failed to create availability.');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  // ❌ Delete Availability
  Future<void> _deleteAvailability(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      print(id);
      final url = Uri.parse(
        'https://janna-server.onrender.com/api/doctors/availability/$id',
      );

      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _showSnackBar('Availability deleted.');
        _fetchAvailabilities();
      } else {
        debugPrint('❌ Delete error: ${response.body}');
        _showSnackBar('Failed to delete availability.');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  // ⚠️ Set Availability Unavailable
  Future<void> _setUnavailable(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final url = Uri.parse(
        'https://janna-server.onrender.com/api/doctors/availability/$id/unavailable',
      );

      final response = await http.put(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _showSnackBar('Slot set to unavailable.');
        _fetchAvailabilities();
      } else {
        debugPrint('❌ Unavailable error: ${response.body}');
        _showSnackBar('Failed to set slot unavailable.');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  // 🧾 Confirm Delete Dialog
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Delete Slot",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          "Are you sure you want to delete this availability?",
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteAvailability(id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  // 🟡 Confirm Unavailable Dialog
  void _confirmSetUnavailable(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Set Slot Unavailable",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          "Are you sure you want to mark this slot as unavailable?",
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(context);
              _setUnavailable(id);
            },
            child: const Text(
              'Set Unavailable',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  // 🕓 Dialog to Select Time
  void _showAddDialog() {
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> _pickStartTime() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 7, minute: 0),
            );
            if (picked != null) {
              if (picked.hour < 7 || picked.hour > 17) {
                _showSnackBar(
                  "Start time must be between 7:00 AM and 5:00 PM.",
                );
                return;
              }
              setState(() => startTime = picked);
            }
          }

          Future<void> _pickEndTime() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 7, minute: 30),
            );
            if (picked != null) {
              if (picked.hour < 7 || picked.hour > 17) {
                _showSnackBar("End time must be between 7:00 AM and 5:00 PM.");
                return;
              }
              if (startTime != null) {
                final startMinutes = startTime!.hour * 60 + startTime!.minute;
                final endMinutes = picked.hour * 60 + picked.minute;
                if (endMinutes - startMinutes < 30) {
                  _showSnackBar(
                    "End time must be at least 30 mins after start.",
                  );
                  return;
                }
              }
              setState(() => endTime = picked);
            }
          }

          String _formatTime(TimeOfDay? t) {
            if (t == null) return '--:--';
            final now = DateTime.now();
            final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
            return DateFormat.jm().format(dt);
          }

          return AlertDialog(
            title: const Text(
              "Add Availability Slot",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    "Start Time: ${_formatTime(startTime)}",
                    style: const TextStyle(fontFamily: 'Poppins'),
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: _pickStartTime,
                ),
                ListTile(
                  title: Text(
                    "End Time: ${_formatTime(endTime)}",
                    style: const TextStyle(fontFamily: 'Poppins'),
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: _pickEndTime,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB36CC6),
                ),
                onPressed: () {
                  if (startTime == null || endTime == null) {
                    _showSnackBar("Please select both start and end times.");
                    return;
                  }
                  final start =
                      "${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}";
                  final end =
                      "${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}";
                  Navigator.pop(context);
                  _createAvailability(start, end);
                },
                child: const Text(
                  'Save',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 📢 Snackbar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = selectedDate != null
        ? DateFormat('MMMM dd, yyyy').format(selectedDate!)
        : 'Select a date';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doctor Availability',
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

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFFB36CC6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Please select a date:',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _selectDate(context),
              icon: const Icon(Icons.calendar_today),
              label: Text(
                formattedDate,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
                side: const BorderSide(width: 1.5, color: Colors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchAvailabilities,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : slots.isEmpty
                    ? const Center(
                        child: Text(
                          'No available slots for this date.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: slots.length,
                        itemBuilder: (context, index) {
                          final slot = slots[index];
                          final id =
                              (slot['availability_id'] ??
                                      slot['availability_id'] ??
                                      '')
                                  .toString();

                          final start = slot['start_time'] ?? 'Unknown';
                          final end = slot['end_time'] ?? 'Unknown';
                          final status = slot['status'] ?? 'available';

                          return Card(
                            elevation: 1,
                            color: status == 'unavailable'
                                ? Colors.grey[300]
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.access_time,
                                color: Colors.blue,
                              ),
                              title: Text(
                                '$start - $end',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                  color: status == 'unavailable'
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (status != 'unavailable')
                                    IconButton(
                                      icon: const Icon(
                                        Icons.block,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () =>
                                          _confirmSetUnavailable(id),
                                      tooltip: 'Set Unavailable',
                                    ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _confirmDelete(id),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
