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
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Colors.white;
  static const Color inputFillColor = Color(0xFFF5F6F9);
  static const Color textColor = Color(0xFF1C1E21);

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      _emailController.text = auth.currentUserEmail;
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
        maxWidth: 500, // Optimize image size before upload
      );

      if (image != null) {
        setState(() => _isUploadingPhoto = true);
        
        // This should update 'photoURL' in your Firestore document
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
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _handleSave(AuthProvider auth) async {
    if (_usernameController.text.trim().isEmpty) {
      _showError('Username cannot be empty');
      return;
    }

    try {
      await auth.updateProfile(
        displayName: _usernameController.text.trim(),
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
      _showError('Update failed: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final photoUrl = auth.photoURL;
    final initialLetter = (auth.displayName.isNotEmpty) ? auth.displayName[0].toUpperCase() : 'U';

    return Stack(
      children: [
        Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            centerTitle: true,
            title: const Text('Edit Profile', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            leading: IconButton(
              icon: const Icon(Icons.close, color: textColor), 
              onPressed: () => context.pop()
            ),
            actions: [
              TextButton(
                onPressed: (auth.isLoading || _isUploadingPhoto) ? null : () => _handleSave(auth),
                child: auth.isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))
                  : const Text('Save', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
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
        ),
        if (_isUploadingPhoto)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, {int maxLines = 1, bool readOnly = false}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      style: TextStyle(color: readOnly ? Colors.grey : textColor, fontSize: 15),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildProfileImageHeader(AuthProvider auth, String? photoUrl, String initialLetter) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor.withOpacity(0.1), width: 2),
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: primaryColor.withOpacity(0.05),
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Text(initialLetter, style: const TextStyle(color: primaryColor, fontSize: 40, fontWeight: FontWeight.bold))
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploadingPhoto ? null : () => _pickAndUploadImage(auth),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isUploadingPhoto ? null : () => _pickAndUploadImage(auth),
            child: const Text('Change Profile Photo', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
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
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: primaryColor, onPrimary: Colors.white, onSurface: textColor),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _selectedDateOfBirth = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: inputFillColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: primaryColor),
            const SizedBox(width: 12),
            Text(
              _selectedDateOfBirth == null ? 'Date of Birth' : DateFormat.yMMMd().format(_selectedDateOfBirth!),
              style: TextStyle(color: _selectedDateOfBirth == null ? Colors.grey : textColor, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}