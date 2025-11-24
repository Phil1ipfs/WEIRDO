// import 'package:flutter/material.dart';
// import '../services/dropdown_service.dart';
// import '../services/auth_service.dart';
// import 'terms_screen.dart';

// class RegistrationScreen extends StatefulWidget {
//   const RegistrationScreen({super.key});

//   @override
//   State<RegistrationScreen> createState() => _RegistrationScreenState();
// }

// class _RegistrationScreenState extends State<RegistrationScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _firstNameController = TextEditingController();
//   final _middleNameController = TextEditingController();
//   final _lastNameController = TextEditingController();
//   final _contactNumberController = TextEditingController();
//   final _validIdController = TextEditingController();
//   final _genderController = TextEditingController();

//   String _userType = 'client';
//   String? _selectedFieldId;
//   List<dynamic> _fields = [];
//   bool _isLoadingFields = true;
//   bool _agreedToTerms = false; // ✅ added

//   @override
//   void initState() {
//     super.initState();
//     _loadFields();
//   }

//   Future<void> _loadFields() async {
//     try {
//       final data = await DropdownService.get('fields');
//       setState(() {
//         _fields = data;
//         _selectedFieldId = _fields.first['field_id'].toString();
//         _isLoadingFields = false;
//       });
//     } catch (e) {
//       setState(() => _isLoadingFields = false);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Failed to load fields: $e')));
//     }
//   }

//   void _register() async {
//     if (!_agreedToTerms) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please agree to the Terms and Agreement'),
//         ),
//       );
//       return;
//     }

//     if (_formKey.currentState!.validate()) {
//       final data = {
//         "email": _emailController.text,
//         "password": _passwordController.text,
//         "first_name": _firstNameController.text,
//         "middle_name": _middleNameController.text,
//         "last_name": _lastNameController.text,
//         "contact_number": _contactNumberController.text,
//         "gender": _genderController.text,
//         "field_id": _selectedFieldId,
//       };

//       if (_userType == 'doctor') {
//         data['valid_id'] = _validIdController.text;
//         final result = await AuthService.registerDoctor(data);
//         _handleResponse(result);
//       } else {
//         final result = await AuthService.registerClient(data);
//         _handleResponse(result);
//       }
//     }
//   }

//   void _handleResponse(Map<String, dynamic> result) {
//     if (result['success']) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Registration successful')));
//       Navigator.pushReplacementNamed(context, '/login');
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(result['message'] ?? 'Something went wrong')),
//       );
//     }
//   }

//   void _goToLogin() {
//     Navigator.pushNamed(context, '/login');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF6F4F0),
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 const Text(
//                   'Create Account',
//                   style: TextStyle(
//                     fontFamily: 'Sahitya',
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFFB36CC6),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   'Join us and get started with your journey!',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     fontSize: 14,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // User Type Toggle
//                 Row(
//                   children: [
//                     Expanded(
//                       child: RadioListTile<String>(
//                         title: const Text('Client'),
//                         value: 'client',
//                         groupValue: _userType,
//                         onChanged: (val) => setState(() => _userType = val!),
//                       ),
//                     ),
//                     Expanded(
//                       child: RadioListTile<String>(
//                         title: const Text('Doctor'),
//                         value: 'doctor',
//                         groupValue: _userType,
//                         onChanged: (val) => setState(() => _userType = val!),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),

//                 _buildTextField(
//                   _emailController,
//                   'Email',
//                   keyboardType: TextInputType.emailAddress,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildTextField(
//                   _passwordController,
//                   'Password',
//                   obscureText: true,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildTextField(_firstNameController, 'First Name'),
//                 const SizedBox(height: 16),
//                 _buildTextField(
//                   _middleNameController,
//                   'Middle Name (Optional)',
//                   required: false,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildTextField(_lastNameController, 'Last Name'),
//                 const SizedBox(height: 16),
//                 _buildTextField(_contactNumberController, 'Contact Number'),
//                 const SizedBox(height: 16),

