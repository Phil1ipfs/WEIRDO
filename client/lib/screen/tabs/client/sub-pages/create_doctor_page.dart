import 'package:flutter/material.dart';

class CreateDoctorPage extends StatefulWidget {
  const CreateDoctorPage({super.key});

  @override
  State<CreateDoctorPage> createState() => _CreateDoctorPageState();
}

class _CreateDoctorPageState extends State<CreateDoctorPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String _selectedSpecialty = 'Pediatrics';

  final List<String> specialties = [
    'Pediatrics',
    'Cardiology',
    'Neurology',
    'General Medicine',
    'Dermatology',
    'ENT',
    'Other',
  ];

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Normally you'd send data to backend here...

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Success'),
          content: const Text(
            'Doctor account has been created successfully.\nCredentials have been sent to the email address.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      // Clear form
      _firstNameController.clear();
      _middleNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _ageController.clear();
      setState(() => _selectedSpecialty = 'Pediatrics');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Doctor Account',
          style: TextStyle(
            fontFamily: 'Sahitya',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFB36CC6),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // First Name
              _buildInputField(_firstNameController, 'First Name'),

              // Middle Name
              _buildInputField(_middleNameController, 'Middle Name'),

              // Last Name
              _buildInputField(_lastNameController, 'Last Name'),

              // Email
              _buildInputField(
                _emailController,
                'Email Address',
                inputType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required.';
                  } else if (!value.contains('@')) {
                    return 'Enter a valid email.';
                  }
                  return null;
                },
              ),

              // Age
              _buildInputField(
                _ageController,
                'Age',
                inputType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Age is required.';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age <= 0) {
                    return 'Enter a valid age.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Specialty Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSpecialty,
                items: specialties.map((specialty) {
                  return DropdownMenuItem(
                    value: specialty,
                    child: Text(
                      specialty,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  );
                }).toList(),
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Doctor Type / Specialty',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) =>
                    setState(() => _selectedSpecialty = value!),
              ),

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB36CC6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label, {
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        validator:
            validator ??
            (value) => (value == null || value.isEmpty)
                ? 'This field is required.'
                : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
