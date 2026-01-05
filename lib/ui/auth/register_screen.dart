import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final username = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final confirmPass = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool agreedToTerms = false;
  String? selectedGender;

  static const Color backgroundColor = Colors.black;
  static const Color inputFillColor = Color(0xFF1C1C1E);
  static const Color primaryColor = Colors.white;
  static const Color secondaryText = Colors.white70;

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    username.dispose();
    email.dispose();
    pass.dispose();
    confirmPass.dispose();
    super.dispose();
  }

  // --- Logic: Random Username Generator ---
  void _generateUsername() {
    final adjectives = ['Cool', 'Swift', 'Bright', 'Neon', 'Urban', 'Wild', 'Silent'];
    final nouns = ['Vibes', 'User', 'Pulse', 'Star', 'Quest', 'Soul', 'Gamer'];
    final random = Random();
    
    setState(() {
      username.text = 
        '${adjectives[random.nextInt(adjectives.length)]}${nouns[random.nextInt(nouns.length)]}${random.nextInt(999)}';
    });
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    VoidCallback? onToggleVisibility,
    bool? isObscured,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: primaryColor),
      cursorColor: primaryColor,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: secondaryText),
        filled: true,
        fillColor: inputFillColor,
        suffixIcon: suffixIcon ?? (onToggleVisibility != null
            ? IconButton(
                icon: Icon(
                  isObscured! ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: secondaryText,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
            : null),
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
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Join Ventra',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 30),

                // Name Row
                Row(
                  children: [
                    Expanded(child: _buildTextField(firstName, 'First Name')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(lastName, 'Last Name')),
                  ],
                ),
                const SizedBox(height: 14),

                // Username with Generator Button
                _buildTextField(
                  username, 
                  'Username',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                    onPressed: _generateUsername,
                    tooltip: 'Generate random username',
                  ),
                ),
                const SizedBox(height: 14),

                // Gender Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: inputFillColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedGender,
                      hint: const Text('Select Gender', style: TextStyle(color: secondaryText)),
                      dropdownColor: inputFillColor,
                      icon: const Icon(Icons.keyboard_arrow_down, color: secondaryText),
                      isExpanded: true,
                      items: ['Male', 'Female', 'Non-binary', 'Prefer not to say']
                          .map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g, style: const TextStyle(color: primaryColor)),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => selectedGender = val),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                _buildTextField(email, 'Email address'),
                const SizedBox(height: 14),

                // Password with Visibility Toggle
                _buildTextField(
                  pass, 
                  'Password', 
                  obscure: _obscurePass,
                  isObscured: _obscurePass,
                  onToggleVisibility: () => setState(() => _obscurePass = !_obscurePass),
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  confirmPass, 
                  'Confirm Password', 
                  obscure: _obscureConfirm,
                  isObscured: _obscureConfirm,
                  onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),

                const SizedBox(height: 18),

                // Terms
                Row(
                  children: [
                    Checkbox(
                      value: agreedToTerms,
                      onChanged: (value) => setState(() => agreedToTerms = value ?? false),
                      activeColor: Colors.blueAccent,
                      checkColor: Colors.white,
                    ),
                    const Expanded(
                      child: Text(
                        'I agree to the Terms & Privacy Policy',
                        style: TextStyle(color: secondaryText, fontSize: 13),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () async {
                    if (!agreedToTerms || selectedGender == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please complete all fields and accept terms')),
                      );
                      return;
                    }

                    if (pass.text != confirmPass.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Passwords do not match')),
                      );
                      return;
                    }

                    await auth.signup(
                      email: email.text.trim(),
                      password: pass.text.trim(),
                      userData: {
                        'firstName': firstName.text.trim(),
                        'lastName': lastName.text.trim(),
                        'username': username.text.trim(),
                        'gender': selectedGender,
                      }
                    );

                    if (auth.isLoggedIn && mounted) context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Create Account', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Log in', style: TextStyle(color: secondaryText)),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}