// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http_parser/http_parser.dart';
// import 'sub-pages/change_password_screen.dart';
// import 'sub-pages/edit_doctor_profile.dart';
// import 'sub-pages/notification_page.dart';
// import 'sub-pages/chat_admin_view.dart';

// class DoctorProfile extends StatefulWidget {
//   const DoctorProfile({super.key});

//   @override
//   State<DoctorProfile> createState() => _DoctorProfileState();
// }

// class _DoctorProfileState extends State<DoctorProfile> {
//   Map<String, dynamic>? userData;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetchProfile();
//   }

//   Future<void> fetchProfile() async {
//     setState(() => isLoading = true);
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("token");
//       if (token == null) {
//         if (mounted) setState(() => isLoading = false);
//         return;
//       }

//       final response = await http.get(
//         Uri.parse("https://janna-server.onrender.com/api/auth/profile"),
//         headers: {"Authorization": "Bearer $token"},
//       );

//       if (response.statusCode == 200) {
//         final data = response.body.isNotEmpty
//             ? jsonDecode(response.body) as Map<String, dynamic>
//             : {};
//         final doctorProfile = data['profile'] as Map<String, dynamic>?;

//         if (doctorProfile != null && mounted) {
//           setState(() {
//             userData = {
//               ...doctorProfile,
//               "email": data['email'] ?? 'Not available',
//               "role": data['role'] ?? 'Doctor',
//               "specialty_name":
//                   doctorProfile['field']?['name'] ?? 'Not specified',
//               "profile_picture":
//                   data['profile_picture'] ?? "https://picsum.photos/200",
//             };
//             isLoading = false;
//           });
//         } else if (mounted) {
//           setState(() {
//             userData = null;
//             isLoading = false;
//           });
//         }
//       } else {
//         debugPrint(
//           "Error fetching profile (HTTP ${response.statusCode}): ${response.body}",
//         );
//         if (mounted) setState(() => isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Failed to fetch profile.")),
//         );
//       }
//     } catch (e) {
//       debugPrint("Fetch profile error: $e");
//       if (mounted) setState(() => isLoading = false);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error fetching profile: $e")));
//     }
//   }

//   /// --- Show bottom sheet for image options ---
//   void _showProfileOptions() {
//     if (userData == null) return;
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

//   /// --- View full-size profile picture ---
//   void _viewProfilePicture() {
//     if (userData == null) return;
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         backgroundColor: Colors.transparent,
//         child: InteractiveViewer(
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(12),
//             child: Image.network(
//               userData!['profile_picture'],
//               fit: BoxFit.contain,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   /// --- Change profile photo (mobile + web) ---
//   Future<void> _changeProfilePhoto() async {
//     if (userData == null) return;

//     try {
//       final picker = ImagePicker();
//       final pickedFile = await picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 85,
//       );

//       if (pickedFile == null) return;

//       final imageBytes = await pickedFile.readAsBytes();
//       final fileName = pickedFile.name;

//       // --- Preview before uploading ---
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
//                     imageBytes,
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
//                   style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
//                 ),
//               ),
//             ],
//           );
//         },
//       );

//       if (confirm != true) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Uploading new profile photo...')),
//       );

//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token');
//       if (token == null) throw Exception('Token not found');

//       final uri = Uri.parse(
//         'https://janna-server.onrender.com/api/auth/change-profile-picture',
//       );
//       final request = http.MultipartRequest('PUT', uri)
//         ..headers['Authorization'] = 'Bearer $token';

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
//         await fetchProfile();
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

//   /// --- Full name builder ---
//   String getFullName() {
//     if (userData == null) return '';
//     final parts = [
//       userData!['first_name'] ?? '',
//       userData!['middle_name'] ?? '',
//       userData!['last_name'] ?? '',
//     ].where((part) => part.isNotEmpty);
//     return parts.join(' ');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Profile",
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

//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : userData == null
//           ? const Center(
//               child: Text(
//                 "No profile data found. Please log in.",
//                 style: TextStyle(fontFamily: 'Poppins'),
//               ),
//             )
//           : RefreshIndicator(
//               onRefresh: fetchProfile,
//               child: ListView(
//                 padding: const EdgeInsets.all(16),
//                 children: [
//                   // --- Profile Card ---
//                   Card(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     elevation: 3,
//                     child: Padding(
//                       padding: const EdgeInsets.all(20),
//                       child: Column(
//                         children: [
//                           GestureDetector(
//                             onTap: _showProfileOptions,
//                             child: CircleAvatar(
//                               radius: 50,
//                               backgroundImage: NetworkImage(
//                                 userData!['profile_picture'],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           Text(
//                             getFullName(),
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontFamily: 'Poppins',
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           Text(
//                             userData!['role'] ?? "Doctor",
//                             style: const TextStyle(
//                               fontSize: 13,
//                               fontFamily: 'Poppins',
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 24),

