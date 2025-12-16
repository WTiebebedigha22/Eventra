import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';

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
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildInstagramAppBar(),
      body: Column(
        children: [
          _buildUserHeader(),
          Expanded(child: _buildComposer()),
          _buildBottomActions(),
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
        onPressed: () => context.pop(),
      ),
      title: const Text('New Post', style: TextStyle(fontWeight: FontWeight.w600)),
      actions: [
        TextButton(
          onPressed: _isPostButtonEnabled ? _submitPost : null,
          child: _isPosting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Share', style: TextStyle(color: primaryPink)),
        ),
      ],
    );
  }

  // --- User Header (Instagram style) ---
  Widget _buildUserHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: const [
          CircleAvatar(radius: 20, backgroundColor: darkSurface),
          SizedBox(width: 12),
          Text('Current User', style: TextStyle(fontWeight: FontWeight.bold)),
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

          // --- Media Preview (Instagram-first) ---
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

          // --- Jiji-style Info Chips ---
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
      avatar: Icon(icon, size: 16, color: primaryPink),
      label: Text(label, style: const TextStyle(color: textColor)),
    );
  }

  // --- Bottom Action Bar (Jiji card feel) ---
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: appBarColor,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _action(Icons.photo, 'Media', _pickMedia),
          _action(Icons.person_add, 'Tag', () => context.push(CreatePostScreen.tagPeopleRoute)),
          _action(Icons.location_on, 'Location', () => setState(() => _location = 'Ventra Hub')),
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
          Icon(icon, color: primaryPink),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: hintColor)),
        ],
      ),
    );
  }
}
