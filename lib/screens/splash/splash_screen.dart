import 'dart:async';
import 'package:flutter/material.dart';
import '../role/choose_role_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // تعمل على Android + Chrome بدون مشاكل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChooseRoleScreen()),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EDF7), // لون ناعم (من الباليت)
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // لو عندك لوجو، ضيفيه هون
            Icon(Icons.qr_code_2, size: 100, color: Colors.deepPurple),

            const SizedBox(height: 20),

            const Text(
              "Welcome to",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w300,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              "QR Authenticator",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 25),

            const CircularProgressIndicator(
              color: Colors.deepPurple,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
