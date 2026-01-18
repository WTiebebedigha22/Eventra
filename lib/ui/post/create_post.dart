import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/posts/post.dart';
import '../../services/imgbb_service.dart';
import 'package:ventra/ui/post/location_picker.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();

  File? _selectedMedia;
  String? _location;
  DateTime? _eventDate;
  bool _isPosting = false;

  // --- Theme Colors ---
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

  bool get _isPostButtonEnabled =>
      (_contentController.text.trim().isNotEmpty || _selectedMedia != null) &&
      !_isPosting;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _contentController.removeListener(_onTextChanged);
    _contentController.dispose();
    super.dispose();
  }

  // --- Media & Interaction Logic ---
  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      HapticFeedback.lightImpact();
      setState(() => _selectedMedia = File(picked.path));
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );
    if (result != null) setState(() => _location = result);
  }
  
  Future<void> _pickEventDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) setState(() => _eventDate = date);
  }

  Future<void> _submitPost() async {
    if (!_isPostButtonEnabled) return;
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;
    
    FocusScope.of(context).unfocus();
    setState(() => _isPosting = true);

    try {
      final postProvider = context.read<PostProvider>();
      String? mediaUrl;

      if (_selectedMedia != null) {
        mediaUrl = await ImgBBService.uploadImage(_selectedMedia!);
      }

      final newPost = Post(
        id: '', 
        creatorId: auth.userId!,
        username: auth.fullName.isEmpty ? 'User' : auth.fullName,
        userProfileUrl: auth.photoURL,
        content: _contentController.text.trim(),
        mediaUrl: mediaUrl,
        timestamp: DateTime.now(),
        likes: [],
        location: _location,
        eventDate: _eventDate,
      );

      await postProvider.uploadPost(newPost);
      if (mounted) context.go('/home'); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent)
        );
      }
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
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: _isPostButtonEnabled ? _submitPost : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _isPosting 
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildUserHeader(auth),
                const SizedBox(height: 16),
                _buildComposer(),
              ],
            ),
          ),
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildUserHeader(AuthProvider auth) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[200],
          backgroundImage: auth.photoURL != null ? NetworkImage(auth.photoURL!) : null,
          child: auth.photoURL == null ? const Icon(Icons.person, color: Colors.grey) : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              auth.fullName.isEmpty ? 'User' : auth.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            const Text("Posting to Public", style: TextStyle(fontSize: 12, color: subtleText)),
          ],
        ),
      ],
    );
  }

  Widget _buildComposer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _contentController,
          maxLines: null,
          autofocus: true,
          style: const TextStyle(fontSize: 18, color: textColor, height: 1.5),
          decoration: InputDecoration(
            hintText: "What's happening?",
            hintStyle: TextStyle(color: subtleText.withOpacity(0.4)),
            border: InputBorder.none,
          ),
        ),
        const SizedBox(height: 16),
        
        // --- Selection Badges ---
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_location != null) _buildBadge(Icons.location_on_rounded, _location!, () => setState(() => _location = null)),
            if (_eventDate != null) _buildBadge(Icons.calendar_today_rounded, DateFormat('EEE, MMM d').format(_eventDate!), () => setState(() => _eventDate = null)),
          ],
        ),

        if (_selectedMedia != null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Image.file(_selectedMedia!, width: double.infinity, fit: BoxFit.fitWidth),
                  Positioned(
                    top: 12, right: 12,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMedia = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primaryColor),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          _toolbarIcon(Icons.image_outlined, _pickMedia),
          const SizedBox(width: 12),
          _toolbarIcon(Icons.location_on_outlined, _pickLocation),
          const SizedBox(width: 12),
          _toolbarIcon(Icons.calendar_today_outlined, _pickEventDate),
          const Spacer(),
          const Text("Drafts", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _toolbarIcon(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: primaryColor, size: 26),
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(8),
    );
  }
}