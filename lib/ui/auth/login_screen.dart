import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool _obscurePass = true;

  static const Color primaryColor = Colors.deepPurple;
  static const Color backgroundColor = Colors.white;
  static const Color inputFillColor = Color(0xFFF8F9FA); 
  static const Color textColor = Color(0xFF1C1E21);     
  static const Color subtleText = Colors.black54;       

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
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: textColor, fontSize: 16),
      cursorColor: primaryColor,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: subtleText.withOpacity(0.5)),
        filled: true,
        fillColor: inputFillColor,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 48),

                _buildTextField(email, 'Email Address', keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildTextField(
                  pass,
                  'Password',
                  obscureText: _obscurePass,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: Colors.grey,
                      size: 22,
                    ),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Forgot Password?', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),

                // --- Main Login Button ---
                ElevatedButton(
                  onPressed: auth.isLoading ? null : () async {
                    try {
                      await auth.login(email: email.text.trim(), password: pass.text.trim());
                      if (auth.isLoggedIn && mounted) context.go('/home');
                    } catch (e) {
                      if (mounted) _showError(e.toString());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 32),
                _buildSeparator(),
                const SizedBox(height: 32),

                // --- 2. Google Button (Using FontAwesome) ---
                OutlinedButton.icon(
                  onPressed: auth.isLoading ? null : () async {
                    try {
                      await auth.signInWithGoogle();
                      if (auth.isLoggedIn && mounted) context.go('/home');
                    } catch (e) {
                      if (mounted) _showError("Google Sign-In failed: $e");
                    }
                  },
                  icon: const FaIcon(
                    FontAwesomeIcons.google,
                    color: Color(0xFFDB4437), // Brand Red
                    size: 18,
                  ),
                  label: auth.isLoading 
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Continue with Google", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                ),

                const SizedBox(height: 24),
                _buildRegisterLink(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets to keep build() clean ---

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: primaryColor.withOpacity(0.05), shape: BoxShape.circle),
          child: Image.asset('assets/logo/app_logo.png', height: 80, errorBuilder: (c, e, s) => const Icon(Icons.bolt, size: 80, color: primaryColor)),
        ),
        const SizedBox(height: 24),
        const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        const Text('Login to proceed to your account', style: TextStyle(fontSize: 15, color: subtleText)),
      ],
    );
  }

  Widget _buildSeparator() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("or", style: TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account?", style: TextStyle(color: subtleText)),
        TextButton(
          onPressed: () => context.push('/register'),
          child: const Text('Create one here', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }
}