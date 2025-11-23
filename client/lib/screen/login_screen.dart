// 0

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isChecking = true; // Show loader while checking token

  @override
  void initState() {
    super.initState();
    _checkSavedToken();
  }

  /// ✅ Checks for a stored token and verifies it
  Future<void> _checkSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      print('Found saved token: verifying...');
      final response = await AuthService.verifyAccount({'token': token});

      if (response['success'] == true) {
        print('Token valid — redirecting user back to the app');
        if (mounted) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/tabs');
          }
        }
        return;
      } else {
        print('Token invalid: ${response['message']}');
      }
    }

    // ✅ Stop loading state
    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  /// ✅ Handles login process
  void _login() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      final result = await AuthService.login(email, password);

      if (result['success']) {
        final token = result['token'];

        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Login successful!')));
          Navigator.pushReplacementNamed(context, '/tabs');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Login failed')),
          );
        }
      }
    }
  }

  /// ✅ Navigation helpers
  void _navigateToRegister() {
    Navigator.of(context).pushNamed('/register');
  }

  void _forgotPassword() {
    Navigator.of(context).pushNamed('/forgot-password');
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Defensive defaults (prevents null bool crash)
    final isChecking = _isChecking ?? true;
    final obscurePassword = _obscurePassword ?? true;

    // ✅ Show loader if checking saved token
    if (isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F4F0),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFB36CC6)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Logo
                Image.asset(
                  'assets/images/icon-logo.png',
                  height: 120,
                  width: 120,
                ),
                const SizedBox(height: 24),

                // ✅ Title
                const Text(
                  'Login here',
                  style: TextStyle(
                    fontFamily: 'Sahitya',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB36CC6),
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Already part of the vibe? Log in and show your true colors today.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 32),

                // ✅ Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ✅ Password Field with Show/Hide Toggle
                TextFormField(
                  controller: _passwordController,
                  obscureText: obscurePassword,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ✅ Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB36CC6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ Create Account Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _navigateToRegister,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFB36CC6)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    child: const Text(
                      'Create an Account',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
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
}
