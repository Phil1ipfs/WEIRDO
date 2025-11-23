import 'package:flutter/material.dart';

class AllAppointmentsPage extends StatefulWidget {
  final List<Map<String, dynamic>> appointments;

  const AllAppointmentsPage({super.key, required this.appointments});

  @override
  State<AllAppointmentsPage> createState() => _AllAppointmentsPageState();
}

class _AllAppointmentsPageState extends State<AllAppointmentsPage> {
  String _selectedStatus = 'All';
  DateTime? _selectedDate;

  final List<String> statuses = [
    'All',
    'Pending',
    'Ongoing',
    'Done',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredAppointments = widget.appointments.where((appointment) {
      final matchesStatus =
          _selectedStatus == 'All' ||
          appointment['status'].toLowerCase() == _selectedStatus.toLowerCase();
      final matchesDate =
          _selectedDate == null ||
          (appointment['date'].year == _selectedDate!.year &&
              appointment['date'].month == _selectedDate!.month &&
              appointment['date'].day == _selectedDate!.day);
      return matchesStatus && matchesDate;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Appointments',
          style: TextStyle(
            fontFamily: 'Sahitya',
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFFB36CC6),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 🔍 Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'Filter by Status',
                      labelStyle: const TextStyle(fontFamily: 'Poppins'),
                    ),
                    items: statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(
                          status,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                    style: const TextStyle(color: Colors.black87),
                    onChanged: (value) {
                      setState(() => _selectedStatus = value ?? 'All');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _selectedDate = pickedDate;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  color: const Color(0xFFB36CC6),
                ),
                IconButton(
                  tooltip: "Clear filters",
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'All';
                      _selectedDate = null;
                    });
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
          ),

          // 🔎 Show Selected Filters
          if (_selectedStatus != 'All' || _selectedDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (_selectedStatus != 'All')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.label,
                            size: 14,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedStatus,
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
                    ),
                  if (_selectedDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event,
                            size: 14,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // 📋 Appointments List
          Expanded(
            child: filteredAppointments.isEmpty
                ? const Center(
                    child: Text(
                      'No appointments found.',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredAppointments.length,
                    itemBuilder: (context, index) {
                      final item = filteredAppointments[index];
                      final date = item['date'] as DateTime;
                      final doctor = item['doctor'];
                      final patient = item['patient'];
                      final status = item['status'];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Dr. $doctor ➜ $patient',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${date.month}/${date.day}/${date.year} at ${_formatTime(date)}',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusBadge(status),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$formattedHour:$minute $suffix';
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'done':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      case 'ongoing':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
