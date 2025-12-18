import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ventra/ui/post/location_picker.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  static const String tagPeopleRoute = '/create-post/tag-people';

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();

  File? _selectedMedia;
  String? _location;
  DateTime? _eventDate;
  bool _isPosting = false;

  static const Color backgroundColor = Colors.black;
  static const Color appBarColor = Color(0xFF0E0E0E);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color textColor = Colors.white;
  static const Color hintColor = Colors.white54;

  bool get _isPostButtonEnabled =>
      (_contentController.text.trim().isNotEmpty || _selectedMedia != null) &&
      !_isPosting;

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
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _selectedMedia = File(picked.path));
  }

  // --- NEW: NAVIGATE TO LOCATION PICKER ---
  Future<void> _pickLocation() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );
    if (result != null) {
      setState(() => _location = result);
    }
  }

  Future<void> _submitPost() async {
    if (!_isPostButtonEnabled) return;
    setState(() => _isPosting = true);

    try {
      final postProvider = context.read<PostProvider>();
      await postProvider.createPost(
        content: _contentController.text.trim(),
        mediaFile: _selectedMedia,
        eventDate: _eventDate,
        location: _location,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post shared!'), backgroundColor: Colors.green),
      );
      context.go('/home/explore');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: const Text('New Post', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _isPostButtonEnabled ? _submitPost : null,
            child: _isPosting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryPink))
                : Text('Share', style: TextStyle(color: _isPostButtonEnabled ? primaryPink : hintColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildUserHeader(auth),
          Expanded(child: _buildComposer()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _buildBottomActions(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(AuthProvider auth) {
  final String displayName = auth.fullName.isNotEmpty ? auth.fullName : 'Guest';
  final String? photoUrl = auth.photoURL ?? auth.profilePhotoUrl;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: darkSurface,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? const Icon(Icons.person, color: hintColor)
              : null,
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            displayName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildComposer() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        TextField(
          controller: _contentController,
          maxLines: null,
          autofocus: true,
          style: const TextStyle(fontSize: 18, color: textColor),
          decoration: const InputDecoration(
            hintText: "What's on your mind?",
            hintStyle: TextStyle(color: hintColor),
            border: InputBorder.none,
          ),
        ),
        
        // --- VISUAL LOCATION BADGE ---
        if (_location != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryPink.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 14, color: primaryPink),
                  const SizedBox(width: 4),
                  Text(_location!, style: const TextStyle(color: primaryPink, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _location = null),
                    child: const Icon(Icons.cancel, size: 16, color: primaryPink),
                  ),
                ],
              ),
            ),
          ),

        if (_selectedMedia != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.file(_selectedMedia!, width: double.infinity, fit: BoxFit.fitWidth),
                Positioned(
                  top: 10, right: 10,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMedia = null),
                    child: const CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 15,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: appBarColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _action(Icons.image_outlined, 'Media', _pickMedia),
          _action(Icons.location_on_outlined, 'Location', _pickLocation), // Linked to picker
          _action(Icons.event_note_outlined, 'Event', () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) setState(() => _eventDate = date);
          }),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Icon(icon, color: primaryPink),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: hintColor, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}