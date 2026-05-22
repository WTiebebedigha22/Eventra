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

class _CreatePostScreenState extends State<CreatePostScreen> with SingleTickerProviderStateMixin {
  // --- Controllers & State ---
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final List<File> _selectedMediaList = [];
  String? _location;
  DateTime? _eventDate;
  bool _isPosting = false;
  
  // 0 = Post, 1 = Event
  int _selectedType = 0; 
  
  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // --- Category Logic ---
  String _selectedCategory = 'General'; 
  final List<String> _categories = [
    'General', 'Parties', 'Seminars', 'Tech', 'Art', 
    'Rentals', 'Workshops', 'Music', 'Sports', 'Food'
  ];

  // --- Theme Colors ---
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B85FF);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Color(0xFF7A7E8B);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onTextChanged);
    _titleController.addListener(_onTextChanged);
    _priceController.addListener(_onTextChanged);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _animationController.forward();
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // --- Validation ---
  bool get _isPostButtonEnabled {
    if (_isPosting) return false;
    if (_selectedType == 1) {
      return _titleController.text.trim().isNotEmpty && 
             _contentController.text.trim().isNotEmpty && 
             _priceController.text.trim().isNotEmpty &&
             _eventDate != null;
    }
    return _contentController.text.trim().isNotEmpty || _selectedMediaList.isNotEmpty;
  }

  // --- Media & Interaction Logic ---
  Future<void> _pickMultiMedia() async {
    try {
      final picker = ImagePicker();
      final List<XFile> pickedList = await picker.pickMultiImage(imageQuality: 80);
      if (pickedList.isNotEmpty) {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedMediaList.addAll(pickedList.map((x) => File(x.path)));
        });
      }
    } catch (e) {
      _showSnackBar('Error picking images: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        HapticFeedback.mediumImpact();
        setState(() => _selectedMediaList.add(File(video.path)));
      }
    } catch (e) {
      _showSnackBar('Error picking video: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (picked != null) {
        HapticFeedback.mediumImpact();
        setState(() => _selectedMediaList.add(File(picked.path)));
      }
    } catch (e) {
      _showSnackBar('Error taking photo: $e');
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _location = result);
    }
  }
  
  Future<void> _pickEventDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      HapticFeedback.lightImpact();
      setState(() => _eventDate = date);
    }
  }

  // --- Submission Logic ---
  Future<void> _submit() async {
    if (!_isPostButtonEnabled) return;
    
    final auth = context.read<AuthProvider>();
    if (auth.userId == null || auth.userId!.isEmpty) {
      _showSnackBar('Please log in to continue');
      return;
    }
    
    FocusScope.of(context).unfocus();
    setState(() => _isPosting = true);

    try {
      List<String> mediaUrls = [];
      for (var file in _selectedMediaList) {
        if (!file.path.toLowerCase().endsWith('.mp4') && 
            !file.path.toLowerCase().endsWith('.mov')) {
          String? url = await ImgBBService.uploadImage(file);
          if (url != null) mediaUrls.add(url);
        }
      }

      if (_selectedType == 1) {
        await _createEventInFirebase(auth, mediaUrls.isNotEmpty ? mediaUrls.first : null);
      } else {
        await _createPostInFirebase(auth, mediaUrls);
      }

      if (mounted) {
        _showSnackBar(
          _selectedType == 1 ? 'Event created successfully! 🎉' : 'Post shared successfully! ✨', 
          isError: false
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  // FIXED: Create post directly in Firestore
  Future<void> _createPostInFirebase(AuthProvider auth, List<String> urls) async {
    final postData = {
      'creatorId': auth.userId,
      'username': auth.fullName.isEmpty ? 'User' : auth.fullName,
      'userProfileUrl': auth.photoURL ?? '',
      'content': _contentController.text.trim(),
      'mediaUrl': urls.isNotEmpty ? urls.first : null,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
      'comments': [],
      'location': _location,
      'category': _selectedCategory,
      'type': 'post',
      'createdAt': FieldValue.serverTimestamp(),
    };
    
    await FirebaseFirestore.instance.collection('posts').add(postData);
  }

  Future<void> _createEventInFirebase(AuthProvider auth, String? mediaUrl) async {
    final eventData = {
      'creatorId': auth.userId,
      'username': auth.fullName.isEmpty ? 'User' : auth.fullName,
      'userProfileUrl': auth.photoURL ?? '',
      'title': _titleController.text.trim(),
      'description': _contentController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'imageUrl': mediaUrl,
      'location': _location ?? '',
      'eventDate': Timestamp.fromDate(_eventDate!),
      'createdAt': FieldValue.serverTimestamp(),
      'category': _selectedCategory,
      'likes': [],
      'comments': [],
      'type': 'event',
      'isActive': true,
    };
    
    await FirebaseFirestore.instance.collection('events').add(eventData);
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
          onPressed: () => _showDiscardDialog(),
        ),
        title: _buildTypeSelector(),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed: _isPostButtonEnabled ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: _isPosting 
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEvent ? 'Create' : 'Post', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildUserHeader(auth),
                    const SizedBox(height: 24),
                    
                    if (isEvent) ...[
                      _buildCategoryPicker(),
                      const SizedBox(height: 16),
                      _buildEventTitleField(),
                      const SizedBox(height: 12),
                      _buildPriceField(),
                      _buildDateTimePicker(),
                      const Divider(height: 32),
                    ],

                    _buildComposer(isEvent),
                  ],
                ),
              ),
              _buildToolbar(),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
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
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedType = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? primaryColor : subtleText,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Category",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: subtleText),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedCategory = cat),
                  selectedColor: primaryColor,
                  backgroundColor: Colors.grey.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : textColor,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventTitleField() {
    return TextField(
      controller: _titleController,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
      decoration: InputDecoration(
        hintText: "Event Name",
        hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      maxLength: 100,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
    );
  }

  Widget _buildPriceField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number_outlined, color: successColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: successColor),
              decoration: InputDecoration(
                hintText: "Ticket Price",
                hintStyle: TextStyle(color: successColor.withValues(alpha: 0.5), fontWeight: FontWeight.normal),
                border: InputBorder.none,
                prefixText: "₦ ",
                prefixStyle: const TextStyle(color: successColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          if (_priceController.text.isNotEmpty)
            GestureDetector(
              onTap: () => _priceController.clear(),
              child: Icon(Icons.close, size: 18, color: successColor.withValues(alpha: 0.5)),
            ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return GestureDetector(
      onTap: _pickEventDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: primaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _eventDate != null
                    ? DateFormat('EEEE, MMMM d, yyyy').format(_eventDate!)
                    : 'Select Event Date',
                style: TextStyle(
                  color: _eventDate != null ? textColor : subtleText,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: subtleText),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(AuthProvider auth) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1.5),
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundImage: auth.photoURL != null && auth.photoURL!.isNotEmpty 
                ? NetworkImage(auth.photoURL!) 
                : null,
            child: auth.photoURL == null || auth.photoURL!.isEmpty
                ? const Icon(Icons.person, color: primaryColor) 
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                auth.fullName.isEmpty ? 'User' : auth.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                _selectedType == 1 ? "Creating an Event" : "Sharing a Post",
                style: TextStyle(fontSize: 12, color: primaryColor),
              ),
            ],
          ),
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
          style: const TextStyle(fontSize: 16, color: textColor, height: 1.5),
          decoration: InputDecoration(
            hintText: isEvent ? "Tell us more about the event..." : "What's on your mind?",
            hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
            border: InputBorder.none,
          ),
        ),
        
        if (_selectedMediaList.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildMediaPreview(),
        ],

        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_location != null) 
              _buildBadge(Icons.location_on_rounded, _location!, () => setState(() => _location = null)),
            if (_eventDate != null) 
              _buildBadge(Icons.calendar_today_rounded, DateFormat('EEE, MMM d').format(_eventDate!), () => setState(() => _eventDate = null)),
            if (isEvent && _eventDate == null) 
              _buildActionPrompt("Add Date", Icons.event, _pickEventDate),
            if (_location == null) 
              _buildActionPrompt("Add Location", Icons.place, _pickLocation),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaPreview() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedMediaList.length,
        itemBuilder: (context, index) => _buildMediaPreviewItem(index),
      ),
    );
  }

  Widget _buildMediaPreviewItem(int index) {
    final file = _selectedMediaList[index];
    final bool isVideo = file.path.toLowerCase().endsWith('.mp4') || 
                         file.path.toLowerCase().endsWith('.mov');

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: isVideo 
              ? Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                  ),
                )
              : Image.file(file, fit: BoxFit.cover),
          ),
          Positioned(
            top: 5, right: 5,
            child: GestureDetector(
              onTap: () => setState(() => _selectedMediaList.removeAt(index)),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primaryColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.cancel, size: 16, color: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPrompt(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: subtleText),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: subtleText, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 0.5)),
      ),
      child: Row(
        children: [
          _buildToolbarIcon(icon: Icons.image_rounded, onTap: _pickMultiMedia, label: "Photos"),
          const SizedBox(width: 12),
          _buildToolbarIcon(icon: Icons.videocam_rounded, onTap: _pickVideo, label: "Video"),
          const SizedBox(width: 12),
          _buildToolbarIcon(icon: Icons.location_on_rounded, onTap: _pickLocation, label: "Place"),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt_rounded, color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarIcon({required IconData icon, required VoidCallback onTap, required String label}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 20),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showDiscardDialog() {
    if (_contentController.text.isNotEmpty || 
        _titleController.text.isNotEmpty || 
        _selectedMediaList.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Discard changes?'),
          content: const Text('You have unsaved changes. Are you sure you want to leave?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              child: const Text('Discard', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? errorColor : successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}