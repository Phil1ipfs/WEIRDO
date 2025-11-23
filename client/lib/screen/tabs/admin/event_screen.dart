import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/event_service.dart'; // adjust path
import 'sub-pages/notification_page.dart';
import 'sub-pages/upload_event_page.dart';
import 'sub-pages/registered_users_page.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  List<Map<String, dynamic>> events = [];
  String searchKeyword = '';
  String? selectedStatus;
  DateTime? selectedDate;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchEvents();
    updatePastAndFetchEvents();
  }

  Future<void> fetchEvents() async {
    setState(() => isLoading = true);
    try {
      final data = await EventService.getAllEvents();
      setState(() => events = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Error fetching events: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.green;
      case 'completed':
        return Colors.blueGrey;
      case 'cancelled':
        return Colors.red;
      case 'now':
      case 'ongoing':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Calculate event status based on date and time
  String getEventStatus(Map<String, dynamic> event) {
    try {
      final status = event['status']?.toString().toLowerCase() ?? 'upcoming';
      
      // If status is already completed or cancelled, return it
      if (status == 'completed' || status == 'cancelled') {
        return status;
      }

      // Parse event date and time
      final dateStr = event['date']?.toString() ?? '';
      final timeStr = event['time']?.toString() ?? '';
      
      if (dateStr.isEmpty || timeStr.isEmpty) {
        return status;
      }

      // Parse date (format: "Month Day, Year" or "YYYY-MM-DD")
      DateTime? eventDateTime;
      try {
        // Try parsing as "Month Day, Year" format first
        if (dateStr.contains(',')) {
          final parts = dateStr.split(',');
          if (parts.length == 2) {
            final monthDay = parts[0].trim();
            final year = int.tryParse(parts[1].trim()) ?? DateTime.now().year;
            final monthDayParts = monthDay.split(' ');
            if (monthDayParts.length == 2) {
              final monthName = monthDayParts[0];
              final day = int.tryParse(monthDayParts[1]) ?? 1;
              final monthMap = {
                'january': 1, 'february': 2, 'march': 3, 'april': 4,
                'may': 5, 'june': 6, 'july': 7, 'august': 8,
                'september': 9, 'october': 10, 'november': 11, 'december': 12
              };
              final month = monthMap[monthName.toLowerCase()] ?? 1;
              eventDateTime = DateTime(year, month, day);
            }
          }
        } else {
          // Try parsing as ISO format
          eventDateTime = DateTime.parse(dateStr.split(' ')[0]);
        }
      } catch (e) {
        return status;
      }

      if (eventDateTime == null) return status;

      // Parse time (format: "HH:MM AM/PM" or "HH:MM")
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final eventDate = DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day);

      // Parse time string
      int hour = 0, minute = 0;
      try {
        final timeLower = timeStr.toLowerCase();
        if (timeLower.contains('am') || timeLower.contains('pm')) {
          final parts = timeLower.replaceAll(RegExp(r'[ap]m'), '').trim().split(':');
          hour = int.tryParse(parts[0]) ?? 0;
          minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          if (timeLower.contains('pm') && hour != 12) hour += 12;
          if (timeLower.contains('am') && hour == 12) hour = 0;
        } else {
          final parts = timeStr.split(':');
          hour = int.tryParse(parts[0]) ?? 0;
          minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        }
      } catch (e) {
        return status;
      }

      final eventDateTimeFull = DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
        hour,
        minute,
      );

      // Check if event is happening now (within 2 hours before and after)
      final diff = eventDateTimeFull.difference(now).inMinutes;
      
      if (diff >= -120 && diff <= 120) {
        return 'now';
      } else if (eventDate.isBefore(today)) {
        return 'completed';
      } else {
        return 'upcoming';
      }
    } catch (e) {
      return event['status']?.toString().toLowerCase() ?? 'upcoming';
    }
  }

  List<Map<String, dynamic>> get filteredEvents {
    return events.where((event) {
      final title = event['title']?.toString().toLowerCase() ?? '';
      final desc = event['description']?.toString().toLowerCase() ?? '';
      final status = event['status']?.toString().toLowerCase() ?? '';

      DateTime date;
      try {
        date = DateFormat('MMMM d, y').parse(event['date']);
      } catch (_) {
        date = DateTime.now();
      }

      final matchesKeyword =
          searchKeyword.isEmpty ||
          title.contains(searchKeyword.toLowerCase()) ||
          desc.contains(searchKeyword.toLowerCase());

      final matchesStatus =
          selectedStatus == null || status == selectedStatus!.toLowerCase();

      final matchesDate =
          selectedDate == null ||
          (date.year == selectedDate!.year &&
              date.month == selectedDate!.month &&
              date.day == selectedDate!.day);

      return matchesKeyword && matchesStatus && matchesDate;
    }).toList();
  }

  Future<void> updatePastAndFetchEvents() async {
    setState(() => isLoading = true);
    try {
      await EventService.updatePastEvents();

      final data = await EventService.getAllEvents();
      setState(() => events = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Error updating/fetching events: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void showEventSlideUp(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ───────────────────────────────────────────────
                //  Drag handle
                // ───────────────────────────────────────────────
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // ───────────────────────────────────────────────
                //  Image (clickable preview)
                // ───────────────────────────────────────────────
                GestureDetector(
                  onTap: () {
                    if (event['image'] != null &&
                        event['image'].toString().isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FullScreenImageView(imageUrl: event['image']),
                        ),
                      );
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child:
                        event['image'] != null &&
                            event['image'].toString().isNotEmpty
                        ? Image.network(
                            event['image'],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                                  'assets/images/banner.png',
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                          )
                        : Image.asset(
                            'assets/images/banner.png',
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // ───────────────────────────────────────────────
                //  Event details
                // ───────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event['title'] ?? 'Untitled Event',
                        style: const TextStyle(
                          fontFamily: 'Sahitya',
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                          color: Color(0xFFB36CC6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: getStatusColor(
                          getEventStatus(event),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        getEventStatus(event).toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 6),
                    Text(event['date'] ?? ''),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 6),
                    Text(event['time'] ?? 'TBD'),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.place, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(event['location'] ?? '')),
                  ],
                ),

                const SizedBox(height: 12),
                Text(event['description'] ?? ''),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${event['interested'] ?? 0} people interested',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: getStatusColor(
                          getEventStatus(event),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        getEventStatus(event).toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ───────────────────────────────────────────────
                //  View Registered Users (always visible)
                // ───────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.group, color: Colors.white),
                    label: const Text(
                      'View Registered Users',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RegisteredUsersPage(eventId: event['event_id']),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ───────────────────────────────────────────────
                //  Delete Event (only if not completed)
                // ───────────────────────────────────────────────
                if (event['status'] != 'Completed')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text(
                        'Delete Event',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB36CC6),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: const Text(
                              'Are you sure you want to delete this event?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            print('Deleting event: ${event['event_id']}');
                            final success = await EventService.deleteEvent(
                              event['event_id'],
                            );
                            if (success) {
                              Navigator.pop(context); // Close bottom sheet
                              fetchEvents(); // Refresh list
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Event deleted successfully'),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete event: $e'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // void showEventSlideUp(Map<String, dynamic> event) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => DraggableScrollableSheet(
  //       expand: false,
  //       initialChildSize: 0.7,
  //       minChildSize: 0.5,
  //       maxChildSize: 0.95,
  //       builder: (context, scrollController) => Container(
  //         decoration: const BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //         ),
  //         child: SingleChildScrollView(
  //           controller: scrollController,
  //           padding: const EdgeInsets.all(16),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Center(
  //                 child: Container(
  //                   width: 50,
  //                   height: 5,
  //                   margin: const EdgeInsets.only(bottom: 16),
  //                   decoration: BoxDecoration(
  //                     color: Colors.grey[300],
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                 ),
  //               ),

  //               // ✅ CLICKABLE IMAGE PREVIEW
  //               GestureDetector(
  //                 onTap: () {
  //                   if (event['image'] != null &&
  //                       event['image'].toString().isNotEmpty) {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder: (_) =>
  //                             FullScreenImageView(imageUrl: event['image']),
  //                       ),
  //                     );
  //                   }
  //                 },
  //                 child: ClipRRect(
  //                   borderRadius: BorderRadius.circular(6),
  //                   child:
  //                       event['image'] != null &&
  //                           event['image'].toString().isNotEmpty
  //                       ? Image.network(
  //                           event['image'],
  //                           height: 180,
  //                           width: double.infinity,
  //                           fit: BoxFit.cover,
  //                           errorBuilder: (context, error, stackTrace) =>
  //                               Image.asset(
  //                                 'assets/images/banner.png',
  //                                 height: 180,
  //                                 width: double.infinity,
  //                                 fit: BoxFit.cover,
  //                               ),
  //                         )
  //                       : Image.asset(
  //                           'assets/images/banner.png',
  //                           height: 180,
  //                           width: double.infinity,
  //                           fit: BoxFit.cover,
  //                         ),
  //                 ),
  //               ),

  //               const SizedBox(height: 16),
  //               Text(
  //                 event['title'] ?? 'Untitled Event',
  //                 style: const TextStyle(
  //                   fontFamily: 'Sahitya',
  //                   fontWeight: FontWeight.w600,
  //                   fontSize: 22,
  //                   color: Color(0xFFB36CC6),
  //                 ),
  //               ),
  //               const SizedBox(height: 10),
  //               Row(
  //                 children: [
  //                   const Icon(Icons.calendar_today, size: 16),
  //                   const SizedBox(width: 6),
  //                   Text(event['date'] ?? ''),
  //                   const SizedBox(width: 16),
  //                   const Icon(Icons.access_time, size: 16),
  //                   const SizedBox(width: 6),
  //                   Text(event['time'] ?? 'TBD'),
  //                 ],
  //               ),
  //               const SizedBox(height: 8),
  //               Row(
  //                 children: [
  //                   const Icon(Icons.place, size: 16),
  //                   const SizedBox(width: 6),
  //                   Expanded(child: Text(event['location'] ?? '')),
  //                 ],
  //               ),
  //               const SizedBox(height: 12),
  //               Text(event['description'] ?? ''),
  //               const SizedBox(height: 12),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Text(
  //                     '${event['interested'] ?? 0} people interested',
  //                     style: const TextStyle(fontWeight: FontWeight.w500),
  //                   ),
  //                   Container(
  //                     padding: const EdgeInsets.symmetric(
  //                       horizontal: 12,
  //                       vertical: 6,
  //                     ),
  //                     decoration: BoxDecoration(
  //                       color: getStatusColor(
  //                         event['status'] ?? '',
  //                       ).withOpacity(0.1),
  //                       border: Border.all(
  //                         color: getStatusColor(event['status'] ?? ''),
  //                       ),
  //                       borderRadius: BorderRadius.circular(4),
  //                     ),
  //                     child: Text(
  //                       event['status'] ?? '',
  //                       style: TextStyle(
  //                         fontWeight: FontWeight.w600,
  //                         color: getStatusColor(event['status'] ?? ''),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 16),

  //               if (event['status'] != 'Completed') ...[
  //                 SizedBox(
  //                   width: double.infinity,
  //                   child: ElevatedButton.icon(
  //                     icon: const Icon(Icons.group),
  //                     label: const Text('View Registered Users'),
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.deepPurple,
  //                     ),
  //                     onPressed: () {
  //                       Navigator.push(
  //                         context,
  //                         MaterialPageRoute(
  //                           builder: (_) =>
  //                               RegisteredUsersPage(eventId: event['event_id']),
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                 ),
  //                 const SizedBox(height: 12),
  //                 SizedBox(
  //                   width: double.infinity,
  //                   child: ElevatedButton.icon(
  //                     icon: const Icon(Icons.delete),
  //                     label: const Text('Delete Event'),
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: const Color(0xFFB36CC6),
  //                     ),
  //                     onPressed: () async {
  //                       // existing delete logic...
  //                     },
  //                   ),
  //                 ),
  //                 const SizedBox(height: 16),
  //               ],

  //               // ✅ Show delete button only if event is NOT completed
  //               // if (event['status'] != 'Completed') ...[
  //               //   SizedBox(
  //               //     width: double.infinity,
  //               //     child: ElevatedButton.icon(
  //               //       icon: const Icon(Icons.delete),
  //               //       label: const Text('Delete Event'),
  //               //       style: ElevatedButton.styleFrom(
  //               //         backgroundColor: const Color(0xFFB36CC6),
  //               //       ),
  //               //       onPressed: () async {
  //               //         final confirm = await showDialog<bool>(
  //               //           context: context,
  //               //           builder: (ctx) => AlertDialog(
  //               //             title: const Text('Confirm Delete'),
  //               //             content: const Text(
  //               //               'Are you sure you want to delete this event?',
  //               //             ),
  //               //             actions: [
  //               //               TextButton(
  //               //                 onPressed: () => Navigator.pop(ctx, false),
  //               //                 child: const Text('Cancel'),
  //               //               ),
  //               //               TextButton(
  //               //                 onPressed: () => Navigator.pop(ctx, true),
  //               //                 child: const Text('Delete'),
  //               //               ),
  //               //             ],
  //               //           ),
  //               //         );

  //               //         if (confirm == true) {
  //               //           try {
  //               //             print('Deleting event: ${event['event_id']}');
  //               //             final success = await EventService.deleteEvent(
  //               //               event['event_id'],
  //               //             );
  //               //             if (success) {
  //               //               Navigator.pop(context); // Close bottom sheet
  //               //               fetchEvents(); // Refresh event list
  //               //               ScaffoldMessenger.of(context).showSnackBar(
  //               //                 const SnackBar(
  //               //                   content: Text('Event deleted successfully'),
  //               //                 ),
  //               //               );
  //               //             }
  //               //           } catch (e) {
  //               //             ScaffoldMessenger.of(context).showSnackBar(
  //               //               SnackBar(
  //               //                 content: Text('Failed to delete event: $e'),
  //               //               ),
  //               //             );
  //               //           }
  //               //         }
  //               //       },
  //               //     ),
  //               //   ),
  //               //   const SizedBox(height: 16),
  //               // ],
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Events",
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

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search by keyword...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) =>
                              setState(() => searchKeyword = value),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              selectedDate = null;
                              selectedStatus = null;
                              searchKeyword = '';
                            });
                            await updatePastAndFetchEvents(); // ✅ refresh on button press
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB36CC6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Icon(Icons.refresh, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => pickDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Filter by date',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              selectedDate != null
                                  ? DateFormat(
                                      'MMMM d, y',
                                    ).format(selectedDate!)
                                  : 'Select date',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus,
                          hint: const Text("Filter by status"),
                          items: ['All', 'Upcoming', 'Completed', 'Cancelled']
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(
                                    status,
                                    style: const TextStyle(color: Colors.black87),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(
                            () =>
                                selectedStatus = value == 'All' ? null : value,
                          ),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.filter_alt),
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ✅ Added RefreshIndicator
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh:
                          updatePastAndFetchEvents, // pull down to refresh
                      child: filteredEvents.isEmpty
                          ? const Center(
                              child: Text('No events match your filters.'),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filteredEvents.length,
                              itemBuilder: (context, index) {
                                final event = filteredEvents[index];
                                return GestureDetector(
                                  onTap: () => showEventSlideUp(event),
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(6),
                                              ),
                                          child:
                                              event['image'] != null &&
                                                  event['image']
                                                      .toString()
                                                      .isNotEmpty
                                              ? Image.network(
                                                  event['image'],
                                                  height: 180,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Image.asset(
                                                        'assets/images/banner.png',
                                                        height: 180,
                                                        fit: BoxFit.cover,
                                                      ),
                                                )
                                              : Image.asset(
                                                  'assets/images/banner.png',
                                                  height: 180,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      event['title'] ??
                                                          'Untitled Event',
                                                      style: const TextStyle(
                                                        fontFamily: 'Sahitya',
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 20,
                                                        color: Color(0xFFB36CC6),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: getStatusColor(
                                                        getEventStatus(event),
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(
                                                      getEventStatus(event)
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.calendar_today,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(event['date'] ?? ''),
                                                  const SizedBox(width: 16),
                                                  const Icon(
                                                    Icons.access_time,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(event['time'] ?? 'TBD'),
                                                ],
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
                  ),
                ],
              ),
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UploadEventPage()),
          );
        },
        backgroundColor: const Color(0xFFB36CC6),
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                Image.asset('assets/images/banner.png', fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
