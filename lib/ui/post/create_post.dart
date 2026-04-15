import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Internal Imports
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
  // --- Controllers & State ---
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  // Functional Update: Handle a list of media
  final List<File> _selectedMediaList = [];
  String? _location;
  DateTime? _eventDate;
  bool _isPosting = false;
  
  // 0 = Post, 1 = Event
  int _selectedType = 0; 

  // --- Category Logic ---
  String _selectedCategory = 'General'; 
  final List<String> _categories = [
    'General', 'Parties', 'Seminars', 'Tech', 'Art', 
    'Rentals', 'Workshops', 'Music', 'Sports', 'Food'
  ];

  // --- Theme Colors ---
  static const Color primaryColor = Colors.deepPurple;
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onTextChanged);
    _titleController.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // --- Validation ---
  bool get _isPostButtonEnabled {
    if (_isPosting) return false;
    if (_selectedType == 1) {
      return _titleController.text.trim().isNotEmpty && 
             _contentController.text.trim().isNotEmpty && 
             _eventDate != null;
    }
    return _contentController.text.trim().isNotEmpty || _selectedMediaList.isNotEmpty;
  }

  // --- Media & Interaction Logic ---
  Future<void> _pickMultiMedia() async {
    final picker = ImagePicker();
    final List<XFile> pickedList = await picker.pickMultiImage(imageQuality: 80);
    if (pickedList.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedMediaList.addAll(pickedList.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      HapticFeedback.mediumImpact();
      setState(() => _selectedMediaList.add(File(video.path)));
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) {
      HapticFeedback.mediumImpact();
      setState(() => _selectedMediaList.add(File(picked.path)));
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _eventDate = date);
  }

  // --- Submission Logic ---
  Future<void> _submit() async {
    if (!_isPostButtonEnabled) return;
    final auth = context.read<AuthProvider>();
    
    FocusScope.of(context).unfocus();
    setState(() => _isPosting = true);

    try {
      List<String> mediaUrls = [];
      for (var file in _selectedMediaList) {
        // Simple check: ImgBB doesn't take videos. 
        if (!file.path.toLowerCase().endsWith('.mp4')) {
          String? url = await ImgBBService.uploadImage(file);
          if (url != null) mediaUrls.add(url);
        }
      }

      if (_selectedType == 1) {
        await _createEventInFirebase(auth, mediaUrls.isNotEmpty ? mediaUrls.first : null);
      } else {
        await _createPostInProvider(auth, mediaUrls);
      }

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

  Future<void> _createPostInProvider(AuthProvider auth, List<String> urls) async {
    final postProvider = context.read<PostProvider>();
    final newPost = Post(
      id: '', 
      creatorId: auth.userId,
      username: auth.fullName.isEmpty ? 'User' : auth.fullName,
      userProfileUrl: auth.photoURL,
      content: _contentController.text.trim(),
      mediaUrl: urls.isNotEmpty ? urls.first : null,
      timestamp: DateTime.now(),
      likes: [],
      location: _location,
      category: 'General',
    );
    await postProvider.uploadPost(newPost);
  }

  Future<void> _createEventInFirebase(AuthProvider auth, String? mediaUrl) async {
    await FirebaseFirestore.instance.collection('events').add({
      'creatorId': auth.userId,
      'username': auth.fullName.isEmpty ? 'User' : auth.fullName,
      'userProfileUrl': auth.photoURL,
      'title': _titleController.text.trim(),
      'description': _contentController.text.trim(),
      'imageUrl': mediaUrl,
      'location': _location,
      'eventDate': Timestamp.fromDate(_eventDate!),
      'createdAt': FieldValue.serverTimestamp(),
      'category': _selectedCategory,
      'likes': [],
      'type': 'event',
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isEvent = _selectedType == 1;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: _buildTypeSelector(),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: _isPostButtonEnabled ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                disabledBackgroundColor: primaryColor.withOpacity(0.5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _isPosting 
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isEvent ? 'Create' : 'Post', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 24),
                
                if (isEvent) ...[
                  const Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: subtleText)),
                  const SizedBox(height: 12),
                  _buildCategoryPicker(),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                    decoration: const InputDecoration(
                      hintText: "Event Name",
                      hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(height: 32),
                ],

                _buildComposer(isEvent),
              ],
            ),
          ),
          _buildToolbar(),
        ],
      ),
    );
  }

  // --- Original UI Components Restored ---

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(25)),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _typeButton("Post", 0),
          _typeButton("Event", 1),
        ],
      ),
    );
  }

  Widget _typeButton(String text, int index) {
    final isSelected = _selectedType == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? primaryColor : subtleText,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedCategory = cat),
              selectedColor: primaryColor,
              backgroundColor: Colors.grey[50],
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserHeader(AuthProvider auth) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundImage: auth.photoURL != null ? NetworkImage(auth.photoURL!) : null,
          child: auth.photoURL == null ? const Icon(Icons.person, color: primaryColor) : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(auth.fullName.isEmpty ? 'User' : auth.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(_selectedType == 1 ? "Creating an Event" : "Sharing a Post", style: const TextStyle(fontSize: 12, color: primaryColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildComposer(bool isEvent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _contentController,
          maxLines: null,
          style: const TextStyle(fontSize: 18, color: textColor, height: 1.5),
          decoration: InputDecoration(
            hintText: isEvent ? "Tell us more about the event..." : "What's on your mind?",
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: InputBorder.none,
          ),
        ),
        
        // Media Preview: Dynamic horizontal list
        if (_selectedMediaList.isNotEmpty)
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(vertical: 20),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedMediaList.length,
              itemBuilder: (context, index) => _buildMediaPreviewItem(index),
            ),
          ),

        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_location != null) _buildBadge(Icons.location_on_rounded, _location!, () => setState(() => _location = null)),
            if (_eventDate != null) _buildBadge(Icons.calendar_today_rounded, DateFormat('EEE, MMM d').format(_eventDate!), () => setState(() => _eventDate = null)),
            if (isEvent && _eventDate == null) _buildActionPrompt("Add Date", Icons.event, _pickEventDate),
            if (_location == null) _buildActionPrompt("Add Location", Icons.place, _pickLocation),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaPreviewItem(int index) {
    final file = _selectedMediaList[index];
    final bool isVideo = file.path.toLowerCase().endsWith('.mp4') || file.path.toLowerCase().endsWith('.mov');

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: isVideo 
              ? Container(color: Colors.black87, child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 40))
              : Image.file(file, fit: BoxFit.cover),
          ),
          Positioned(
            top: 5, right: 5,
            child: GestureDetector(
              onTap: () => setState(() => _selectedMediaList.removeAt(index)),
              child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primaryColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          GestureDetector(onTap: onRemove, child: const Icon(Icons.cancel, size: 16, color: primaryColor)),
        ],
      ),
    );
  }

  Widget _buildActionPrompt(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: subtleText),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: subtleText, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5))),
      child: Row(
        children: [
          _modernToolbarIcon(icon: Icons.image_rounded, onTap: _pickMultiMedia, label: "Photos"),
          const SizedBox(width: 12),
          _modernToolbarIcon(icon: Icons.videocam_rounded, onTap: _pickVideo, label: "Video"),
          const SizedBox(width: 12),
          _modernToolbarIcon(icon: Icons.location_on_rounded, onTap: _pickLocation, label: "Place"),
          const Spacer(),
          Container(
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: IconButton(onPressed: _takePhoto, icon: const Icon(Icons.camera_alt_rounded, color: primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _modernToolbarIcon({required IconData icon, required VoidCallback onTap, required String label}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 20),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}