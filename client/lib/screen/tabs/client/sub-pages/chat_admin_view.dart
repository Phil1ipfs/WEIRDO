import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class ChatAdminView extends StatefulWidget {
  const ChatAdminView({super.key});

  @override
  State<ChatAdminView> createState() => _ChatAdminViewState();
}

class _ChatAdminViewState extends State<ChatAdminView> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  static const String baseUrl = "https://janna-server.onrender.com/api";

  final List<Map<String, dynamic>> _messages = [];
  bool _isOnline = true;
  String _adminName = "Admin";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadAdminProfile(); // 🧠 Load admin name first
    _loadMessages();

    // 🔁 Refresh messages every 2 seconds
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 🧠 Fetch admin profile
  Future<void> _loadAdminProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) return;

      final url = Uri.parse("$baseUrl/admins/profile");
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final admin = data["admin"];
        setState(() {
          _adminName = "${admin["first_name"]} ${admin["last_name"]} (Admin)"
              .trim(); // ✅ Combine first + last name
        });
      } else {
        print("Error fetching admin profile: ${response.body}");
      }
    } catch (e) {
      print("Exception fetching admin profile: $e");
    }
  }

  /// 📨 Fetch chat messages between user and admin
  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) return;

    final url = Uri.parse("$baseUrl/messages/client-admin-convo");
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token", "No-Cache": "true"},
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        _messages
          ..clear()
          ..addAll(
            data.map((msg) {
              // Check if message is from current user (client) by comparing sender_role
              final isMe = msg['sender_role'] == 'client' || msg['sender_role'] == 'Client';
              return {
                'id': msg['message_id'],
                'sender': isMe ? 'me' : 'other',
                'type': msg['type'],
                'content': msg['content'],
                'time': DateTime.parse(
                  msg['createdAt'],
                ).toLocal().toString().substring(11, 16),
                'delivered': msg['read'] ?? false,
              };
            }),
          );
      });
    } else {
      print("Error loading admin messages: ${response.body}");
    }
  }

  /// ✉️ Send text message to admin
  Future<void> _sendMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final text = _messageController.text.trim();

    if (text.isEmpty || token == null) return;

    final url = Uri.parse("$baseUrl/messages/admin");
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode({"type": "text", "content": text}),
    );

    if (response.statusCode == 200) {
      final msg = json.decode(response.body)['message'];
      setState(() {
        _messages.add({
          'id': msg['message_id'],
          'sender': 'me',
          'type': msg['type'],
          'content': msg['content'],
          'time': DateTime.parse(
            msg['createdAt'],
          ).toLocal().toString().substring(11, 16),
          'delivered': msg['read'] ?? false,
        });
        _messageController.clear();
      });
    } else {
      print("Error sending message: ${response.body}");
    }
  }

  /// 🖼️ Send image to admin
  Future<void> _sendImage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return;

    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final url = Uri.parse("$baseUrl/messages/admin");
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode({"type": "image", "content": file.path}),
    );

    if (response.statusCode == 200) {
      final msg = json.decode(response.body)['message'];
      setState(() {
        _messages.add({
          'id': msg['message_id'],
          'sender': 'me',
          'type': msg['type'],
          'content': msg['content'],
          'time': DateTime.parse(
            msg['createdAt'],
          ).toLocal().toString().substring(11, 16),
          'delivered': msg['read'] ?? false,
        });
      });
    } else {
      print("Error sending image: ${response.body}");
    }
  }

  void _showFullScreen(ImageProvider imageProvider) {
    showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: InteractiveViewer(child: Image(image: imageProvider)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB36CC6),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Text(
              _adminName,
              style: const TextStyle(
                fontFamily: 'Sahitya',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isOnline ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['sender'] == 'me';
                final type = msg['type'];
                final content = msg['content'];
                final time = msg['time'] as String;
                final delivered = msg['delivered'] as bool;

                Widget bubbleChild;
                ImageProvider? imageProvider;

                if (type == 'text') {
                  bubbleChild = Text(
                    content,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                  );
                } else {
                  imageProvider = content.startsWith("http")
                      ? NetworkImage(content)
                      : FileImage(File(content));
                  bubbleChild = GestureDetector(
                    onTap: () => _showFullScreen(imageProvider!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image(image: imageProvider!),
                    ),
                  );
                }

                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFFB36CC6)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isMe
                            ? const Radius.circular(12)
                            : Radius.zero,
                        bottomRight: isMe
                            ? Radius.zero
                            : const Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: type == 'text'
                              ? const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 14,
                                )
                              : const EdgeInsets.all(4),
                          child: bubbleChild,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                time,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: isMe ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  delivered ? Icons.done_all : Icons.check,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                              ],
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
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: _sendImage,
                    icon: const Icon(Icons.image),
                    color: const Color(0xFFB36CC6),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Message admin...',
                        hintStyle: const TextStyle(fontFamily: 'Poppins'),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    color: const Color(0xFFB36CC6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
