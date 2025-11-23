import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Model to simplify specialty data handling
class Specialty {
  final int id;
  final String name;

  Specialty({required this.id, required this.name});

  factory Specialty.fromJson(Map<String, dynamic> json) {
    // Assuming the backend returns 'field_id' and 'name' for specialties
    return Specialty(id: json['field_id'], name: json['name']);
  }
}

class EditDoctorProfile extends StatefulWidget {
  final Map<String, dynamic> doctorData;

  const EditDoctorProfile({super.key, required this.doctorData});

  @override
  State<EditDoctorProfile> createState() => _EditDoctorProfileState();
}

class _EditDoctorProfileState extends State<EditDoctorProfile> {
  // Controllers for editable fields
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _contactNumberController;
  late TextEditingController _validIdController;

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isLoadingFields = true;

  // Specialty state
  List<Specialty> _specialties = [];
  Specialty? _selectedSpecialty;

  @override
  void initState() {
    super.initState();

    // Initialize all controllers with current data
    _emailController = TextEditingController(
      text: widget.doctorData['email'] ?? '',
    );
    _firstNameController = TextEditingController(
      text: widget.doctorData['first_name'] ?? '',
    );
    _middleNameController = TextEditingController(
      text: widget.doctorData['middle_name'] ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.doctorData['last_name'] ?? '',
    );
    _contactNumberController = TextEditingController(
      text: widget.doctorData['contact_number'] ?? '',
    );
    _validIdController = TextEditingController(
      text: widget.doctorData['valid_id'] ?? '',
    );

    _fetchSpecialties();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactNumberController.dispose();
    _validIdController.dispose();
    super.dispose();
  }

  // Uses the updated API endpoint: https://janna-server.onrender.com/api/dropdown/fields
  Future<void> _fetchSpecialties() async {
    try {
      final response = await http.get(
        Uri.parse("https://janna-server.onrender.com/api/dropdown/fields"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> fieldData = jsonDecode(response.body);
        _specialties = fieldData
            .map((data) => Specialty.fromJson(data))
            .toList();

        final currentFieldId = widget.doctorData['field_id'];

        // Find the currently selected specialty based on the ID from doctorData
        _selectedSpecialty = _specialties.firstWhereOrNull(
          (s) => s.id == currentFieldId,
        );
      } else {
        _showSnackBar(
          'Failed to load specialties. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Fetch specialties error: $e');
      _showSnackBar('A network error occurred while loading specialties.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFields = false;
        });
      }
    }
  }

  // Handles updating both User (email) and Doctor (profile) data
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSpecialty == null) {
      _showSnackBar('Please select your specialty.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        _showSnackBar('Authentication failed. Please log in again.');
        return;
      }

      // Payload contains both User (email) and Doctor fields
      final updatedData = {
        'email': _emailController.text,
        'first_name': _firstNameController.text,
        'middle_name': _middleNameController.text,
        'last_name': _lastNameController.text,
        'contact_number': _contactNumberController.text,
        'valid_id': _validIdController.text,
        'field_id': _selectedSpecialty!.id,
      };

      final response = await http.put(
        Uri.parse("https://janna-server.onrender.com/api/doctors/profile"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Profile updated successfully!');
        Navigator.pop(context, true); // Go back and indicate success
      } else {
        final error =
            jsonDecode(response.body)['message'] ?? 'Failed to update profile.';
        _showSnackBar('Error: $error');
      }
    } catch (e) {
      _showSnackBar('An unexpected error occurred: $e');
      print('Update error: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'Sahitya',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
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
            children: <Widget>[
              // --- Editable Email Field ---
              _buildTextFormField(
                _emailController,
                'Email Address',
                Icons.email,
                true,
                TextInputType.emailAddress,
              ),

              // Role field is removed
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // --- Doctor Profile Fields ---
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
              const SizedBox(height: 16),

              _buildTextFormField(
                _validIdController,
                'Valid ID / License Number',
                Icons.credit_card,
                true,
              ),
              const SizedBox(height: 16),

              // --- Specialty Dropdown ---
              _isLoadingFields
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<Specialty>(
                      decoration: _inputDecoration('Specialty', Icons.star),
                      value: _selectedSpecialty,
                      hint: const Text(
                        'Select your specialty',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      items: _specialties.map((Specialty specialty) {
                        return DropdownMenuItem<Specialty>(
                          value: specialty,
                          child: Text(
                            specialty.name,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                      style: const TextStyle(color: Colors.black87),
                      onChanged: (Specialty? newValue) {
                        setState(() {
                          _selectedSpecialty = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a specialty' : null,
                    ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _updateProfile,
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

  // Helper function to build consistent TextFormField widgets
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

  // Helper function for consistent input decoration
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

// Simple extension to find the first element or return null
extension IterableExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
