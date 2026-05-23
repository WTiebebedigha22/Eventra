import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../components/comment_sheet.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>?> _postFuture;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  String _activeCollection = 'posts';
  VideoPlayerController? _videoController;
  bool _isSaved = false;

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color accentColor = Color(0xFFFF6B6B);

  @override
  void initState() {
    super.initState();
    _postFuture = _loadData();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _loadData() async {
    final String id = widget.postId.trim();
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('posts').doc(id).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        _initializeMedia(data);
        _checkIfSaved();
        return data;
      }
    } catch (e) {
      debugPrint("⚠️ Firestore Error: $e");
    }
    return null;
  }

  Future<void> _checkIfSaved() async {
    if (currentUserId == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('bookmarks')
        .doc(widget.postId)
        .get();
    if (mounted) {
      setState(() => _isSaved = doc.exists);
    }
  }

  void _initializeMedia(Map<String, dynamic> data) {
    final String mediaUrl = data['mediaUrl'] ?? data['imageUrl'] ?? '';
    final bool isVideo = data['isVideo'] == true || 
                         mediaUrl.toLowerCase().contains('.mp4') || 
                         mediaUrl.toLowerCase().contains('.mov');

    if (isVideo && mediaUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController?.play();
            _videoController?.setLooping(true);
          }
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2));
          }
          if (!snapshot.hasData) {
            return _buildErrorWidget();
          }
          return _buildPostBody(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            const Text(
              "Post no longer available",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostBody(Map<String, dynamic> data) {
    final String media = data['mediaUrl'] ?? data['imageUrl'] ?? '';
    final String creatorId = data['creatorId'] ?? data['userId'] ?? '';
    final List likes = List.from(data['likes'] ?? []);
    final bool isLiked = likes.contains(currentUserId);
    final int commentCount = data['commentCount'] ?? 0;
    final DateTime timestamp = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final String formattedDate = DateFormat('MMMM d, yyyy • h:mm a').format(timestamp);

    return Stack(
      children: [
        // 1. BACKGROUND MEDIA
        Positioned.fill(
          child: _videoController != null && _videoController!.value.isInitialized
              ? Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                )
              : media.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: media,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[900]),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.article, size: 64, color: Colors.grey),
                    ),
        ),

        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.2, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // 2. BACK BUTTON
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          child: _buildGlassButton(
            icon: Icons.arrow_back_ios_new,
            onPressed: () => context.pop(),
          ),
        ),

        // 3. RIGHT SIDE ACTION BUTTONS
        Positioned(
          right: 16,
          top: MediaQuery.of(context).padding.top + 10,
          child: _buildGlassButton(
            icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
            onPressed: () => _toggleSave(data),
          ),
        ),

        Positioned(
          right: 16,
          top: MediaQuery.of(context).size.height * 0.35,
          child: Column(
            children: [
              _buildActionButton(
                icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: _formatCount(likes.length),
                color: isLiked ? accentColor : Colors.white,
                onTap: () => _toggleLike(data),
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: _formatCount(commentCount),
                onTap: () => _showComments(),
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: "Share",
                onTap: () => _sharePost(data),
              ),
            ],
          ),
        ),

        // 4. BOTTOM INFO PANEL
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserHeader(creatorId),
                const SizedBox(height: 12),
                
                // Timestamp
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.white.withOpacity(0.6)),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Content
                Text(
                  data['content'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Category Chip
                if (data['category'] != null && data['category'].isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      data['category'],
                      style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onPressed}) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 22),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(String creatorId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(creatorId).snapshots(),
      builder: (context, userSnap) {
        final u = userSnap.hasData ? (userSnap.data!.data() as Map<String, dynamic>?) : null;
        return GestureDetector(
          onTap: () => context.push('/user/$creatorId'),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: u?['photoURL'] != null && u!['photoURL'].isNotEmpty
                    ? CachedNetworkImageProvider(u['photoURL'])
                    : null,
                backgroundColor: Colors.grey[800],
                child: u?['photoURL'] == null
                    ? const Icon(Icons.person, size: 20, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u?['displayName'] ?? u?['username'] ?? 'User',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    "@${u?['username'] ?? 'user'}",
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => CommentsScreen(
          postId: widget.postId,
          collection: 'posts',
        ),
      ),
    );
  }

  Future<void> _toggleSave(Map<String, dynamic> data) async {
    if (currentUserId == null) return;
    
    HapticFeedback.lightImpact();
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('bookmarks')
        .doc(widget.postId);

    if (_isSaved) {
      await ref.delete();
      setState(() => _isSaved = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from saved'), duration: Duration(seconds: 1)),
      );
    } else {
      await ref.set({
        'id': widget.postId,
        'title': data['content']?.substring(0, data['content'].length > 50 ? 50 : data['content'].length) ?? 'Post',
        'imageUrl': data['mediaUrl'] ?? data['imageUrl'],
        'type': 'post',
        'savedAt': FieldValue.serverTimestamp(),
      });
      setState(() => _isSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to bookmarks'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _toggleLike(Map<String, dynamic> data) async {
    if (currentUserId == null) return;
    
    final docRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId.trim());
    List likes = List.from(data['likes'] ?? []);
    bool wasLiked = likes.contains(currentUserId);

    HapticFeedback.lightImpact();
    setState(() {
      if (wasLiked) {
        likes.remove(currentUserId);
      } else {
        likes.add(currentUserId);
      }
      data['likes'] = likes;
    });

    try {
      if (wasLiked) {
        await docRef.update({'likes': FieldValue.arrayRemove([currentUserId])});
      } else {
        await docRef.update({'likes': FieldValue.arrayUnion([currentUserId])});
      }
    } catch (e) {
      _loadData();
    }
  }

  void _sharePost(Map<String, dynamic> data) {
    Share.share(
      '📝 Check out this post on Eventra!\n\n'
      '"${data['content'] ?? ''}"\n\n'
      'Posted by ${data['username'] ?? 'a user'}',
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}