import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart'; 

// --- Color Palette from HomeScreen ---
const Color primaryPink = Color(0xFFE91E63);
const Color backgroundColor = Colors.black;
const Color appBarColor = Color(0xFF181818);
const Color textColor = Colors.white;
const Color hintColor = Colors.white54;
const Color darkSurface = Color(0xFF242424);

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  // 💡 NEW: Define the static route for the tagging sub-screen
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
  bool _isPosting = false; // New state to manage loading

  bool get _isPostButtonEnabled => (_contentController.text.isNotEmpty || _selectedMedia != null) && !_isPosting;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_updateState);
  }

  @override
  void dispose() {
    _contentController.removeListener(_updateState);
    _contentController.dispose();
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  // --- Image Picker Logic ---
  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedMedia = File(pickedFile.path);
      });
    }
  }
  
  // --- Enhanced Feature: Feeling Picker ---
  Future<void> _pickFeeling() async {
    final newFeeling = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FeelingPickerSheet(),
    );

    if (newFeeling != null) {
      setState(() {
        _selectedFeeling = newFeeling;
      });
    }
  }

  // --- Enhanced Feature: Event Date Picker ---
  Future<void> _pickEventDate() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: primaryPink, // Pink header/button color
              onPrimary: textColor,
              surface: appBarColor, // Dark background for the picker
              onSurface: textColor,
            ),
            dialogBackgroundColor: appBarColor,
          ),
          child: child!,
        );
      }
    );

    if (date != null) {
      setState(() {
        _eventDate = date;
      });
    }
  }

  // --- Enhanced Feature: Location Picker (Placeholder) ---
  void _pickLocation() {
    // In a real app, this would use a package like geolocator/google_maps_flutter
    // and potentially save GeoPoint data to Firestore.
    setState(() {
      _location = 'Ventra Hub, Downtown'; // Placeholder location
    });
  }

  // --- Post Submission Logic ---
  Future<void> _submitPost() async {
    if (!_isPostButtonEnabled) return;

    setState(() {
      _isPosting = true; // Start loading
    });

    try {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      
      // Combine content with feeling/event/location for a richer post, 
      // although these are also sent as separate fields to the PostProvider.
      String finalContent = _contentController.text.trim();
      if (_selectedFeeling != null) {
        finalContent = 'Feeling $_selectedFeeling - $finalContent';
      }

      await postProvider.createPost(
        content: finalContent,
        mediaFile: _selectedMedia,
        eventDate: _eventDate,
        location: _location,
      );

      // Successfully posted, navigate back
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post: ${e.toString()}'),
            backgroundColor: primaryPink,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false; // Stop loading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildUserInfoHeader(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContentInput(),

                  if (_selectedMedia != null) 
                    const SizedBox(height: 16),
                    _buildMediaPreview(),
                  
                  const SizedBox(height: 16),

                  // Display added details clearly below the input area
                  _buildExtraDetailsDisplay(),
                ],
              ),
            ),
          ),
          
          _buildDockedActions(),
        ],
      ),
    );
  }
  
  // --- Widgets ---

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: appBarColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: textColor),
        onPressed: () => context.pop(),
      ),
      title: const Text('Create Post', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextButton(
            onPressed: _isPostButtonEnabled ? _submitPost : null,
            style: TextButton.styleFrom(
              backgroundColor: _isPostButtonEnabled ? primaryPink : primaryPink.withOpacity(0.3),
              foregroundColor: textColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _isPosting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: textColor,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildExtraDetailsDisplay() {
    final details = <Widget>[];

    if (_selectedFeeling != null) {
      details.add(_buildDetailChip(
        icon: Icons.sentiment_satisfied_alt, 
        label: 'Feeling $_selectedFeeling',
        onRemove: () => setState(() => _selectedFeeling = null),
      ));
    }
    
    if (_location != null) {
      details.add(_buildDetailChip(
        icon: Icons.location_on, 
        label: _location!,
        onRemove: () => setState(() => _location = null),
      ));
    }

    if (_eventDate != null) {
      details.add(_buildDetailChip(
        icon: Icons.event, 
        label: 'Event: ${MaterialLocalizations.of(context).formatShortDate(_eventDate!)}',
        onRemove: () => setState(() => _eventDate = null),
      ));
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Wrap(spacing: 8.0, runSpacing: 8.0, children: details),
    );
  }

  Widget _buildDetailChip({required IconData icon, required String label, required VoidCallback onRemove}) {
    return Chip(
      backgroundColor: darkSurface,
      label: Text(label, style: const TextStyle(color: textColor, fontSize: 14)),
      avatar: Icon(icon, color: primaryPink, size: 18),
      deleteIcon: const Icon(Icons.close, color: hintColor, size: 16),
      onDeleted: onRemove,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildUserInfoHeader() {
    // ... (No changes)
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: darkSurface,
            child: Icon(Icons.person, color: hintColor), 
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current User', 
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  _buildPrivacyButton(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPrivacyButton() {
    // ... (No changes)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        children: [
          Icon(Icons.public, color: hintColor, size: 14),
          SizedBox(width: 4),
          Text('Public', style: TextStyle(color: hintColor, fontSize: 12)),
          Icon(Icons.arrow_drop_down, color: hintColor, size: 16),
        ],
      ),
    );
  }

  Widget _buildContentInput() {
    // ... (No changes)
    return TextField(
      controller: _contentController,
      maxLines: null,
      style: const TextStyle(color: textColor, fontSize: 20),
      keyboardType: TextInputType.multiline,
      decoration: const InputDecoration(
        hintText: "What's on your mind?",
        hintStyle: TextStyle(color: hintColor, fontSize: 20),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        // The Preview Image
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.file(
            _selectedMedia!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
          ),
        ),
        
        // The Remove Button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedMedia = null;
              });
            },
            child: const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, color: textColor, size: 18),
            ),
          ),
        ),

        // Optional: Edit Icon
        Positioned(
          bottom: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.edit, color: textColor),
            onPressed: () {
              // TODO: Implement image editing feature (e.g., cropping)
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            )
          ),
        )
      ],
    );
  }

  Widget _buildDockedActions() {
    return Container(
      decoration: const BoxDecoration(
        color: appBarColor, 
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Additional Post Options Bar ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(Icons.photo_library, 'Photo/Video', _pickMedia),
                _buildActionButton(Icons.sentiment_satisfied_alt, 'Feeling', _pickFeeling), 
                _buildActionButton(Icons.event, 'Event', _pickEventDate), 
                _buildActionButton(Icons.location_on, 'Location', _pickLocation), 
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // --- Separator (like in Facebook) ---
          const Divider(color: Colors.white10, height: 1),
          
          // --- Tag People / More Options ---
          ListTile(
            leading: const Icon(Icons.person_add_alt_1, color: primaryPink),
            title: const Text('Tag people', style: TextStyle(color: textColor)),
            trailing: const Icon(Icons.arrow_forward_ios, color: hintColor, size: 16),
            onTap: () {
              // 💡 IMPLEMENTATION: Navigate to the tagging screen
              context.push(CreatePostScreen.tagPeopleRoute);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: primaryPink, size: 24),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: hintColor, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Helper Widget for Feeling Picker Bottom Sheet ---
class _FeelingPickerSheet extends StatelessWidget {
  final List<String> feelings = ['Happy', 'Excited', 'Tired', 'Blessed', 'Focused', 'Grateful'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: appBarColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How are you feeling?', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: feelings.map((feeling) => ActionChip(
              backgroundColor: darkSurface,
              label: Text(feeling, style: const TextStyle(color: textColor)),
              avatar: const Icon(Icons.star, color: primaryPink, size: 18),
              onPressed: () => Navigator.of(context).pop(feeling),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

