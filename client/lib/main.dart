import 'package:flutter/material.dart';
import 'screen/login_screen.dart';
import 'screen/registration_screen.dart';
import 'screen/tabs/tab_screen.dart';
import 'screen/forgot_password_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Big Flutter App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(), // <-- Add this
        '/tabs': (context) => const TabScreen(),
        '/forgot-password': (context) =>
            const ForgotPasswordScreen(), // ✅ added
      },
    );
  }
}
