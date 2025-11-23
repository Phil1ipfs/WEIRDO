import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F0),
      appBar: AppBar(
        title: const Text(
          'Terms and Agreement',
          style: TextStyle(
            fontFamily: 'Sahitya',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFB36CC6),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms and Agreement',
              style: TextStyle(
                fontFamily: 'Sahitya',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB36CC6),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '''
Welcome to our application! By creating an account, you agree to the following terms and conditions:

1. **Account Responsibility**
   You are responsible for maintaining the confidentiality of your account credentials. Any actions taken using your account are your responsibility.

2. **Use of Service**
   The platform is provided for lawful purposes only. You must not use the application to engage in any activity that violates applicable laws or regulations.

3. **Data Privacy**
   We value your privacy. Personal information collected during registration will only be used for account creation, communication, and service improvement.

4. **Prohibited Conduct**
   You must not:
   - Attempt to hack, disrupt, or gain unauthorized access to any system.
   - Share offensive, false, or misleading information.
   - Impersonate another individual or organization.

5. **Account Termination**
   The administrators reserve the right to suspend or terminate accounts that violate these terms.

6. **Modifications**
   We may update these terms from time to time. Users will be notified of any major changes.

By continuing to register or use our services, you acknowledge that you have read, understood, and agree to be bound by these Terms and Agreement.
              ''',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Thank you for joining us!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
