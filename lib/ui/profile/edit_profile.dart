import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
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

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Use listen: false because we just want the initial values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      _emailController.text = auth.currentUserEmail ?? '';
      _usernameController.text = auth.displayName; 
      _firstNameController.text = auth.firstName; 
      _lastNameController.text = auth.lastName;
      _bioController.text = auth.bio;
      _selectedDateOfBirth = auth.dob;

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(AuthProvider auth) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading photo...'), backgroundColor: primaryPink),
        );

        await auth.uploadProfilePicture(File(image.path));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo updated!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleSave(AuthProvider auth) async {
    // Basic validation
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await auth.updateProfile(
        displayName: _usernameController.text.trim(), // FIXED: Added missing parameter
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        bio: _bioController.text.trim(),
        dob: _selectedDateOfBirth,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {int maxLines = 1, bool readOnly = false}) {
    return TextField(
      controller: controller,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryPink, width: 2.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use listen: true here (default) to show loading state
    final auth = Provider.of<AuthProvider>(context);
    final photoUrl = auth.photoURL;
    final initialLetter = auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        title: const Text('Edit Profile', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.close, color: textColor), onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: auth.isLoading ? null : () => _handleSave(auth),
            child: auth.isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryPink))
              : const Text(
                  'Save',
                  style: TextStyle(color: primaryPink, fontWeight: FontWeight.bold, fontSize: 16),
                ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildProfileImageHeader(auth, photoUrl, initialLetter),
            const SizedBox(height: 30),
            _buildTextField(_emailController, 'Email (Read-only)', readOnly: true),
            const SizedBox(height: 20),
            _buildTextField(_usernameController, 'Username'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildTextField(_firstNameController, 'First Name')),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(_lastNameController, 'Last Name')),
              ],
            ),
            const SizedBox(height: 20),
            _buildDatePicker(),
            const SizedBox(height: 20),
            _buildTextField(_bioController, 'Bio', maxLines: 4),
          ],
        ),
      ),
    );
  }

  // --- UI Helper Components ---

  Widget _buildProfileImageHeader(AuthProvider auth, String? photoUrl, String initialLetter) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: appBarColor,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(initialLetter, style: const TextStyle(color: primaryPink, fontSize: 40))
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _pickAndUploadImage(auth),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: primaryPink, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                  ),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => _pickAndUploadImage(auth),
            child: const Text('Change Photo', style: TextStyle(color: primaryPink)),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDateOfBirth ?? DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(primary: primaryPink, onPrimary: Colors.black, surface: appBarColor, onSurface: textColor),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) setState(() => _selectedDateOfBirth = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: inputFillColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _selectedDateOfBirth != null ? primaryPink : Colors.transparent, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: primaryPink),
            const SizedBox(width: 10),
            Text(
              _selectedDateOfBirth == null ? 'Select Date of Birth' : DateFormat.yMMMd().format(_selectedDateOfBirth!),
              style: TextStyle(color: textColor.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}