import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Define your color scheme (consistent with Login/Register screens)
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color backgroundColor = Colors.black;
  static const Color textColor = Colors.white;

  @override
  void initState() {
    super.initState();
    // Navigate after a slightly longer delay to show the loading animation
    Future.delayed(const Duration(milliseconds: 2500), () { 
      if (!mounted) return;
      context.go('/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine the size for spacing and scaling
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. The Main App Logo/Name
            const Text(
              'Eventra',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w600, // Slightly lighter than bold
                color: textColor,
                letterSpacing: 1.5,
              ),
            ),
            
            SizedBox(height: screenHeight * 0.15), 
            
            SizedBox(
              width: 150, 
              child: LinearProgressIndicator(
                backgroundColor: primaryPink.withOpacity(0.3), 
                valueColor: const AlwaysStoppedAnimation<Color>(primaryPink), 
                minHeight: 4.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}