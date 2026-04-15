import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

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
  late AnimationController _heartAnimationController;

  @override
  void initState() {
    super.initState();
    _postFuture = _loadData();
    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _loadData() async {
    final String id = widget.postId.trim();
    try {
      // Check posts first, then events
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('posts').doc(id).get();
      if (!doc.exists) {
        doc = await FirebaseFirestore.instance.collection('events').doc(id).get();
        if (doc.exists) setState(() => _activeCollection = 'events');
      }

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        _initializeMedia(data);
        return data;
      }
    } catch (e) {
      debugPrint("⚠️ Firestore Error: $e");
    }
    return null;
  }

  void _initializeMedia(Map<String, dynamic> data) {
    final String mediaUrl = data['imageUrl'] ?? data['mediaUrl'] ?? '';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
          }
          if (!snapshot.hasData) return const Center(child: Text("Content no longer available", style: TextStyle(color: Colors.white)));
          
          return _buildTikTokJijiBody(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildTikTokJijiBody(Map<String, dynamic> data) {
    final String media = data['imageUrl'] ?? data['mediaUrl'] ?? '';
    final String creatorId = data['userId'] ?? data['creatorId'] ?? '';
    final List likes = List.from(data['likes'] ?? []);
    final bool isLiked = likes.contains(currentUserId);
    final String price = data['price'] ?? "Contact for Price";

    return Stack(
      children: [
        // 1. FULLSCREEN MEDIA
        GestureDetector(
          onDoubleTap: () => _toggleLike(data),
          onTap: () {
            if (_videoController != null) {
              _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
              setState(() {});
            }
          },
          child: SizedBox.expand(
            child: _videoController != null && _videoController!.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  )
                : Image.network(
                    media, 
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white30, size: 50)),
                  ),
          ),
        ),

        // 2. SOFT GRADIENT OVERLAYS
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black],
                stops: [0, 0.15, 0.5, 0.95],
              ),
            ),
          ),
        ),

        // 3. RIGHT SIDEBAR
        Positioned(
          right: 12,
          bottom: 120,
          child: Column(
            children: [
              _buildSideAction(
                icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isLiked ? Colors.redAccent : Colors.white,
                label: "${likes.length}",
                onTap: () => _toggleLike(data),
              ),
              const SizedBox(height: 20),
              _buildSideAction(
                icon: Icons.chat_bubble_outline_rounded,
                label: "Comment",
                onTap: () {},
              ),
              const SizedBox(height: 20),
              _buildSideAction(
                icon: Icons.share_outlined,
                label: "Share",
                onTap: () => Share.share("Check this out on Ventra!"),
              ),
            ],
          ),
        ),

        // 4. BOTTOM INFO & JIJI CTA
        Positioned(
          left: 16,
          bottom: 30,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info - Clickable
              GestureDetector(
                onTap: () => context.push('/user/$creatorId'),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(creatorId).snapshots(),
                  builder: (context, userSnap) {
                    final u = userSnap.hasData ? (userSnap.data!.data() as Map<String, dynamic>?) : null;
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white24,
                          backgroundImage: u?['photoURL'] != null ? NetworkImage(u!['photoURL']) : null,
                        ),
                        const SizedBox(width: 10),
                        Text("@${u?['username'] ?? 'user'}", 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              
              // Content Row: Price + Description
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? '',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(data['description'] ?? data['content'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Price Badge (The "Jiji" Look)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3BA73A), // Jiji Green
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Modernized Jiji Action Button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3BA73A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {},
                      child: const Text("SHOW CONTACT", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white),
                      onPressed: () {},
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSideAction({required IconData icon, required String label, required VoidCallback onTap, Color color = Colors.white}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.1),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _toggleLike(Map<String, dynamic> data) async {
    if (currentUserId == null) return;
    
    final docRef = FirebaseFirestore.instance.collection(_activeCollection).doc(widget.postId.trim());
    List likes = List.from(data['likes'] ?? []);
    bool wasLiked = likes.contains(currentUserId);

    // OPTIMISTIC UPDATE: Update UI immediately
    setState(() {
      if (wasLiked) {
        likes.remove(currentUserId);
      } else {
        likes.add(currentUserId);
        HapticFeedback.mediumImpact();
      }
      data['likes'] = likes; // Locally update the data map
    });

    try {
      if (wasLiked) {
        await docRef.update({'likes': FieldValue.arrayRemove([currentUserId])});
      } else {
        await docRef.update({'likes': FieldValue.arrayUnion([currentUserId])});
      }
    } catch (e) {
      // Revert on error
      setState(() { _postFuture = _loadData(); });
    }
  }
}