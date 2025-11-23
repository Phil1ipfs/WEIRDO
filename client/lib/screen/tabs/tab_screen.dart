import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin/home_screen.dart';
// import 'admin/about_screen.dart';
import 'admin/article_screen.dart';
import 'admin/event_screen.dart';
import 'admin/doctor_screen.dart';
import 'admin/consultation_screen.dart';
import 'admin/profile_screen.dart';
import 'admin/client_screen.dart';

import 'client/client_home.dart';
import 'client/client_articles.dart';
import 'client/client_events.dart';
import 'client/client_consultation.dart';
import 'client/client_profile.dart';
import 'doctor/doctor_home.dart';
import 'doctor/doctor_events.dart';
import 'doctor/doctor_articles.dart';
import 'doctor/doctor_consultation.dart';
import 'doctor/doctor_profile.dart';
import 'doctor/doctor_patients.dart';
import 'doctor/doctor_availability.dart';

import '../../services/auth_service.dart';

class TabScreen extends StatefulWidget {
  const TabScreen({super.key});

  @override
  State<TabScreen> createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen> {
  int _selectedIndex = 0;
  List<String> _tabs = [];
  String _role = ''; // "client", "doctor", or "admin"

  @override
  void initState() {
    super.initState();
    _verifyAccountOnLoad();
  }

  Future<void> _verifyAccountOnLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print('No token found.');
      return;
    }

    final response = await AuthService.verifyAccount({'token': token});
    print("Verification result: $response");

    if (response['success'] == true) {
      final role = response['role'];
      final tabs = response['tabs'];

      if (role is String && tabs is List) {
        setState(() {
          _tabs = List<String>.from(tabs);
          _role = role;
        });
      } else {
        print(
          "Error: Invalid or missing 'role' or 'tabs'. Role: $role, Tabs: $tabs",
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Login Verified')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getPage(String tab, String role) {
    switch (role) {
      case 'grace':
        switch (tab) {
          case 'home':
            return const ClientHome();
          case 'events':
            return const ClientEvents();
          case 'articles':
            return const ClientArticles();
          case 'consultation':
            return const ClientConsultation();
          case 'profile':
            return const ClientProfile();
        }
        break;
      case 'janna':
        switch (tab) {
          case 'home':
            return const DoctorHome();
          case 'events':
            return const DoctorEvents();
          case 'articles':
            return const DoctorArticles();
          case 'consultation':
            return const DoctorConsultation();
          case 'profile':
            return const DoctorProfile();
          case 'patients':
            return const DoctorPatients();
          case 'availability':
            return const DoctorAvailabilityScreen();
        }
        break;
      case 'gwyneth':
        switch (tab) {
          case 'home':
            return const HomeScreen();
          case 'events':
            return const EventScreen();
          case 'articles':
            return const ArticleScreen();
          case 'messages':
            return const ConsultationScreen();
          case 'profile':
            return const ProfileScreen();
          case 'doctors':
            return const DoctorScreen();
          case 'clients':
            return const ClientScreen();
        }
        break;
    }

    return const Center(child: Text('Page not found'));
  }

  BottomNavigationBarItem _getNavItem(String tab) {
    IconData icon;
    switch (tab) {
      case 'home':
        icon = Icons.home;
        break;
      case 'events':
        icon = Icons.event;
        break;
      case 'articles':
        icon = Icons.article;
        break;
      case 'consultation':
        icon = Icons.chat;
        break;
      case 'messages':
        icon = Icons.message;
        break;
      case 'profile':
        icon = Icons.person;
        break;
      case 'patients':
        icon = Icons.group;
        break;
      case 'doctors':
        icon = Icons.medical_services;
        break;
      case 'clients':
        icon = Icons.people_alt;
        break;
      case 'availability':
        icon = Icons.schedule;
      default:
        icon = Icons.help;
    }

    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: tab[0].toUpperCase() + tab.substring(1),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabs.isEmpty || _role.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs.map((tab) => _getPage(tab, _role)).toList(),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: const Color(0xFFB36CC6),
          primaryColor: Colors.white,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          items: _tabs.map(_getNavItem).toList(),
        ),
      ),
    );
  }
}
