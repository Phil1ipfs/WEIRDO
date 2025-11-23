import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // for token or user_id storage

class ClientAppointmentPage extends StatefulWidget {
  const ClientAppointmentPage({super.key});

  @override
  State<ClientAppointmentPage> createState() => _ClientAppointmentPageState();
}

class _ClientAppointmentPageState extends State<ClientAppointmentPage> {
  DateTime? selectedDate;
  Map<String, dynamic>? selectedDoctor;
  Map<String, dynamic>? selectedSlot;

  final TextEditingController remarksController = TextEditingController();

  List<Map<String, dynamic>> availableSlots = [];
  List<Map<String, dynamic>> availableDoctors = [];

  bool isLoadingDoctors = true;
  bool isLoadingSlots = false;

  int? userId;

  @override
  void initState() {
    super.initState();
    loadUser();
    fetchDoctors();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id') ?? 1; // fallback if not found
    });
  }

  Future<void> fetchDoctors() async {
    try {
      final url = Uri.parse("https://janna-server.onrender.com/api/dropdown/doctors");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          availableDoctors = data
              .map((doc) => doc as Map<String, dynamic>)
              .toList();
          isLoadingDoctors = false;
        });
      } else {
        throw Exception("Failed to fetch doctors");
      }
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
      setState(() => isLoadingDoctors = false);
    }
  }

  Future<void> fetchAvailableTimeSlots() async {
    if (selectedDoctor == null || selectedDate == null) return;

    setState(() {
      isLoadingSlots = true;
      availableSlots = [];
      selectedSlot = null;
    });

    final doctorId = selectedDoctor!['doctor_id'];
    final date = DateFormat('yyyy-MM-dd').format(selectedDate!);
    final url = Uri.parse(
      "https://janna-server.onrender.com/api/doctors/available-times?doctor_id=$doctorId&date=$date",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List slots = data is List ? data : data['slots'] ?? [];

        // final filteredSlots = slots
        //     .where((slot) => slot['status'] == 'available')
        //     .map((slot) => slot as Map<String, dynamic>)
        //     .toList();

        // setState(() {
        //   availableSlots = filteredSlots;
        //   if (availableSlots.isNotEmpty) {
        //     selectedSlot = availableSlots.first; // auto-select first slot
        //   }
        // });
        setState(() {
          availableSlots = slots
              .map((slot) => slot as Map<String, dynamic>)
              .toList();
        });

        print(availableSlots);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No available slots for this date')),
        );
      }
    } catch (e) {
      debugPrint("Error fetching slots: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching available time slots')),
      );
    } finally {
      setState(() => isLoadingSlots = false);
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
      await fetchAvailableTimeSlots();
    }
  }

  void submitAppointment() async {
    //get token from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (selectedDate == null ||
        selectedSlot == null ||
        selectedDoctor == null ||
        remarksController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final appointmentData = {
      "doctor_id": selectedDoctor!['doctor_id'],
      "user_id": userId ?? 1,
      "date": DateFormat('yyyy-MM-dd').format(selectedDate!),
      "availability_id": selectedSlot!['availability_id'],
      "remarks": remarksController.text.trim(),
    };

    try {
      final url = Uri.parse("https://janna-server.onrender.com/api/appointments");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(appointmentData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment Scheduled Successfully!')),
        );
        setState(() {
          selectedDate = null;
          selectedSlot = null;
          selectedDoctor = null;
          remarksController.clear();
          availableSlots = [];
        });
      } else {
        debugPrint('Error: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to schedule appointment')),
        );
      }
    } catch (e) {
      debugPrint('Error submitting appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error connecting to server')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Schedule Appointment',
          style: TextStyle(
            fontFamily: 'Sahitya',
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFFB36CC6),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 📝 Remarks Input
              TextFormField(
                controller: remarksController,
                decoration: const InputDecoration(
                  labelText: 'Consultation Remarks',
                  prefixIcon: Icon(Icons.edit_note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // 👨‍⚕️ Doctor Dropdown
              isLoadingDoctors
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedDoctor,
                      decoration: const InputDecoration(
                        labelText: 'Choose Doctor',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      items: availableDoctors
                          .map(
                            (doc) => DropdownMenuItem(
                              value: doc,
                              child: Text(
                                '${doc['first_name']} ${doc['last_name']}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      style: const TextStyle(color: Colors.black87),
                      onChanged: (value) async {
                        setState(() => selectedDoctor = value);
                        if (selectedDate != null) {
                          await fetchAvailableTimeSlots();
                        }
                      },
                    ),
              const SizedBox(height: 16),

              // 📅 Date Picker
              InkWell(
                onTap: () => pickDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Select Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    selectedDate != null
                        ? DateFormat('MMMM d, y').format(selectedDate!)
                        : 'Choose a date',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ⏰ Time Slot Dropdown
              isLoadingSlots
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedSlot,
                      decoration: const InputDecoration(
                        labelText: 'Select Time Slot',
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                      items: availableSlots.map((slot) {
                        final start = formatTime(slot['start_time']);
                        final end = formatTime(slot['end_time']);
                        return DropdownMenuItem(
                          value: slot,
                          child: Text(
                            '$start - $end',
                            style: const TextStyle(color: Colors.black87),
                          ),
                        );
                      }).toList(),
                      style: const TextStyle(color: Colors.black87),
                      onChanged: (value) =>
                          setState(() => selectedSlot = value),
                    ),

              const SizedBox(height: 24),

              // ✅ Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: submitAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB36CC6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Schedule Appointment',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatTime(String time) {
  try {
    final parsed = DateFormat("HH:mm:ss").parse(time);
    return DateFormat("h:mm a").format(parsed);
  } catch (_) {
    return time;
  }
}
