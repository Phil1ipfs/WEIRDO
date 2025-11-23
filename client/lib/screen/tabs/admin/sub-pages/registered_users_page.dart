import 'package:flutter/material.dart';
import '../../../../services/event_service.dart';

class RegisteredUsersPage extends StatefulWidget {
  final int eventId;

  const RegisteredUsersPage({super.key, required this.eventId});

  @override
  State<RegisteredUsersPage> createState() => _RegisteredUsersPageState();
}

class _RegisteredUsersPageState extends State<RegisteredUsersPage> {
  Map<String, dynamic>? eventData;
  List<dynamic> users = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchRegisteredUsers();
  }

  Future<void> fetchRegisteredUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await EventService.getRegisteredUsers(widget.eventId);
      setState(() {
        eventData = response['event'];
        users = response['users'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          eventData?['title'] ?? 'Registered Users',
          style: const TextStyle(
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
          : errorMessage != null
          ? Center(child: Text('Error: $errorMessage'))
          : users.isEmpty
          ? const Center(child: Text('No registered users found.'))
          : RefreshIndicator(
              onRefresh: fetchRegisteredUsers,
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final profileList = user['profile'];
                  final profile =
                      (profileList is List && profileList.isNotEmpty)
                      ? profileList.first
                      : {};
                  final fullName =
                      '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'
                          .trim();

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            user['profile_picture'] != null &&
                                user['profile_picture'].toString().isNotEmpty
                            ? NetworkImage(user['profile_picture'])
                            : const AssetImage(
                                    'assets/images/default_profile.png',
                                  )
                                  as ImageProvider,
                      ),
                      title: Text(
                        fullName.isEmpty ? 'Unnamed User' : fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB36CC6),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['email'] ?? ''),
                          Text(
                            'Role: ${user['role']?.toString().toUpperCase() ?? ''}',
                          ),
                          if (profile['contact_number'] != null)
                            Text('📞 ${profile['contact_number']}'),
                          if (profile['gender'] != null)
                            Text('Gender: ${profile['gender']}'),
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
