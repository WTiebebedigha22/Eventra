import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();

  // Define your color scheme (Spotify Dark Mode with Pink/Purple Accents)
  static const Color primaryPink = Color(0xFFE91E63); // Accent color
  static const Color secondaryPurple = Color(0xFF9C27B0); // Accent color
  static const Color backgroundColor = Colors.black; // Spotify-like dark background
  static const Color inputFillColor = Color(0xFF121212); // Slightly lighter dark for inputs
  static const Color textColor = Colors.white;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  // --- Widget for custom input field (Minimalist Style) ---
  Widget _buildTextField(
      TextEditingController controller, String hintText,
      {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: textColor),
      cursorColor: primaryPink,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        // Use minimal borders, relying on fill color for definition
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none, // No side borders initially
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: primaryPink, width: 2.0), // Pink highlight on focus
        ),
      ),
    );
  }
  // --------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Title Area
              const Icon(
                Icons.music_note,
                size: 80,
                color: primaryPink,
              ),
              const SizedBox(height: 10),
              const Text(
                'Log in to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 40),

              // Email Input
              _buildTextField(email, 'Email address'),
              const SizedBox(height: 15),

              // Password Input
              _buildTextField(pass, 'Password', obscureText: true),
              const SizedBox(height: 30),

              // Login Button (Gradient)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30), // Pill shape
                  gradient: const LinearGradient(
                    colors: [primaryPink, secondaryPurple],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    if (auth.isLoading) return;
                    await auth.login(email.text.trim(), pass.text.trim());
                    if (auth.isLoggedIn && mounted) context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black, // Dark indicator on bright button
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'LOG IN',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black), // Black text on bright button
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Register Button (TextButton - low visibility, high contrast)
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text(
                  'Don\'t have an account?',
                  style: TextStyle(color: textColor, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}