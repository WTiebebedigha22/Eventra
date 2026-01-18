import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // --- Styling Constants ---
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Colors.white; // Matching your Eventra theme
  static const Color textColor = Colors.black54;

  // --- Configuration for Animated GIF ---
  static const String appLogoGifPath = 'assets/logo/logo.gif'; 
  static const double logoSize = 200.0;

  @override
  void initState() {
    super.initState();
    _startAppFlow();
  }

  void _startAppFlow() {
    // 1. Duration should match the length of your GIF animation
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;

      // 2. Real-time Auth Check
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is logged in, sync them and go to Explore (Home)
        context.go('/explore'); 
      } else {
        // First-time user or logged out
        context.go('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. The Animated GIF
            Image.asset(
              appLogoGifPath,
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
            ),

            // 2. Branding Text
            const Padding(
              padding: EdgeInsets.only(top: 24.0),
              child: Text(
                'EVENTRA',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 6.0, // Wider spacing for "Premium" look
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.1),

            // 3. Elegant Progress Bar
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: primaryColor.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                minHeight: 2.0, // Thinner line looks more modern
              ),
            ),
          ],
        ),
      ),
    );
  }
}