//                   // --- Contact Info ---
//                   Card(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     elevation: 2,
//                     child: Column(
//                       children: [
//                         ListTile(
//                           leading: const Icon(Icons.email, color: Colors.red),
//                           title: const Text(
//                             'Email',
//                             style: TextStyle(fontFamily: 'Poppins'),
//                           ),
//                           subtitle: Text(
//                             userData!['email'] ?? "Not available",
//                             style: const TextStyle(fontFamily: 'Poppins'),
//                           ),
//                         ),
//                         const Divider(height: 0),
//                         ListTile(
//                           leading: const Icon(Icons.phone, color: Colors.red),
//                           title: const Text(
//                             'Phone',
//                             style: TextStyle(fontFamily: 'Poppins'),
//                           ),
//                           subtitle: Text(
//                             userData!['contact_number'] ?? "N/A",
//                             style: const TextStyle(fontFamily: 'Poppins'),
//                           ),
//                         ),
//                         const Divider(height: 0),
//                         ListTile(
//                           leading: const Icon(
//                             Icons.star,
//                             color: Color(0xFFB36CC6),
//                           ),
//                           title: const Text(
//                             'Specialization',
//                             style: TextStyle(fontFamily: 'Poppins'),
//                           ),
//                           subtitle: Text(
//                             userData!['specialty_name'] ?? "N/A",
//                             style: const TextStyle(fontFamily: 'Poppins'),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 24),

//                   // --- Account Actions ---
//                   Card(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     elevation: 2,
//                     child: Column(
//                       children: [
//                         ListTile(
//                           leading: const Icon(Icons.edit, color: Colors.blue),
//                           title: const Text(
//                             'Edit Profile',
//                             style: TextStyle(fontFamily: 'Poppins'),
//                           ),
//                           onTap: () async {
//                             if (userData != null) {
//                               final bool? result = await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       EditDoctorProfile(doctorData: userData!),
//                                 ),
//                               );
//                               if (result == true) await fetchProfile();
//                             }
//                           },
//                         ),
//                         const Divider(height: 0),
//                         ListTile(
//                           leading: const Icon(Icons.lock, color: Colors.orange),
//                           title: const Text(
//                             'Change Password',
//                             style: TextStyle(fontFamily: 'Poppins'),
//                           ),
//                           onTap: () async {
//                             final bool? result = await Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) =>
//                                     const ChangePasswordScreen(),
//                               ),
//                             );
//                             if (result == true) {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text(
//                                     "Password changed successfully!",
//                                   ),
//                                   behavior: SnackBarBehavior.floating,
//                                 ),
//                               );
//                             }
//                           },
//                         ),
//                         const Divider(height: 0),
//                         ListTile(
//                           leading: const Icon(
//                             Icons.support_agent,
//                             color: Colors.purple,
//                           ),
//                           title: const Text(
//                             'Chat with Admin',
//                             style: TextStyle(fontFamily: 'Poppins'),
//                           ),
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const ChatAdminView(),
//                               ),
//                             );
//                           },
//                         ),

