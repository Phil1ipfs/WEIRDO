// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class AddArticleScreen extends StatefulWidget {
//   const AddArticleScreen({super.key});

//   @override
//   State<AddArticleScreen> createState() => _AddArticleScreenState();
// }

// class _AddArticleScreenState extends State<AddArticleScreen> {
//   final TextEditingController titleController = TextEditingController();
//   final TextEditingController slugController = TextEditingController();
//   final TextEditingController contentController = TextEditingController();
//   final TextEditingController excerptController = TextEditingController();
//   final TextEditingController linkController =
//       TextEditingController(); // ✅ Added

//   String status = 'draft';
//   final Color customColor = const Color(0xFFB36CC6);

//   Future<void> _submitArticle() async {
//     final title = titleController.text.trim();
//     final slug = slugController.text.trim();
//     final content = contentController.text.trim();
//     final excerpt = excerptController.text.trim();
//     final link = linkController.text.trim(); // ✅ Get link value

//     if (title.isEmpty || slug.isEmpty || content.isEmpty || excerpt.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('All fields are required.')));
//       return;
//     }

//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');

//     if (token == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('User token not found.')));
//       return;
//     }

//     final url = Uri.parse('https://janna-server.onrender.com/api/articles');
//     final response = await http.post(
//       url,
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'title': title,
//         'slug': slug,
//         'content': content,
//         'excerpt': excerpt,
//         'status': status,
//         'link': link, // ✅ Include link in request
//         'token': token,
//       }),
//     );

//     if (response.statusCode == 201) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Article created successfully.')),
//       );
//       Navigator.pop(context);
//     } else {
//       final data = jsonDecode(response.body);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: ${data['message']}')));
//     }
//   }

//   InputDecoration _inputDecoration(String label) {
//     return InputDecoration(
//       labelText: label,
//       labelStyle: const TextStyle(fontFamily: 'Poppins'),
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(2)),
//       filled: true,
//       fillColor: Colors.white,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Add Article',
//           style: TextStyle(
//             fontFamily: 'Sahitya',
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: customColor,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView(
//           children: [
//             TextField(
//               controller: titleController,
//               decoration: _inputDecoration('Title'),
//               style: const TextStyle(fontFamily: 'Poppins'),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: slugController,
//               decoration: _inputDecoration('Slug'),
//               style: const TextStyle(fontFamily: 'Poppins'),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: contentController,
//               maxLines: 5,
//               decoration: _inputDecoration('Content'),
//               style: const TextStyle(fontFamily: 'Poppins'),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: excerptController,
//               maxLines: 2,
//               decoration: _inputDecoration('Excerpt'),
//               style: const TextStyle(fontFamily: 'Poppins'),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: linkController,
//               decoration: _inputDecoration(
//                 'Link (optional)',
//               ), // ✅ New field label
//               style: const TextStyle(fontFamily: 'Poppins'),
//               keyboardType: TextInputType.url,
//             ),
//             const SizedBox(height: 12),
//             DropdownButtonFormField<String>(
//               value: status,
//               decoration: _inputDecoration('Status'),
//               style: const TextStyle(fontFamily: 'Poppins'),
//               items: const [
//                 DropdownMenuItem(value: 'draft', child: Text('Draft')),
//                 DropdownMenuItem(value: 'published', child: Text('Published')),
//               ],
//               onChanged: (value) {
//                 if (value != null) {
//                   setState(() => status = value);
//                 }
//               },
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _submitArticle,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: customColor,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   textStyle: const TextStyle(
//                     fontFamily: 'Poppins',
//                     fontWeight: FontWeight.w500,
//                     fontSize: 16,
//                   ),
//                 ),
//                 child: const Text(
//                   'Submit Article',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddArticleScreen extends StatefulWidget {
  const AddArticleScreen({super.key});

  @override
  State<AddArticleScreen> createState() => _AddArticleScreenState();
}

class _AddArticleScreenState extends State<AddArticleScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController slugController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController excerptController = TextEditingController();
  final TextEditingController linkController = TextEditingController();

  String status = 'draft';
  final Color customColor = const Color(0xFFB36CC6);

  final ImagePicker _picker = ImagePicker();
  Uint8List? _coverImageBytes;
  bool _isLoading = false;

  // 📸 Pick image from gallery
  Future<void> _pickCoverImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _coverImageBytes = bytes);
    }
  }

  // 🖼️ Load default image if none selected
  Future<Uint8List> _getDefaultImageBytes() async {
    final byteData = await rootBundle.load('assets/images/banner.png');
    return byteData.buffer.asUint8List();
  }

  Future<void> _submitArticle() async {
    final title = titleController.text.trim();
    final slug = slugController.text.trim();
    final content = contentController.text.trim();
    final excerpt = excerptController.text.trim();
    final link = linkController.text.trim();

    if (title.isEmpty || slug.isEmpty || content.isEmpty || excerpt.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields are required.')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User token not found.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageBytes = _coverImageBytes ?? await _getDefaultImageBytes();

      // 🌐 Create multipart request
      final url = Uri.parse('https://janna-server.onrender.com/api/articles');
      final request = http.MultipartRequest('POST', url)
        ..fields['title'] = title
        ..fields['slug'] = slug
        ..fields['content'] = content
        ..fields['excerpt'] = excerpt
        ..fields['status'] = status
        ..fields['link'] = link
        ..fields['token'] = token
        ..files.add(
          http.MultipartFile.fromBytes(
            'cover_image',
            imageBytes,
            filename: 'cover_image.jpg',
          ),
        );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      setState(() => _isLoading = false);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article created successfully.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $responseBody')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Poppins'),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(2)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePreview = _coverImageBytes != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _coverImageBytes!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/banner.png',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Article',
          style: TextStyle(
            fontFamily: 'Sahitya',
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        backgroundColor: customColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            imagePreview,
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _pickCoverImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Choose Cover Image'),
                style: TextButton.styleFrom(foregroundColor: customColor),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: _inputDecoration('Title'),
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: slugController,
              decoration: _inputDecoration('Slug'),
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: _inputDecoration('Content'),
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: excerptController,
              maxLines: 2,
              decoration: _inputDecoration('Excerpt'),
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: linkController,
              decoration: _inputDecoration('Link (optional)'),
              style: const TextStyle(fontFamily: 'Poppins'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: status,
              decoration: _inputDecoration('Status'),
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.black87,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'draft',
                  child: Text('Draft', style: TextStyle(color: Colors.black87)),
                ),
                DropdownMenuItem(
                  value: 'published',
                  child: Text('Published', style: TextStyle(color: Colors.black87)),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => status = value);
                }
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitArticle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: customColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Article',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
