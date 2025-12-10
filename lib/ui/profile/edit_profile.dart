import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; 
import '../../providers/auth_provider.dart'; 

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

  // --- 💡 UPDATED CONTROLLERS ---
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController(); // NEW
  final _lastNameController = TextEditingController(); // NEW
  final _bioController = TextEditingController();
  
  // State for Date of Birth
  DateTime? _selectedDateOfBirth; // NEW: Holds the actual DateTime object

  // 💡 Real Image Picker instance
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    // Use `WidgetsBinding.instance.addPostFrameCallback` to access Provider safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      
      // Load existing data
      _usernameController.text = auth.currentUserName; 
      _firstNameController.text = auth.currentUserFirstName; // ASSUME: Provider has this field
      _lastNameController.text = auth.currentUserLastName;  // ASSUME: Provider has this field
      _bioController.text = auth.currentBio;
          
      // Load DOB
      _selectedDateOfBirth = auth.currentUserDOB; // ASSUME: Provider has this field as DateTime?
      
      // Force UI update if DOB was loaded
      setState(() {}); 
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // --- Photo Upload Logic (Unchanged) ---
  Future<void> _pickAndUploadImage(AuthProvider auth) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading photo...'),
            backgroundColor: primaryPink,
            duration: Duration(seconds: 2),
          ),
        );
        
        final imageFile = File(image.path);
        await auth.uploadProfilePicture(imageFile);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Image upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // --- Date Picker Logic ---
  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000), // Default to a reasonable year
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: primaryPink,
              onPrimary: Colors.black,
              surface: appBarColor,
              onSurface: textColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primaryPink),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  // --- Widget for custom input field (Unchanged) ---
  Widget _buildTextField(
      TextEditingController controller, String labelText, {int maxLines = 1}) {
    final isReadOnly = labelText.contains('Read-only');
      
    return TextField(
      controller: controller,
      readOnly: isReadOnly, 
      maxLines: maxLines, // Allow multiline for bio
      style: TextStyle(color: isReadOnly ? textColor.withOpacity(0.5) : textColor),
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

  // --- Save Logic (UPDATED) ---
  Future<void> _saveProfile(BuildContext context, AuthProvider auth) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saving profile...'),
            backgroundColor: primaryPink,
            duration: Duration(seconds: 1),
          ),
      );

      // 💡 UPDATED CALL WITH NEW FIELDS
      await auth.updateProfile(
        username: _usernameController.text.trim(), 
        firstName: _firstNameController.text.trim(), // NEW
        lastName: _lastNameController.text.trim(),  // NEW
        bio: _bioController.text.trim(),
        dob: _selectedDateOfBirth,                // NEW
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      debugPrint('Profile save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final email = auth.currentUserEmail ?? 'Unknown';
    final initialLetter = auth.currentUserName.isNotEmpty ? auth.currentUserName[0].toUpperCase() : email[0].toUpperCase();
    final photoUrl = auth.profilePhotoUrl; 

    // Format DOB for display
    final dobText = _selectedDateOfBirth == null 
      ? 'Select Date of Birth' 
      : DateFormat.yMMMd().format(_selectedDateOfBirth!);

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
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: auth.isLoading 
                ? null 
                : () => _saveProfile(context, auth),
            child: Text(
              'Save',
              style: TextStyle(
                color: auth.isLoading ? primaryPink.withOpacity(0.5) : primaryPink,
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
            // --- 1. Avatar Editing Area (Unchanged) ---
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: appBarColor,
                    backgroundImage: 
                        photoUrl != null && photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl) as ImageProvider<Object>
                        : null,
                    child: photoUrl == null || photoUrl.isEmpty
                        ? Text(
                        initialLetter,
                        style: const TextStyle(color: primaryPink, fontSize: 40),
                      )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: auth.isLoading ? null : () => _pickAndUploadImage(auth),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: auth.isLoading ? Colors.grey : primaryPink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: auth.isLoading ? null : () => _pickAndUploadImage(auth),
                child: Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    color: auth.isLoading ? primaryPink.withOpacity(0.5) : primaryPink, 
                    fontSize: 16
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 30),

            // --- 2. Editable Fields (UPDATED) ---
            
            // Email (Read-only)
            _buildTextField(TextEditingController(text: email), 'Email (Read-only)'),
            const SizedBox(height: 20),
            
            // Username
            _buildTextField(_usernameController, 'Username'),
            const SizedBox(height: 20),

            // First Name and Last Name (Side-by-Side)
            Row(
              children: [
                Expanded(
                  child: _buildTextField(_firstNameController, 'First Name'), 
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(_lastNameController, 'Last Name'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Date of Birth Picker Field
            GestureDetector(
              onTap: auth.isLoading ? null : () => _selectDateOfBirth(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: inputFillColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: primaryPink.withOpacity(0.5), 
                    width: 
                        (_selectedDateOfBirth != null) ? 2.0 : 0.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: primaryPink),
                    const SizedBox(width: 10),
                    Text(
                      dobText,
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Bio (Changed to multiline)
            _buildTextField(_bioController, 'Bio', maxLines: 4), // 💡 Set maxLines
            const SizedBox(height: 30),
            
            // Optional: Link to Change Password Screen (Unchanged)
            TextButton(
              onPressed: auth.isLoading ? null : () {
                context.push('/settings/security'); 
              },
              child: Text(
                'Change Password',
                style: TextStyle(
                  color: textColor.withOpacity(0.7)
                ),
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}

