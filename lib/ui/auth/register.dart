import 'package:flutter/material.dart';
import 'package:ventra/ui/auth/login.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Create Account', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: const RegisterForm(),
    );
  }
}

// --- Stateful Widget for Form Handling and Validation ---

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmpasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;

  // Pinterest's signature red color
  static const Color _pinterestRed = Colors.purpleAccent;

  void _submitRegistration() {
    if (_formKey.currentState!.validate()) {
      // Simulate registration process
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registering user: ${_emailController.text}')),
      );
      debugPrint('Name: ${_nameController.text}');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper widget for Pinterest-style input fields (reused from Login)
  Widget _buildPinterestInputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    required bool obscureText,
    required FormFieldValidator<String> validator,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Subtle background color
        borderRadius: BorderRadius.circular(10), // Rounded corners
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
          border: InputBorder.none, // Remove the default border
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _pinterestRed, width: 2), // Red focus border
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
    );
  }

  // Helper widget for Social Login Buttons (reused from Login)
  Widget _buildSocialLoginButton({required String text, required Color color, required IconData icon}) {
    return ElevatedButton.icon(
      onPressed: () {
        debugPrint('$text pressed');
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 0,
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Image.asset(
                'assets/icon.png',
                height: 60, 
              ),
              const SizedBox(height: 20.0),

              // 📝 Title
              const Text(
                'Join Eventra',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10.0),
              
              // ℹ️ Description
              const Text(
                'Find your next great idea.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40.0),

              _buildPinterestInputField(
                controller: _nameController,
                labelText: 'Username',
                hintText: 'Username',
                prefixIcon: Icons.person,
                obscureText: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15.0),

              // 📧 Email Text Field
              _buildPinterestInputField(
                controller: _emailController,
                labelText: 'Email',
                hintText: 'Email address',
                prefixIcon: Icons.email,
                obscureText: false,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15.0),

              // 🔑 Password Text Field
              _buildPinterestInputField(
                controller: _passwordController,
                labelText: 'Password',
                hintText: 'Create a password',
                prefixIcon: Icons.lock,
                obscureText: !_isPasswordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),


              const SizedBox(height: 15.0),

              // 🔑 Password Text Field
              _buildPinterestInputField(
                controller: _confirmpasswordController,
                labelText: 'Confirm Password',
                hintText: 'Type your password again.',
                prefixIcon: Icons.lock,
                obscureText: !_isPasswordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),

              const SizedBox(height: 30.0),

              // ➡️ Register Button
              ElevatedButton(
                onPressed: _submitRegistration,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.purpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0, // Flat design
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: 25.0),

              // OR Divider
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey, thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text('OR', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider(color: Colors.grey, thickness: 1)),
                ],
              ),
              
              const SizedBox(height: 25.0),

              // Google/Facebook Login
              _buildSocialLoginButton(
                text: 'Continue with Google',
                color: Colors.blue,
                icon: Icons.g_mobiledata, 
              ),
              const SizedBox(height: 10.0),
              _buildSocialLoginButton(
                text: 'Continue with Apple',
                color: const Color.fromARGB(255, 3, 3, 3), 
                icon: Icons.apple_rounded,
              ),

              const SizedBox(height: 40.0),

              // Login Link
              TextButton(
                onPressed: () {
                  // Navigate back to the Login Page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text(
                  "Already a member? Log in",
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: _pinterestRed
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}