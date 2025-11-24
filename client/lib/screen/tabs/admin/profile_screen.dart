// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'sub-pages/edit_admin_profile.dart';
// import 'sub-pages/change_password_screen.dart';
// import 'package:flutter/foundation.dart'; // 👈 Add this import (for kIsWeb)
// import 'package:http_parser/http_parser.dart'; // ✅ Add this line
// import 'sub-pages/notification_page.dart';

// /// Profile model
// class Profile {
//   final String name;
//   final String role;
//   final String email;
//   final String phone;
//   final String imageUrl;

//   Profile({
//     required this.name,
//     required this.role,
//     required this.email,
//     required this.phone,
//     required this.imageUrl,
//   });

//   factory Profile.fromJson(Map<String, dynamic> json) {
//     final profileData = json['profile'] ?? {};
//     return Profile(
//       name: profileData['first_name'] != null
//           ? '${profileData['first_name']} ${profileData['middle_name'] ?? ''} ${profileData['last_name'] ?? ''}'
//           : 'No Name',
//       role: json['role'] ?? 'Unknown',
//       email: json['email'] ?? 'No Email',
//       phone: profileData['contact_number'] ?? 'No Phone',
//       imageUrl: json['profile_picture'],
//     );
//   }
// }

// /// Profile Screen
// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   Profile? _profile;
//   Map<String, dynamic>? _rawProfileData;
//   bool _isLoading = true;

//   final String apiUrl = 'https://janna-server.onrender.com/api/auth/profile';

//   @override
//   void initState() {
//     super.initState();
//     _loadProfile();
//   }

//   /// Load profile with token
//   Future<void> _loadProfile() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token') ?? '';

//     if (token.isEmpty) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Token not found. Please login again.')),
//       );
//       return;
//     }

//     await _fetchProfile(token);
//   }

//   /// Fetch profile from backend
//   Future<void> _fetchProfile(String token) async {
//     try {
//       final response = await http.get(
//         Uri.parse(apiUrl),
//         headers: {'Authorization': 'Bearer $token'},
//       );

//       if (response.statusCode == 201 || response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           _rawProfileData = data;
//           _profile = Profile.fromJson(data);
//           _isLoading = false;
//         });
//       } else {
//         throw Exception('Failed to load profile');
//       }
//     } catch (e) {
//       debugPrint('Error fetching profile: $e');
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Failed to load profile.')));
//     }
//   }

//   /// Navigate to Edit Profile
//   Future<void> _navigateToEditProfile() async {
//     if (_rawProfileData == null) return;

//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => EditAdminProfile(
//           adminData: {
//             "email": _rawProfileData!['email'],
//             "profile": _rawProfileData!['profile'] ?? {},
//           },
//         ),
//       ),
//     );

//     if (result == true) {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? '';
//       if (token.isNotEmpty) await _fetchProfile(token);
//     }
//   }

//   /// Show image options
//   void _showProfileOptions() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (context) {
//         return SafeArea(
//           child: Wrap(
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.visibility, color: Colors.blue),
//                 title: const Text(
//                   'View Profile Picture',
//                   style: TextStyle(fontFamily: 'Poppins'),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _viewProfilePicture();
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.camera_alt, color: Colors.green),
//                 title: const Text(
//                   'Change Profile Photo',
//                   style: TextStyle(fontFamily: 'Poppins'),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _changeProfilePhoto();
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   /// View full-size picture
//   void _viewProfilePicture() {
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         backgroundColor: Colors.transparent,
//         child: InteractiveViewer(
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(12),
//             child: Image.network(_profile!.imageUrl, fit: BoxFit.contain),
//           ),
//         ),
//       ),
//     );
//   }

//   /// Pick, preview, and upload new profile photo (mobile + web)
//   Future<void> _changeProfilePhoto() async {
//     try {
//       Uint8List? imageBytes;
//       String? fileName;

//       if (kIsWeb) {
//         // 🖼️ For Web: use FilePicker to ensure Chrome compatibility
//         final result = await ImagePicker().pickImage(
//           source: ImageSource.gallery,
//           imageQuality: 85,
//         );
//         if (result == null) return;
//         imageBytes = await result.readAsBytes();
//         fileName = result.name;
//       } else {
//         // 📱 For Mobile
//         final result = await ImagePicker().pickImage(
//           source: ImageSource.gallery,
//           imageQuality: 85,
//         );
//         if (result == null) return;
//         imageBytes = await result.readAsBytes();
//         fileName = result.name;
//       }

