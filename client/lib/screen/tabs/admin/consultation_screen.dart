import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'sub-pages/chat_view_screen.dart';
import 'sub-pages/notification_page.dart';

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  State<ConsultationScreen> createState() => ConsultationScreenState();
}

class ConsultationScreenState extends State<ConsultationScreen> {
  String _searchQuery = '';
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;
  int? _adminUserId; // Store admin's user_id

  static const String baseUrl = "https://janna-server.onrender.com/api"; // Backend URL

  @override
  void initState() {
    super.initState();
    _fetchAdminUserId();
  }

  /// Fetch admin's user_id from profile
  Future<void> _fetchAdminUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        setState(() => _loading = false);
        return;
      }

      // Fetch admin profile to get user_id
      final adminProfileUrl = Uri.parse("$baseUrl/admins/profile");
      final adminProfileResponse = await http.get(
        adminProfileUrl,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (adminProfileResponse.statusCode == 200) {
        final adminData = json.decode(adminProfileResponse.body);
        // Admin profile response structure: { admin: { user_id, ... }, email, ... }
        setState(() {
          _adminUserId = adminData['admin']?['user_id'];
          if (_adminUserId == null) {
            // Try alternative structure
            _adminUserId = adminData['user_id'];
          }
        });
      }
      
      // Fetch conversations after getting admin user_id
      _fetchConversations();
    } catch (e) {
      print("Error fetching admin user_id: $e");
      // Still try to fetch conversations
      _fetchConversations();
    }
  }

  /// Fetch conversations using token from SharedPreferences
  Future<void> _fetchConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Get token from local storage

    if (token == null) {
      print('Token not found in local storage');
      setState(() => _loading = false);
      return;
    }

    try {
      final url = Uri.parse("$baseUrl/messages/admin");
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _conversations = data.map<Map<String, dynamic>>((user) {
            return {
              'conversation_user_id': user['conversation_user_id'],
              'sender_id': user['sender_id'],
              'receiver_id': user['receiver_id'],
              'name': user['email'] ?? 'User',
              'message': user['last_message'] ?? '',
              'time': user['last_time'] != null
                  ? DateTime.parse(
                      user['last_time'],
                    ).toLocal().toString().substring(11, 16)
                  : '',
              'imageUrl':
                  user['profile_picture'] ??
                  'https://picsum.photos/seed/${user['conversation_user_id']}/100',
              'read': false,
              'delivered': true,
            };
          }).toList();
          _loading = false;
        });
      } else {
        print("Error fetching conversations: ${response.body}");
        setState(() => _loading = false);
      }
    } catch (e) {
      print("Error fetching conversations: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredConversations = _conversations.where((conv) {
      return conv['name'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔍 Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search chats...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      hintStyle: const TextStyle(fontFamily: 'Poppins'),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredConversations.length,
                    itemBuilder: (context, index) {
                      final convo = filteredConversations[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            final otherUserId = convo['conversation_user_id'];
                            
                            if (otherUserId != null && _adminUserId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatViewScreen(
                                    currentUserId: _adminUserId!,
                                    userId: otherUserId,
                                    name: convo['name'] ?? 'User',
                                  ),
                                ),
                              );
                            } else {
                              print(
                                'Navigation failed: userId=${otherUserId}, adminUserId=${_adminUserId}',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Unable to open chat. Please try again.'),
                                ),
                              );
                            }
                          },
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  convo['imageUrl'],
                                ),
                                radius: 26,
                              ),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    convo['name'],
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    convo['time'],
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      convo['message'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    (convo['delivered'] ?? true)
                                        ? Icons.check_circle_outline
                                        : Icons.access_time,
                                    size: 16,
                                    color: (convo['delivered'] ?? true)
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ],
                              ),
                              trailing: (convo['read'] ?? false)
                                  ? const SizedBox()
                                  : Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: const Color(0xFFB36CC6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Text(
                                        '1',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
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
}
