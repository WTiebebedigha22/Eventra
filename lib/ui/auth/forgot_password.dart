import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();

  // --- Theme Colors (Aligned with Modern Light Style) ---
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Colors.white;
  static const Color inputFillColor = Color(0xFFF8F9FA); 
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Widget _buildTextField() {
    return TextField(
      controller: email,
      style: const TextStyle(color: textColor, fontSize: 16),
      cursorColor: primaryColor,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: 'Email address',
        hintStyle: TextStyle(color: subtleText.withOpacity(0.4)),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      // Added AppBar for a standard "Back" experience
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Header Section ---
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/logo/app_logo.png',
                      height: 80,
                      errorBuilder: (c, e, s) => const Icon(Icons.lock_reset_rounded, size: 80, color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Password Reset',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enter your email address and we\'ll send you instructions to reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: subtleText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              _buildTextField(),

              const SizedBox(height: 32),

              // --- Action Button ---
              ElevatedButton(
                onPressed: auth.isLoading ? null : () async {
                  final emailText = email.text.trim();
                  if (emailText.isEmpty) {
                    _showSnackBar('Please enter your email address');
                    return;
                  }

                  try {
                    await auth.forgotPassword(emailText);
                    if (mounted) {
                      _showSnackBar('Password reset email sent!', isError: false);
                      context.go('/login');
                    }
                  } catch (e) {
                    if (mounted) _showSnackBar(e.toString());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Send Reset Link',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'Remember your password? Log in',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}