//                         const Divider(height: 0),
//                         ListTile(
//                           leading: const Icon(Icons.logout, color: Colors.red),
//                           title: const Text(
//                             'Logout',
//                             style: TextStyle(fontFamily: 'Poppins'),
//                           ),
//                           onTap: () async {
//                             showDialog(
//                               context: context,
//                               builder: (context) => AlertDialog(
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 title: const Text(
//                                   "Logout Confirmation",
//                                   style: TextStyle(
//                                     fontFamily: 'Poppins',
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                                 content: const Text(
//                                   "Are you sure you want to logout?",
//                                   style: TextStyle(fontFamily: 'Poppins'),
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () => Navigator.pop(context),
//                                     child: const Text(
//                                       "Cancel",
//                                       style: TextStyle(
//                                         fontFamily: 'Poppins',
//                                         color: Colors.grey,
//                                       ),
//                                     ),
//                                   ),
//                                   TextButton(
//                                     onPressed: () async {
//                                       final prefs =
//                                           await SharedPreferences.getInstance();
//                                       await prefs.remove('token');
//                                       Navigator.of(context).pop();
//                                       Navigator.pushNamedAndRemoveUntil(
//                                         context,
//                                         '/login',
//                                         (route) => false,
//                                       );
//                                     },
//                                     child: const Text(
//                                       "Logout",
//                                       style: TextStyle(
//                                         fontFamily: 'Poppins',
//                                         color: Color(0xFFB36CC6),
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'sub-pages/change_password_screen.dart';
import 'sub-pages/edit_doctor_profile.dart';
import 'sub-pages/notification_page.dart';
import 'sub-pages/chat_admin_view.dart';

class DoctorProfile extends StatefulWidget {
  const DoctorProfile({super.key});

  @override
  State<DoctorProfile> createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
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

  Future<void> fetchProfile() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse("https://janna-server.onrender.com/api/auth/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = response.body.isNotEmpty
            ? jsonDecode(response.body) as Map<String, dynamic>
            : {};
        final doctorProfile = data['profile'] as Map<String, dynamic>?;

        if (doctorProfile != null && mounted) {
          setState(() {
            userData = {
              ...doctorProfile,
              "email": data['email'] ?? 'Not available',
              "role": data['role'] ?? 'Doctor',
              "specialty_name":
                  doctorProfile['field']?['name'] ?? 'Not specified',
              "profile_picture": _buildProfilePictureUrl(data['profile_picture']),
              "gender":
                  doctorProfile['gender'] ?? "Not specified", // 👈 Added safely
            };
            isLoading = false;
          });
        } else if (mounted) {
          setState(() {
            userData = null;
            isLoading = false;
          });
        }
      } else {
        debugPrint(
          "Error fetching profile (HTTP ${response.statusCode}): ${response.body}",
        );
        if (mounted) setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch profile.")),
        );
      }
    } catch (e) {
      debugPrint("Fetch profile error: $e");
      if (mounted) setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching profile: $e")));
    }
  }

  /// --- Show bottom sheet for image options ---
  void _showProfileOptions() {
    if (userData == null) return;
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

  /// --- View full-size profile picture ---
  void _viewProfilePicture() {
    if (userData == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              userData!['profile_picture'],
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  /// --- Change profile photo (mobile + web) ---
  Future<void> _changeProfilePhoto() async {
    if (userData == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final imageBytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name;

      // --- Preview before uploading ---
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
                    imageBytes,
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
                  style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
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
      final token = prefs.getString('token');
      if (token == null) throw Exception('Token not found');

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
        await fetchProfile();
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

  /// --- Full name builder ---
  String getFullName() {
    if (userData == null) return '';
    final parts = [
      userData!['first_name'] ?? '',
      userData!['middle_name'] ?? '',
      userData!['last_name'] ?? '',
    ].where((part) => part.isNotEmpty);
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
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

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? const Center(
              child: Text(
                "No profile data found. Please log in.",
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchProfile,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- Profile Card ---
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
                              backgroundImage: NetworkImage(
                                userData!['profile_picture'],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            getFullName(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            userData!['role'] ?? "Doctor",
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Contact Info ---
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
                            userData!['email'] ?? "Not available",
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
                            userData!['contact_number'] ?? "N/A",
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: const Icon(Icons.person, color: Colors.pink),
                          title: const Text(
                            'Gender',
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                          subtitle: Text(
                            userData!['gender'] ?? "Not specified",
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: const Icon(
                            Icons.star,
                            color: Color(0xFFB36CC6),
                          ),
                          title: const Text(
                            'Specialization',
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                          subtitle: Text(
                            userData!['specialty_name'] ?? "N/A",
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Account Actions ---
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
                          onTap: () async {
                            if (userData != null) {
                              final bool? result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditDoctorProfile(doctorData: userData!),
                                ),
                              );
                              if (result == true) await fetchProfile();
                            }
                          },
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
                                  content: Text(
                                    "Password changed successfully!",
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: const Icon(
                            Icons.support_agent,
                            color: Colors.purple,
                          ),
                          title: const Text(
                            'Chat with Admin',
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChatAdminView(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text(
                            'Logout',
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                          onTap: () async {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                title: const Text(
                                  "Logout Confirmation",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final prefs =
                                          await SharedPreferences.getInstance();
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
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
