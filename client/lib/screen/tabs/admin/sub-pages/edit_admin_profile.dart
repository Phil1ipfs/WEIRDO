import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditAdminProfile extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const EditAdminProfile({super.key, required this.adminData});

  @override
  State<EditAdminProfile> createState() => _EditAdminProfileState();
}

class _EditAdminProfileState extends State<EditAdminProfile> {
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _contactNumberController;

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final profile = widget.adminData['profile'] ?? {};
    _emailController = TextEditingController(
      text: widget.adminData['email'] ?? '',
    );
    _firstNameController = TextEditingController(
      text: profile['first_name'] ?? '',
    );
    _middleNameController = TextEditingController(
      text: profile['middle_name'] ?? '',
    );
    _lastNameController = TextEditingController(
      text: profile['last_name'] ?? '',
    );
    _contactNumberController = TextEditingController(
      text: profile['contact_number'] ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _showSnackBar('Authentication failed. Please log in again.');
        return;
      }

      final updatedData = {
        'email': _emailController.text,
        'first_name': _firstNameController.text,
        'middle_name': _middleNameController.text,
        'last_name': _lastNameController.text,
        'contact_number': _contactNumberController.text,
      };

      final response = await http.put(
        Uri.parse('https://janna-server.onrender.com/api/admins/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Admin profile updated successfully!');
        Navigator.pop(context, true);
      } else {
        final message =
            jsonDecode(response.body)['message'] ?? 'Failed to update profile.';
        _showSnackBar('Error: $message');
      }
    } catch (e) {
      _showSnackBar('An unexpected error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmUpdate() async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Update'),
        content: const Text('Do you want to save these changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB36CC6),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      _updateProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Admin Profile',
          style: TextStyle(
            fontFamily: 'Sahitya',
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFFB36CC6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextFormField(
                _emailController,
                'Email Address',
                Icons.email,
                true,
                TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildTextFormField(
                _firstNameController,
                'First Name',
                Icons.person,
                true,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                _middleNameController,
                'Middle Name (Optional)',
                Icons.person_outline,
                false,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                _lastNameController,
                'Last Name',
                Icons.person,
                true,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                _contactNumberController,
                'Contact Number',
                Icons.phone,
                true,
                TextInputType.phone,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _confirmUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB36CC6),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isRequired, [
    TextInputType keyboardType = TextInputType.text,
  ]) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon),
      style: const TextStyle(fontFamily: 'Poppins'),
      validator: isRequired
          ? (value) => value!.isEmpty ? '$label is required' : null
          : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFB36CC6)),
      labelStyle: const TextStyle(fontFamily: 'Poppins'),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB36CC6), width: 2.0),
      ),
    );
  }
}
