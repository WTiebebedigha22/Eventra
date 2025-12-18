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
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color backgroundColor = Colors.black;
  static const Color appBarColor = Color(0xFF181818); 
  static const Color inputFillColor = Color(0xFF121212); 
  static const Color textColor = Colors.white;

  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      // Load existing data
      _usernameController.text = auth.currentUserFullName;
      _firstNameController.text = auth.currentUserFirstName;
      _lastNameController.text = auth.currentUserLastName;
      _bioController.text = auth.currentBio;
      _selectedDateOfBirth = auth.currentUserDOB;

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

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000),
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

  Widget _buildTextField(
      TextEditingController controller, String labelText, {
        int maxLines = 1,
        bool readOnly = false,
        String? initialValue,
      }) {
    return TextField(
      controller: controller..text = initialValue ?? controller.text,
      readOnly: readOnly,
      maxLines: maxLines,
      style: TextStyle(color: readOnly ? textColor.withOpacity(0.5) : textColor),
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

  Future<void> _saveProfile(BuildContext context, AuthProvider auth) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving profile...'),
          backgroundColor: primaryPink,
          duration: Duration(seconds: 1),
        ),
      );

      await auth.updateProfile(
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        bio: _bioController.text.trim(),
        dob: _selectedDateOfBirth,
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
    final initialLetter = auth.currentUserFullName.isNotEmpty
        ? auth.currentUserFullName[0].toUpperCase()
        : email[0].toUpperCase();
    final photoUrl = auth.profilePhotoUrl; 

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
            onPressed: auth.isLoading ? null : () => _saveProfile(context, auth),
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
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Email read-only
            _buildTextField(_usernameController, 'Email (Read-only)',
                readOnly: true, initialValue: email),
            const SizedBox(height: 20),

            // Username
            _buildTextField(_usernameController, 'Username'),
            const SizedBox(height: 20),

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

            GestureDetector(
              onTap: auth.isLoading ? null : () => _selectDateOfBirth(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: inputFillColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: primaryPink.withOpacity(0.5), 
                    width: (_selectedDateOfBirth != null) ? 2.0 : 0.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: primaryPink),
                    const SizedBox(width: 10),
                    Text(
                      dobText,
                      style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildTextField(_bioController, 'Bio', maxLines: 4),
            const SizedBox(height: 30),

            TextButton(
              onPressed: auth.isLoading ? null : () {
                context.push('/settings/security'); 
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