//                 DropdownButtonFormField<String>(
//                   value: _genderController.text.isNotEmpty
//                       ? _genderController.text
//                       : null,
//                   decoration: const InputDecoration(
//                     labelText: 'Gender',
//                     border: OutlineInputBorder(),
//                   ),
//                   items: const [
//                     DropdownMenuItem(value: 'Male', child: Text('Male')),
//                     DropdownMenuItem(value: 'Female', child: Text('Female')),
//                     DropdownMenuItem(
//                       value: 'Non-binary',
//                       child: Text('Non-binary'),
//                     ),
//                     DropdownMenuItem(value: 'Gay', child: Text('Gay')),
//                     DropdownMenuItem(value: 'Lesbian', child: Text('Lesbian')),
//                     DropdownMenuItem(
//                       value: 'Bisexual',
//                       child: Text('Bisexual'),
//                     ),
//                     DropdownMenuItem(
//                       value: 'Transgender',
//                       child: Text('Transgender'),
//                     ),
//                     DropdownMenuItem(value: 'Queer', child: Text('Queer')),
//                     DropdownMenuItem(
//                       value: 'Prefer not to say',
//                       child: Text('Prefer not to say'),
//                     ),
//                     DropdownMenuItem(value: 'Other', child: Text('Other')),
//                   ],
//                   onChanged: (value) {
//                     setState(() {
//                       _genderController.text = value!;
//                     });
//                   },
//                   validator: (value) {
//                     if (value == null || value.isEmpty)
//                       return 'Please select your gender';
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),

//                 // Show custom text field if "Other" is selected
//                 if (_genderController.text == 'Other') ...[
//                   _buildTextField(
//                     _genderController,
//                     'Please specify your gender',
//                   ),
//                   const SizedBox(height: 16),
//                 ],

//                 if (_userType == 'doctor') ...[
//                   _isLoadingFields
//                       ? const CircularProgressIndicator()
//                       : DropdownButtonFormField<String>(
//                           value:
//                               _selectedFieldId ??
//                               (_fields.isNotEmpty
//                                   ? _fields.first['field_id'].toString()
//                                   : null),
//                           hint: const Text('Please select a field'),
//                           decoration: const InputDecoration(
//                             labelText: 'Select Field',
//                             border: OutlineInputBorder(),
//                           ),
//                           items: _fields.map<DropdownMenuItem<String>>((field) {
//                             return DropdownMenuItem<String>(
//                               value: field['field_id'].toString(),
//                               child: Text(field['name']),
//                             );
//                           }).toList(),
//                           onChanged: (value) {
//                             setState(() {
//                               _selectedFieldId = value!;
//                             });
//                           },
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please select a field';
//                             }
//                             return null;
//                           },
//                         ),
//                   const SizedBox(height: 16),
//                   _buildTextField(_validIdController, 'Valid ID'),
//                   const SizedBox(height: 16),
//                 ],
//                 // ✅ Terms & Agreement Checkbox
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: _agreedToTerms,
//                       activeColor: const Color(0xFFB36CC6),
//                       onChanged: (value) {
//                         setState(() => _agreedToTerms = value!);
//                       },
//                     ),
//                     Expanded(
//                       child: GestureDetector(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => const TermsScreen(),
//                             ),
//                           );
//                         },
//                         child: const Text.rich(
//                           TextSpan(
//                             text: 'I agree to the ',
//                             style: TextStyle(
//                               fontFamily: 'Poppins',
//                               fontSize: 14,
//                               color: Colors.black87,
//                             ),
//                             children: [
//                               TextSpan(
//                                 text: 'Terms and Agreement',
//                                 style: TextStyle(
//                                   color: Color(0xFFB36CC6),
//                                   fontWeight: FontWeight.w600,
//                                   decoration: TextDecoration.underline,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 8),

