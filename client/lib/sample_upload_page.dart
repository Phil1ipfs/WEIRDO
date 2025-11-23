import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class SampleUploadPage extends StatefulWidget {
  const SampleUploadPage({super.key});

  @override
  State<SampleUploadPage> createState() => _SampleUploadPageState();
}

class _SampleUploadPageState extends State<SampleUploadPage> {
  File? _selectedImageFile;
  Uint8List? _webImage;
  bool _isUploading = false;

  // 📸 Pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      // On web, read image as bytes
      final bytes = await picked.readAsBytes();
      setState(() => _webImage = bytes);
    } else {
      // On mobile/desktop, use File
      setState(() => _selectedImageFile = File(picked.path));
    }
  }

  // ☁️ Upload image to API
  Future<void> _uploadImage() async {
    if (!kIsWeb && _selectedImageFile == null) return;
    if (kIsWeb && _webImage == null) return;

    setState(() => _isUploading = true);
    const apiUrl = "https://janna-server.onrender.com/api/upload"; // adjust as needed

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      if (kIsWeb) {
        // On web: send bytes directly
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _webImage!,
            filename: 'upload.png',
          ),
        );
      } else {
        // On mobile: send file path
        request.files.add(
          await http.MultipartFile.fromPath('image', _selectedImageFile!.path),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Image uploaded successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Upload failed (${response.statusCode})")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ Error: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imagePreview;
    if (kIsWeb && _webImage != null) {
      imagePreview = Image.memory(_webImage!, height: 200);
    } else if (!kIsWeb && _selectedImageFile != null) {
      imagePreview = Image.file(_selectedImageFile!, height: 200);
    } else {
      imagePreview = Container(
        height: 200,
        width: 200,
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 100, color: Colors.white70),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Sample Upload Page")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              imagePreview,
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.photo),
                label: const Text("Pick Image"),
                onPressed: _pickImage,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload),
                label: Text(_isUploading ? "Uploading..." : "Upload Image"),
                onPressed: _isUploading ? null : _uploadImage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
