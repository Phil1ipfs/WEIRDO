import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _otpController = TextEditingController();
  final _oldPasswordController = TextEditingController(); // ⬅ Added
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isOtpVerified = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _sendOtp(); // ⬅ Automatically send OTP when page opens
  }

  Future<void> _sendOtp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.post(
        Uri.parse("https://janna-server.onrender.com/api/auth/send-otp"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);
      print("Server OTP response: $data"); // 🧩 Debug log

      if (response.statusCode == 200 &&
          data['email'] != null &&
          data['code'] != null) {
        // ✅ Send OTP email using EmailJS REST API
        final emailResponse = await http.post(
          Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'service_id':
                'service_lwmhzvz', // 🔹 Replace with your EmailJS service ID
            'template_id':
                'template_vnzskzw', // 🔹 Replace with your EmailJS template ID
            'user_id': 'NqGto92Fuhj7llwi-', // 🔹 Your EmailJS public key
            'template_params': {
              'to_email':
                  data['email'], // must match variable in EmailJS template
              'otp_code':
                  data['code'], // must match variable in EmailJS template
            },
          }),
        );

        // 🧩 Debugging: print EmailJS response
        print("EmailJS response status: ${emailResponse.statusCode}");
        print("EmailJS response body: ${emailResponse.body}");

        if (emailResponse.statusCode == 200 ||
            emailResponse.statusCode == 202) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ OTP sent to ${data['email']}")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "⚠️ Failed to send OTP email. (status ${emailResponse.statusCode})",
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed to generate OTP.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error sending OTP: $e")));
    }
  }

  // 🔹 Step 1: Verify OTP
  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter your OTP")));
      return;
    }

    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception("No token found.");

      final response = await http.post(
        Uri.parse("https://janna-server.onrender.com/api/auth/verify-otp"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"code": _otpController.text.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() => isOtpVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP verified! Enter your passwords.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Invalid OTP")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🔹 Step 2: Change Password (Updated to include old password)
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception("No token found.");

      final response = await http.put(
        Uri.parse("https://janna-server.onrender.com/api/auth/change-password"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "oldPassword": _oldPasswordController.text.trim(),
          "newPassword": _newPasswordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password changed successfully!")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Failed to change password"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🔹 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Change Password",
          style: TextStyle(
            fontFamily: 'Sahitya',
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFFB36CC6),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isOtpVerified ? _buildPasswordForm() : _buildOtpForm(),
      ),
    );
  }

  // 🔹 OTP Form
  Widget _buildOtpForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Enter the 6-digit OTP sent to your email",
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: "OTP Code",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: isLoading ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB36CC6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
          ),
          child: isLoading
              ? const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                )
              : const Text("Verify OTP"),
        ),
      ],
    );
  }

  // 🔹 Password Change Form (Updated)
  Widget _buildPasswordForm() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          TextFormField(
            controller: _oldPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Old Password",
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? "Enter your old password" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "New Password",
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null || v.length < 6 ? "Minimum 6 characters" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Confirm New Password",
              border: OutlineInputBorder(),
            ),
            validator: (v) => v != _newPasswordController.text
                ? "Passwords do not match"
                : null,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: isLoading ? null : _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB36CC6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                : const Text("Change Password"),
          ),
        ],
      ),
    );
  }
}
