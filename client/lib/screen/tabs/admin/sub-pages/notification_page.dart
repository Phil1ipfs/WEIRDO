import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool isLoading = true;
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      // 🔑 Get token from local storage
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // 🌐 API call to backend using Bearer token in Authorization header
      final response = await http.get(
        Uri.parse("https://janna-server.onrender.com/api/notifications"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // ✅ Add Bearer token
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notifications = data["notifications"] ?? [];
          isLoading = false;
        });
      } else {
        print("Error: ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Fetch error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontFamily: 'Sahitya',
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFFB36CC6),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(child: Text("No new notifications yet!"))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(notif["title"] ?? "No title"),
                  subtitle: Text(notif["message"] ?? ""),
                  trailing: notif["is_read"] == true
                      ? const Icon(Icons.done_all, color: Colors.green)
                      : const Icon(Icons.mark_email_unread, color: Colors.grey),
                );
              },
            ),
    );
  }
}
