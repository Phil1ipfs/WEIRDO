import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:async'; // 👈 required for Timer

class ChatViewScreen extends StatefulWidget {
  final int currentUserId; // Logged-in user
  final int userId; // Chat partner
  final String name;
  final String status;
  final int? appointmentId; // Appointment ID for this conversation

  const ChatViewScreen({
    super.key,
    required this.currentUserId,
    required this.userId,
    required this.name,
    required this.status,
    this.appointmentId,
  });

  @override
  State<ChatViewScreen> createState() => _ChatViewScreenState();
}

class _ChatViewScreenState extends State<ChatViewScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Replace with your server address (use IP if on emulator/device)
  static const String baseUrl = "https://janna-server.onrender.com/api";

  final List<Map<String, dynamic>> _messages = [];
  bool _showProfile = false;
  bool _isOnline = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadMessages();

    // 🔁 Auto-refresh every 1 second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 👈 stop timer when leaving screen
    super.dispose();
  }

  /// Fetch conversation from backend
  Future<void> _loadMessages() async {
    print(widget.status);
    String urlString = "$baseUrl/messages/${widget.currentUserId}/${widget.userId}";
    // Add appointment_id to query params if provided
    if (widget.appointmentId != null) {
      urlString += "?appointment_id=${widget.appointmentId}";
    }
    final url = Uri.parse(urlString);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        _messages.clear();
        _messages.addAll(
          data.map((msg) {
            final isMe = msg['sender_id'] == widget.currentUserId;
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
      print("Error loading messages: ${response.body}");
    }
  }

  Future<void> _sendMessage() async {
    if (widget.status.toLowerCase() != "ongoing") {
      // Optionally show a toast/snackbar
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Chat is not active.")));
      return;
    }

    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      final url = Uri.parse("$baseUrl/messages/client");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "sender_id": widget.currentUserId,
          "receiver_id": widget.userId,
          "type": "text",
          "content": text,
          "appointment_id": widget.appointmentId,
        }),
      );

      if (response.statusCode == 200) {
        _messageController.clear();
        // Reload messages to get the latest from backend
        await Future.delayed(const Duration(milliseconds: 300));
        _loadMessages();
      } else {
        print("Error sending message: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: ${response.body}')),
        );
      }
    }
  }

  Future<void> _sendImage() async {
    if (widget.status.toLowerCase() != "ongoing") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Chat is not active.")));
      return;
    }

    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final url = Uri.parse("$baseUrl/messages");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "sender_id": widget.currentUserId,
          "receiver_id": widget.userId,
          "type": "image",
          "content": file.path,
          "appointment_id": widget.appointmentId,
        }),
      );

      if (response.statusCode == 200) {
        // Reload messages to get the latest from backend
        await Future.delayed(const Duration(milliseconds: 300));
        _loadMessages();
      } else {
        print("Error sending image: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: ${response.body}')),
        );
      }
    }
  }

  /// Mark message as read
  Future<void> _markAsRead(int messageId) async {
    final url = Uri.parse("$baseUrl/messages/$messageId/read");
    final response = await http.patch(url);
    if (response.statusCode == 200) {
      print("Message $messageId marked as read");
    } else {
      print("Error marking read: ${response.body}");
    }
  }

  /// Show fullscreen image
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
              widget.name,
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
        actions: [
          IconButton(
            icon: Icon(_showProfile ? Icons.expand_less : Icons.expand_more),
            onPressed: () => setState(() => _showProfile = !_showProfile),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showProfile)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://images.pexels.com/photos/32493668/pexels-photo-32493668.jpeg',
                    ),
                    radius: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Cardiologist • ${_isOnline ? 'Online' : 'Offline'}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                  if (content is String && content.startsWith("http")) {
                    imageProvider = NetworkImage(content);
                  } else if (content is String) {
                    imageProvider = FileImage(File(content));
                  }
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
                    onPressed: widget.status.toLowerCase() == "ongoing" ? _sendImage : null,
                    icon: const Icon(Icons.image),
                    color: const Color(0xFFB36CC6),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: widget.status.toLowerCase() == "ongoing", // 👈 disables typing
                      decoration: InputDecoration(
                        hintText: widget.status.toLowerCase() == "ongoing"
                            ? 'Type a message...'
                            : 'Chat is not active',
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
                    onPressed: widget.status.toLowerCase() == "ongoing" ? _sendMessage : null,
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