//                 // Register Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _agreedToTerms ? _register : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFFB36CC6),
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                     child: const Text(
//                       'Register',
//                       style: TextStyle(
//                         fontFamily: 'Poppins',
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // Back to Login
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton(
//                     onPressed: _goToLogin,
//                     style: OutlinedButton.styleFrom(
//                       side: const BorderSide(color: Color(0xFFB36CC6)),
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                     child: const Text(
//                       'Back to Login',
//                       style: TextStyle(
//                         fontFamily: 'Poppins',
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                         color: Color(0xFFB36CC6),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(
//     TextEditingController controller,
//     String label, {
//     bool obscureText = false,
//     TextInputType keyboardType = TextInputType.text,
//     bool required = true,
//   }) {
//     return TextFormField(
//       controller: controller,
//       obscureText: obscureText,
//       keyboardType: keyboardType,
//       style: const TextStyle(
//         fontFamily: 'Poppins',
//         fontWeight: FontWeight.w400,
//       ),
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//       ),
//       validator: (value) {
//         if (!required) return null;
//         if (value == null || value.isEmpty) return 'Enter your $label';
//         if (label == 'Email' && !value.contains('@'))
//           return 'Enter a valid email';
//         if (label == 'Password' && value.length < 6)
//           return 'Password must be at least 6 characters';
//         return null;
//       },
//     );
//   }
// }

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/dropdown_service.dart';
import '../services/auth_service.dart';
import 'terms_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _validIdController = TextEditingController();
  final _genderController = TextEditingController();

  String _userType = 'client';
  String? _selectedFieldId;
  List<dynamic> _fields = [];
  bool _isLoadingFields = true;
  bool _agreedToTerms = false;

  // ✅ Added for password visibility toggle
  bool _obscurePassword = true;

  // ✅ Image picker for valid ID
  Uint8List? _validIdImage;
  String? _validIdFileName;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    try {
      final data = await DropdownService.get('fields');
      setState(() {
        _fields = data;
        _selectedFieldId = _fields.first['field_id'].toString();
        _isLoadingFields = false;
      });
    } catch (e) {
      setState(() => _isLoadingFields = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load fields: $e')));
    }
  }

  // ✅ Image picker for valid ID
  Future<void> _pickValidId() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _validIdImage = bytes;
        _validIdFileName = pickedFile.name;
      });
    }
  }

  void _register() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Agreement'),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final data = {
        "email": _emailController.text,
        "password": _passwordController.text,
        "first_name": _firstNameController.text,
        "middle_name": _middleNameController.text,
        "last_name": _lastNameController.text,
        "contact_number": _contactNumberController.text,
        "gender": _genderController.text,
        "field_id": _selectedFieldId,
      };

      if (_userType == 'doctor') {
        data['valid_id'] = _validIdController.text;
        final result = await AuthService.registerDoctor(
          data,
          validIdImage: _validIdImage,
          validIdFileName: _validIdFileName,
        );
        _handleResponse(result);
      } else {
        final result = await AuthService.registerClient(data);
        _handleResponse(result);
      }
    }
  }

  void _handleResponse(Map<String, dynamic> result) {
    if (result['success']) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration successful')));
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Something went wrong')),
      );
    }
  }

  void _goToLogin() {
    Navigator.pushNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontFamily: 'Sahitya',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB36CC6),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join us and get started with your journey!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                // User Type Toggle
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Client'),
                        value: 'client',
                        groupValue: _userType,
                        onChanged: (val) => setState(() => _userType = val!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Doctor'),
                        value: 'doctor',
                        groupValue: _userType,
                        onChanged: (val) => setState(() => _userType = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                _buildTextField(
                  _emailController,
                  'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // ✅ Password with toggle
                _buildTextField(
                  _passwordController,
                  'Password',
                  obscureText: _obscurePassword,
                  isPassword: true,
                ),
                const SizedBox(height: 16),

                _buildTextField(_firstNameController, 'First Name'),
                const SizedBox(height: 16),
                _buildTextField(
                  _middleNameController,
                  'Middle Name (Optional)',
                  required: false,
                ),
                const SizedBox(height: 16),
                _buildTextField(_lastNameController, 'Last Name'),
                const SizedBox(height: 16),
                _buildTextField(_contactNumberController, 'Contact Number'),
                const SizedBox(height: 16),

                // Gender Dropdown
                DropdownButtonFormField<String>(
                  value: _genderController.text.isNotEmpty
                      ? _genderController.text
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Male',
                      child: Text('Male', style: TextStyle(color: Colors.black87)),
                    ),
                    DropdownMenuItem(
                      value: 'Female',
                      child: Text('Female', style: TextStyle(color: Colors.black87)),
                    ),
                    DropdownMenuItem(
                      value: 'Non-binary',
                      child: Text('Non-binary', style: TextStyle(color: Colors.black87)),
                    ),
                    DropdownMenuItem(
                      value: 'Gay',
                      child: Text('Gay', style: TextStyle(color: Colors.black87)),
                    ),
                    DropdownMenuItem(
                      value: 'Lesbian',
                      child: Text('Lesbian', style: TextStyle(color: Colors.black87)),
                    ),
                    DropdownMenuItem(
                      value: 'Bisexual',
                      child: Text('Bisexual', style: TextStyle(color: Colors.black87)),
                    ),
                    DropdownMenuItem(
                      value: 'Transgender',
                      child: Text('Transgender', style: TextStyle(color: Colors.black87)),
                    ),
                    DropdownMenuItem(
                      value: 'Queer',
                      child: Text('Queer', style: TextStyle(color: Colors.black87)),
                    ),
                    DropdownMenuItem(
                      value: 'Prefer not to say',
                      child: Text('Prefer not to say', style: TextStyle(color: Colors.black87)),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child: Text('Other', style: TextStyle(color: Colors.black87)),
                    ),
                  ],
                  style: const TextStyle(color: Colors.black87),
                  onChanged: (value) {
                    setState(() {
                      _genderController.text = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your gender';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Show custom text field if "Other" is selected
                if (_genderController.text == 'Other') ...[
                  _buildTextField(
                    _genderController,
                    'Please specify your gender',
                  ),
                  const SizedBox(height: 16),
                ],

                if (_userType == 'doctor') ...[
                  _isLoadingFields
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                          value:
                              _selectedFieldId ??
                              (_fields.isNotEmpty
                                  ? _fields.first['field_id'].toString()
                                  : null),
                          hint: const Text('Please select a field'),
                          decoration: const InputDecoration(
                            labelText: 'Select Field',
                            border: OutlineInputBorder(),
                          ),
                          items: _fields.map<DropdownMenuItem<String>>((field) {
                            return DropdownMenuItem<String>(
                              value: field['field_id'].toString(),
                              child: Text(
                                field['name'],
                                style: const TextStyle(color: Colors.black87),
                              ),
                            );
                          }).toList(),
                          style: const TextStyle(color: Colors.black87),
                          onChanged: (value) {
                            setState(() {
                              _selectedFieldId = value!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a field';
                            }
                            return null;
                          },
                        ),
                  const SizedBox(height: 16),
                  _buildTextField(_validIdController, 'Valid ID Number'),
                  const SizedBox(height: 16),

                  // Valid ID Image Upload Button
                  ElevatedButton.icon(
                    onPressed: _pickValidId,
                    icon: const Icon(Icons.attach_file, color: Colors.white),
                    label: Text(
                      _validIdFileName ?? 'Attached valid id',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB36CC6),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  // Show image preview if selected
                  if (_validIdImage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _validIdImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],

                // Terms and Agreement
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      activeColor: const Color(0xFFB36CC6),
                      onChanged: (value) {
                        setState(() => _agreedToTerms = value!);
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TermsScreen(),
                            ),
                          );
                        },
                        child: const Text.rich(
                          TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(
                                text: 'Terms and Agreement',
                                style: TextStyle(
                                  color: Color(0xFFB36CC6),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _agreedToTerms ? _register : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB36CC6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Back to Login
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _goToLogin,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFB36CC6)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFB36CC6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        // ✅ show eye icon only for password fields
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFFB36CC6),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
      ),
      validator: (value) {
        if (!required) return null;
        if (value == null || value.isEmpty) return 'Enter your $label';
        if (label == 'Email' && !value.contains('@')) {
          return 'Enter a valid email';
        }
        if (label == 'Password') {
          // Check minimum length
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          // Check if alphanumeric only (letters and numbers, no special characters)
          if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
            return 'Password must contain only letters and numbers';
          }
          // Check for at least one uppercase letter
          if (!RegExp(r'[A-Z]').hasMatch(value)) {
            return 'Password must contain at least one uppercase letter';
          }
          // Check for at least one lowercase letter
          if (!RegExp(r'[a-z]').hasMatch(value)) {
            return 'Password must contain at least one lowercase letter';
          }
          // Check for at least one number
          if (!RegExp(r'[0-9]').hasMatch(value)) {
            return 'Password must contain at least one number';
          }
        }
        return null;
      },
    );
  }
}
