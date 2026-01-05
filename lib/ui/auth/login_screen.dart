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

  // Apple‑inspired dark UI (clean, minimal, premium)
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color backgroundColor = Colors.black;
  static const Color inputFillColor = Color(0xFF1C1C1E); // iOS dark field
  static const Color textColor = Colors.white;
  static const Color subtleText = Colors.white70;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText, {
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: textColor, fontSize: 16),
      cursorColor: primaryPink,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: subtleText),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // 🍎 Apple‑style logo area
                Column(
                  children: [
                    Image.asset(
                      'assets/logo/app_logo.png', // 🔥 add your logo here
                      height: 72,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sign in with your account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Welcome back',
                      style: TextStyle(fontSize: 14, color: subtleText),
                    ),
                  ],
                ),

                const SizedBox(height: 50),

                _buildTextField(email, 'Email'),
                const SizedBox(height: 16),
                _buildTextField(pass, 'Password', obscureText: true),

                const SizedBox(height: 30),

                // Apple‑style primary button
                ElevatedButton(
                  onPressed: () async {
                    if (auth.isLoading) return;
                    await auth.login(email.text.trim(), pass.text.trim());
                    if (auth.isLoggedIn && mounted) context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPink,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // Apple‑style subtle actions
                TextButton(
                  onPressed: () => context.go('/forgot-password'),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: subtleText, fontSize: 13),
                  ),
                ),

                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text(
                    'Create a new account here',
                    style: TextStyle(color: subtleText, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
