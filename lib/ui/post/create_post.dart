import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart'; // Import AuthProvider

const Color primaryPink = Color(0xFFE91E63);
const Color backgroundColor = Colors.black;
const Color appBarColor = Color(0xFF181818);
const Color textColor = Colors.white;
const Color hintColor = Colors.white54;
const Color darkSurface = Color(0xFF242424);

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  static const String tagPeopleRoute = '/create-post/tag-people';

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  File? _selectedMedia;
  String? _selectedFeeling;
  DateTime? _eventDate;
  String? _location;
  bool _isPosting = false;

  bool get _isPostButtonEnabled =>
      (_contentController.text.isNotEmpty || _selectedMedia != null) && !_isPosting;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedMedia = File(picked.path));
  }

  Future<void> _submitPost() async {
    if (!_isPostButtonEnabled) return;
    setState(() => _isPosting = true);

    try {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      await postProvider.createPost(
        content: _contentController.text.trim(),
        mediaFile: _selectedMedia,
        eventDate: _eventDate,
        location: _location,
      );
      if (mounted) context.go('/explore'); // Navigate back to the home branch
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildInstagramAppBar(),
      body: Column(
        children: [
          _buildUserHeader(authProvider), // Pass provider to header
          Expanded(child: _buildComposer()),
          
          // Use SafeArea to ensure bottom bar is not flush against the screen edge
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0), 
              child: _buildBottomActions(),
            ),
          ),
        ],
      ),
    );
  }

  // --- Instagram-like AppBar ---
  AppBar _buildInstagramAppBar() {
    return AppBar(
      backgroundColor: appBarColor,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.close, color: textColor),
        onPressed: () => context.go('/home_screen'), // Ensure it goes back to the home shell
      ),
      title: const Text('New Post', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: _isPostButtonEnabled ? _submitPost : null,
          child: _isPosting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: primaryPink),
                )
              : const Text('Share', 
                  style: TextStyle(color: primaryPink, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  // --- User Header (Shows logged-in user data) ---
  Widget _buildUserHeader(AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20, 
            backgroundColor: darkSurface,
            backgroundImage: auth.profilePhotoUrl != null 
                ? NetworkImage(auth.profilePhotoUrl!) 
                : null,
            child: auth.profilePhotoUrl == null 
                ? const Icon(Icons.person, color: hintColor) 
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            auth.currentUserFullName.isEmpty ? 'Loading...' : auth.currentUserFullName, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)
          ),
        ],
      ),
    );
  }

  // --- Main Composer ---
  Widget _buildComposer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _contentController,
            maxLines: null,
            style: const TextStyle(fontSize: 18, color: textColor),
            decoration: const InputDecoration(
              hintText: "What's on your mind?",
              hintStyle: TextStyle(color: hintColor),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 12),

          if (_selectedMedia != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.file(_selectedMedia!, width: double.infinity, height: 260, fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _selectedMedia = null),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            children: [
              if (_selectedFeeling != null) _infoChip(Icons.mood, _selectedFeeling!),
              if (_location != null) _infoChip(Icons.location_on, _location!),
              if (_eventDate != null)
                _infoChip(Icons.event, _eventDate!.toLocal().toString().split(' ')[0]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Chip(
      backgroundColor: darkSurface,
      side: BorderSide.none,
      avatar: Icon(icon, size: 16, color: primaryPink),
      label: Text(label, style: const TextStyle(color: textColor, fontSize: 12)),
    );
  }

  // --- Bottom Action Bar (Improved Spacing) ---
  Widget _buildBottomActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16), // Gives it a floating look
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: appBarColor,
        borderRadius: BorderRadius.circular(16), // Jiji/Figma rounded style
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _action(Icons.photo_library_outlined, 'Media', _pickMedia),
          _action(Icons.person_add_outlined, 'Tag', () => context.push(CreatePostScreen.tagPeopleRoute)),
          _action(Icons.location_on_outlined, 'Location', () => setState(() => _location = 'Ventra Hub')),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryPink, size: 28),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: hintColor)),
        ],
      ),
    );
  }
}