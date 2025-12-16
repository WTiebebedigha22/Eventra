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

  // --- Configuration for Asset Logo ---
  static const String appLogoAssetPath = 'assets/icon.png';
  static const double logoSize = 150.0; // Define a suitable size for your logo

  @override
  void initState() {
    super.initState();
    // Navigate after a slightly longer delay to show the loading animation
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      
      // IMPORTANT: Add your app startup logic here (e.g., check auth status)
      // For now, we navigate to the onboarding screen.
      // context.go(isAuthenticated ? '/home' : '/onboarding');
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
            // 1. The Main App Logo (Replaced Text with Image.asset)
            Image.asset(
              appLogoAssetPath,
              width: logoSize,
              height: logoSize,
              // If the asset is a simple graphic, you can use a color filter
              // to match your theme (optional):
              // color: textColor,
            ),

            // Optional: Keep the app name text below the logo
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                'Eventra',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.15),

            // 2. Linear Progress Indicator
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