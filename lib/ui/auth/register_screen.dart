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

  // --- Theme Colors (Aligned with Login/Settings) ---
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Colors.white;
  static const Color inputFillColor = Color(0xFFF8F9FA); 
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: textColor, fontSize: 15),
      cursorColor: primaryColor,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: subtleText.withOpacity(0.4)),
        filled: true,
        fillColor: inputFillColor,
        suffixIcon: suffixIcon ?? (onToggleVisibility != null
            ? IconButton(
                icon: Icon(
                  isObscured! ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.grey,
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.05), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
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
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create Account',
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fill in your details to get started',
                style: TextStyle(color: subtleText, fontSize: 15),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(child: _buildTextField(firstName, 'First Name')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(lastName, 'Last Name')),
                ],
              ),
              const SizedBox(height: 14),

              _buildTextField(
                username, 
                'Username',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.auto_awesome, color: primaryColor, size: 18),
                  onPressed: _generateUsername,
                ),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                decoration: BoxDecoration(
                  color: inputFillColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withOpacity(0.05)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedGender,
                    hint: const Text('Select Gender', style: TextStyle(color: subtleText, fontSize: 15)),
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.keyboard_arrow_down, color: subtleText),
                    isExpanded: true,
                    items: ['Male', 'Female', 'Non-binary', 'Prefer not to say']
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g, style: const TextStyle(color: textColor)),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => selectedGender = val),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _buildTextField(email, 'Email address', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),

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

              const SizedBox(height: 14),

              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: agreedToTerms,
                      onChanged: (value) => setState(() => agreedToTerms = value ?? false),
                      activeColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'I agree to the Terms & Privacy Policy',
                      style: TextStyle(color: subtleText, fontSize: 13),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: auth.isLoading ? null : () async {
                  if (!agreedToTerms || selectedGender == null) {
                    _showSnackBar('Please complete all fields and accept terms');
                    return;
                  }
                  if (pass.text != confirmPass.text) {
                    _showSnackBar('Passwords do not match');
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
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: auth.isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?', style: TextStyle(color: subtleText)),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Log in', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}