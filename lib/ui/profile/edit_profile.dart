import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Define your color scheme (consistent)
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color backgroundColor = Colors.black;
  static const Color appBarColor = Color(0xFF181818); 
  static const Color inputFillColor = Color(0xFF121212); 
  static const Color textColor = Colors.white;

  // Controllers for fields that can be edited
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController(); // 💡 NEW: Full Name Controller
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 💡 Fetch initial data (Placeholder logic)
    _usernameController.text = 'User_Eventra_X'; 
    _fullNameController.text = 'Alice Johnson'; // 💡 NEW: Initialize Full Name
    _bioController.text = 'Event Enthusiast | Exploring the city\'s best meetups.';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose(); // 💡 NEW: Dispose Full Name Controller
    _bioController.dispose();
    super.dispose();
  }
  
  // --- Widget for custom input field (Minimalist Style) ---
  Widget _buildTextField(
      TextEditingController controller, String labelText) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: textColor),
      cursorColor: primaryPink,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: textColor.withOpacity(0.5)),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryPink, width: 2.0),
        ),
      ),
    );
  }
  // --------------------------------------------------------

  // --- Save Logic ---
  Future<void> _saveProfile(BuildContext context, AuthProvider auth) async {
    // ... saving logic remains the same, but now you can also save _fullNameController.text
    // Example: await auth.updateProfile(_usernameController.text, _fullNameController.text, _bioController.text);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final email = auth.currentUserEmail ?? 'Unknown';
    final initialLetter = email[0].toUpperCase();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: textColor),
          onPressed: () => context.pop(), // Close/Cancel button
        ),
        actions: [
          // SAVE Button (Checkmark)
          TextButton(
            onPressed: () => _saveProfile(context, auth),
            child: const Text(
              'Save',
              style: TextStyle(
                color: primaryPink,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. Avatar Editing Area ---
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: appBarColor,
                    child: Text(
                      initialLetter,
                      style: const TextStyle(color: primaryPink, fontSize: 40),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: primaryPink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 10),
            
            // "Change Photo" link
            Center(
              child: TextButton(
                onPressed: () {
                  // Action: Open image picker
                },
                child: const Text(
                  'Change Profile Photo',
                  style: TextStyle(color: primaryPink, fontSize: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 30),

            // --- 2. Editable Fields ---
            // Email (Display only, as it's complex to change in Firebase)
            _buildTextField(TextEditingController(text: email), 'Email (Read-only)'),
            const SizedBox(height: 20),
            
            // Username
            _buildTextField(_usernameController, 'Username'),
            const SizedBox(height: 20),
            
            // 💡 NEW: Full Name Field
            _buildTextField(_fullNameController, 'Full Name'), 
            const SizedBox(height: 20),

            // Bio
            _buildTextField(_bioController, 'Bio'),
            const SizedBox(height: 20),
            
            // Optional: Link to Change Password Screen
            TextButton(
              onPressed: () {
                // Navigate to a dedicated ChangePasswordScreen
                context.push('/settings/security/change-password');
              },
              child: Text(
                'Change Password',
                style: TextStyle(color: textColor.withOpacity(0.7)),
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}
