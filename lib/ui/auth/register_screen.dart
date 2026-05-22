import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
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
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Updated theme colors to match the app
  static const Color primaryColor = Color(0xFF6C63FF); // Deep Purple Accent
  static const Color backgroundColor = Colors.white;
  static const Color inputFillColor = Color(0xFFF8F9FA);
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Color(0xFF7A7E8B);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    username.dispose();
    email.dispose();
    pass.dispose();
    confirmPass.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _generateUsername() {
    final adjectives = ['Cool', 'Swift', 'Bright', 'Neon', 'Urban', 'Wild', 'Silent', 'Epic', 'Rapid', 'Smart'];
    final nouns = ['Vibes', 'User', 'Pulse', 'Star', 'Quest', 'Soul', 'Gamer', 'Creator', 'Wanderer'];
    final random = Random();
    
    HapticFeedback.lightImpact();
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
    TextInputAction textInputAction = TextInputAction.next,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hint,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: const TextStyle(color: textColor, fontSize: 15),
          cursorColor: primaryColor,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: subtleText.withValues(alpha: 0.5)),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: errorColor, width: 1),
            ),
            errorText: errorText,
          ),
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value != pass.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleSignUp(AuthProvider auth) async {
    // Validation
    if (firstName.text.trim().isEmpty) {
      _showSnackBar('Please enter your first name');
      return;
    }
    if (lastName.text.trim().isEmpty) {
      _showSnackBar('Please enter your last name');
      return;
    }
    if (username.text.trim().isEmpty) {
      _showSnackBar('Please enter a username');
      return;
    }
    if (email.text.trim().isEmpty) {
      _showSnackBar('Please enter your email');
      return;
    }
    if (pass.text.isEmpty) {
      _showSnackBar('Please enter a password');
      return;
    }
    if (pass.text != confirmPass.text) {
      _showSnackBar('Passwords do not match');
      return;
    }
    if (pass.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return;
    }
    if (selectedGender == null) {
      _showSnackBar('Please select your gender');
      return;
    }
    if (!agreedToTerms) {
      _showSnackBar('Please agree to the Terms & Privacy Policy');
      return;
    }

    FocusScope.of(context).unfocus();
    
    try {
      await auth.signup(
        email: email.text.trim(),
        password: pass.text.trim(),
        userData: {
          'firstName': firstName.text.trim(),
          'lastName': lastName.text.trim(),
          'displayName': '${firstName.text.trim()} ${lastName.text.trim()}',
          'username': username.text.trim(),
          'gender': selectedGender,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      if (auth.isLoggedIn && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! 🎉'),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildFormFields(),
                  const SizedBox(height: 20),
                  _buildTermsCheckbox(),
                  const SizedBox(height: 24),
                  _buildSignUpButton(auth),
                  const SizedBox(height: 16),
                  _buildLoginLink(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 4,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Fill in your details to get started',
          style: TextStyle(
            color: subtleText,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
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
              tooltip: 'Generate username',
            ),
          ),
          const SizedBox(height: 14),
          _buildGenderDropdown(),
          const SizedBox(height: 14),
          _buildTextField(
            email,
            'Email Address',
            keyboardType: TextInputType.emailAddress,
            errorText: _validateEmail(email.text),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            pass,
            'Password',
            obscure: _obscurePass,
            isObscured: _obscurePass,
            onToggleVisibility: () => setState(() => _obscurePass = !_obscurePass),
            errorText: _validatePassword(pass.text),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            confirmPass,
            'Confirm Password',
            obscure: _obscureConfirm,
            isObscured: _obscureConfirm,
            onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
            errorText: _validateConfirmPassword(confirmPass.text),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: inputFillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedGender,
              hint: const Text(
                'Select Gender',
                style: TextStyle(color: subtleText, fontSize: 15),
              ),
              dropdownColor: Colors.white,
              icon: Icon(Icons.keyboard_arrow_down, color: subtleText),
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
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: agreedToTerms,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() => agreedToTerms = value ?? false);
            },
            activeColor: primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: subtleText, fontSize: 13),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton(AuthProvider auth) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      child: ElevatedButton(
        onPressed: auth.isLoading ? null : () => _handleSignUp(auth),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
        ),
        child: auth.isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                'Create Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account?', style: TextStyle(color: subtleText)),
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.go('/login');
          },
          child: const Text(
            'Log in',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}