//       // 🖼️ Show preview dialog before uploading
//       final bool? confirm = await showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             title: const Text(
//               'Preview Profile Picture',
//               style: TextStyle(
//                 fontFamily: 'Poppins',
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(100),
//                   child: Image.memory(
//                     imageBytes!,
//                     width: 150,
//                     height: 150,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 const Text(
//                   'Do you want to save this as your new profile picture?',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontFamily: 'Poppins'),
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: const Text(
//                   'Cancel',
//                   style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
//                 ),
//               ),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFB36CC6),
//                 ),
//                 onPressed: () => Navigator.pop(context, true),
//                 child: const Text(
//                   'Save',
//                   style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
//                 ),
//               ),
//             ],
//           );
//         },
//       );

//       // 🚫 Cancel if user didn’t confirm
//       if (confirm != true) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Uploading new profile photo...')),
//       );

//       // 🔐 Upload with token
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? '';
//       if (token.isEmpty) throw Exception('Token not found');

//       final uri = Uri.parse(
//         'https://janna-server.onrender.com/api/auth/change-profile-picture',
//       );
//       final request = http.MultipartRequest('PUT', uri)
//         ..headers['Authorization'] = 'Bearer $token';

//       // 🧩 Attach image (works for both mobile and web)
//       request.files.add(
//         http.MultipartFile.fromBytes(
//           'image',
//           imageBytes,
//           filename: fileName,
//           contentType: MediaType('image', 'jpeg'),
//         ),
//       );

//       final response = await request.send();

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Profile photo updated successfully!')),
//         );
//         await _fetchProfile(token); // ✅ Refresh profile info
//       } else {
//         throw Exception('Upload failed (${response.statusCode})');
//       }
//     } catch (e) {
//       debugPrint('Error uploading profile photo: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Failed to upload photo: $e')));
//     }
//   }

//   /// Logout confirmation
//   void _confirmLogout() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         title: const Text(
//           "Logout Confirmation",
//           style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
//         ),
//         content: const Text(
//           "Are you sure you want to logout?",
//           style: TextStyle(fontFamily: 'Poppins'),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text(
//               "Cancel",
//               style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
//             ),
//           ),
//           TextButton(
//             onPressed: () async {
//               SharedPreferences prefs = await SharedPreferences.getInstance();
//               await prefs.remove('token');
//               Navigator.of(context).pop();
//               Navigator.pushNamedAndRemoveUntil(
//                 context,
//                 '/login',
//                 (route) => false,
//               );
//             },
//             child: const Text(
//               "Logout",
//               style: TextStyle(
//                 fontFamily: 'Poppins',
//                 color: Color(0xFFB36CC6),
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Profile',
//           style: TextStyle(
//             fontFamily: 'Sahitya', // ✅ Custom font
//             fontWeight: FontWeight.w700, // ✅ Bold weight
//             fontSize: 22, // optional, looks better for title
//           ),
//         ),
//         elevation: 0,
//         backgroundColor: const Color(
//           0xFFB36CC6,
//         ), // ✅ same as your footer tabs color
//         foregroundColor: Colors.white, // for title and icons
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications_none),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const NotificationPage(),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),

