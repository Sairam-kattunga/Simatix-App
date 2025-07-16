import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student_login_screen.dart';
import 'student_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');

    if (savedEmail != null && savedPassword != null) {
      try {
        // Try signing in silently
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: savedEmail, password: savedPassword);

        final uid = userCredential.user!.uid;

        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('uid', isEqualTo: uid)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final studentData = snapshot.docs.first.data() as Map<String, dynamic>;

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StudentHomeScreen(studentData: studentData),
            ),
          );
          return;
        }
      } catch (e) {
        // If auto login fails, clear saved credentials and go to login screen
        await prefs.remove('email');
        await prefs.remove('password');
      }
    }

    // No saved credentials or failed login => navigate to login screen
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