//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _profile == null
//           ? const Center(child: Text('Profile not found'))
//           : ListView(
//               padding: const EdgeInsets.all(16),
//               children: [
//                 // 📸 Profile Card
//                 Card(
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   elevation: 3,
//                   child: Padding(
//                     padding: const EdgeInsets.all(20),
//                     child: Column(
//                       children: [
//                         GestureDetector(
//                           onTap: _showProfileOptions,
//                           child: CircleAvatar(
//                             radius: 50,
//                             backgroundImage: NetworkImage(_profile!.imageUrl),
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           _profile!.name,
//                           style: const TextStyle(
//                             fontSize: 20,
//                             fontFamily: 'Poppins',
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         Text(
//                           _profile!.role,
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontFamily: 'Poppins',
//                             color: Colors.grey,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 24),

//                 // 📱 Contact Info
//                 Card(
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   elevation: 2,
//                   child: Column(
//                     children: [
//                       ListTile(
//                         leading: const Icon(Icons.email, color: Colors.red),
//                         title: const Text(
//                           'Email',
//                           style: TextStyle(fontFamily: 'Poppins'),
//                         ),
//                         subtitle: Text(
//                           _profile!.email,
//                           style: const TextStyle(fontFamily: 'Poppins'),
//                         ),
//                       ),
//                       const Divider(height: 0),
//                       ListTile(
//                         leading: const Icon(Icons.phone, color: Colors.red),
//                         title: const Text(
//                           'Phone',
//                           style: TextStyle(fontFamily: 'Poppins'),
//                         ),
//                         subtitle: Text(
//                           _profile!.phone,
//                           style: const TextStyle(fontFamily: 'Poppins'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 24),

//                 // ⚙️ Account Actions
//                 Card(
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   elevation: 2,
//                   child: Column(
//                     children: [
//                       ListTile(
//                         leading: const Icon(Icons.edit, color: Colors.blue),
//                         title: const Text(
//                           'Edit Profile',
//                           style: TextStyle(fontFamily: 'Poppins'),
//                         ),
//                         onTap: _navigateToEditProfile,
//                       ),
//                       const Divider(height: 0),
//                       ListTile(
//                         leading: const Icon(Icons.lock, color: Colors.orange),
//                         title: const Text(
//                           'Change Password',
//                           style: TextStyle(fontFamily: 'Poppins'),
//                         ),
//                         onTap: () async {
//                           final bool? result = await Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) =>
//                                   const ChangePasswordScreen(),
//                             ),
//                           );

//                           if (result == true) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text("Password changed successfully!"),
//                                 behavior: SnackBarBehavior.floating,
//                               ),
//                             );
//                           }
//                         },
//                       ),
//                       const Divider(height: 0),
//                       ListTile(
//                         leading: const Icon(Icons.logout, color: Colors.red),
//                         title: const Text(
//                           'Logout',
//                           style: TextStyle(fontFamily: 'Poppins'),
//                         ),
//                         onTap: _confirmLogout,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sub-pages/edit_admin_profile.dart';
import 'sub-pages/change_password_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'sub-pages/notification_page.dart';

class Profile {
  final String name;
  final String role;
  final String email;
  final String phone;
  final String gender;
  final String imageUrl;

  Profile({
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    required this.gender,
    required this.imageUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final profileData = json['profile'] ?? {};

    // Helper to build profile picture URL
    String buildProfilePictureUrl(String? url) {
      if (url == null || url.isEmpty) return "https://picsum.photos/200";
      if (url.startsWith('/uploads/')) {
        return 'https://janna-server.onrender.com$url';
      }
      return url;
    }

    return Profile(
      name: profileData['first_name'] != null
          ? '${profileData['first_name']} ${profileData['middle_name'] ?? ''} ${profileData['last_name'] ?? ''}'
          : 'No Name',
      role: json['role'] ?? 'Unknown',
      email: json['email'] ?? 'No Email',
      phone: profileData['contact_number'] ?? 'No Phone',
      gender: profileData['gender'] ?? 'Not Specified',
      imageUrl: buildProfilePictureUrl(json['profile_picture']),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;
  Map<String, dynamic>? _rawProfileData;
  bool _isLoading = true;
  final String apiUrl = 'https://janna-server.onrender.com/api/auth/profile';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Helper function to build full profile picture URL
  String _buildProfilePictureUrl(String? profilePicture) {
    if (profilePicture == null || profilePicture.isEmpty) {
      return "https://picsum.photos/200";
    }
    // If it starts with /uploads/, prepend the server URL
    if (profilePicture.startsWith('/uploads/')) {
      return 'https://janna-server.onrender.com$profilePicture';
    }
    // Otherwise return as is (for full URLs)
    return profilePicture;
  }

  Future<void> _loadProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token not found. Please login again.')),
      );
      return;
    }
    await _fetchProfile(token);
  }

  Future<void> _fetchProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _rawProfileData = data;
          _profile = Profile.fromJson(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load profile.')));
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_rawProfileData == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAdminProfile(
          adminData: {
            "email": _rawProfileData!['email'],
            "profile": _rawProfileData!['profile'] ?? {},
          },
        ),
      ),
    );
    if (result == true) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isNotEmpty) await _fetchProfile(token);
    }
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.blue),
                title: const Text(
                  'View Profile Picture',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewProfilePicture();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text(
                  'Change Profile Photo',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _changeProfilePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _viewProfilePicture() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(_profile!.imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Future<void> _changeProfilePhoto() async {
    try {
      Uint8List? imageBytes;
      String? fileName;

      final result = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (result == null) return;
      imageBytes = await result.readAsBytes();
      fileName = result.name;

      final bool? confirm = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Preview Profile Picture',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.memory(
                    imageBytes!,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Do you want to save this as your new profile picture?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB36CC6),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Save',
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
                ),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading new profile photo...')),
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) throw Exception('Token not found');

      final uri = Uri.parse(
        'https://janna-server.onrender.com/api/auth/change-profile-picture',
      );
      final request = http.MultipartRequest('PUT', uri)
        ..headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully!')),
        );
        await _fetchProfile(token);
      } else {
        throw Exception('Upload failed (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload photo: $e')));
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          "Logout Confirmation",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          "Are you sure you want to logout?",
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');
              Navigator.of(context).pop();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text(
              "Logout",
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFB36CC6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
          ? const Center(child: Text('Profile not found'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showProfileOptions,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(_profile!.imageUrl),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _profile!.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _profile!.role,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.email, color: Colors.red),
                        title: const Text(
                          'Email',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        subtitle: Text(
                          _profile!.email,
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.phone, color: Colors.red),
                        title: const Text(
                          'Phone',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        subtitle: Text(
                          _profile!.phone,
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.person, color: Colors.red),
                        title: const Text(
                          'Gender',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        subtitle: Text(
                          _profile!.gender,
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit, color: Colors.blue),
                        title: const Text(
                          'Edit Profile',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        onTap: _navigateToEditProfile,
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.lock, color: Colors.orange),
                        title: const Text(
                          'Change Password',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        onTap: () async {
                          final bool? result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ChangePasswordScreen(),
                            ),
                          );
                          if (result == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Password changed successfully!"),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          'Logout',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        onTap: _confirmLogout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
