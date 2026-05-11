import 'dart:ui'; // Required for ImageFilter
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
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
          }
          if (!snapshot.hasData) return const Center(child: Text("Content no longer available", style: TextStyle(color: Colors.white)));
          
          return _buildImmersiveBody(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildImmersiveBody(Map<String, dynamic> data) {
    final String media = data['imageUrl'] ?? data['mediaUrl'] ?? '';
    final String creatorId = data['userId'] ?? data['creatorId'] ?? '';
    final List likes = List.from(data['likes'] ?? []);
    final bool isLiked = likes.contains(currentUserId);
    final String price = data['price'] ?? "Contact for Price";

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
              : Image.network(media, fit: BoxFit.cover),
        ),

        // 2. BACK BUTTON (Floating)
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.white.withOpacity(0.1),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
          ),
        ),

        // 3. RIGHT SIDE FLOATING ACTIONS
        Positioned(
          right: 16,
          top: MediaQuery.of(context).size.height * 0.3,
          child: Column(
            children: [
              _buildModernSideAction(
                icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isLiked ? Colors.redAccent : Colors.white,
                label: "${likes.length}",
                onTap: () => _toggleLike(data),
              ),
              const SizedBox(height: 24),
              _buildModernSideAction(
                icon: Icons.chat_bubble_outline_rounded,
                label: "Ask",
                onTap: () {},
              ),
              const SizedBox(height: 24),
              _buildModernSideAction(
                icon: Icons.share_outlined,
                label: "Send",
                onTap: () => Share.share("Check this out on Ventra!"),
              ),
              const SizedBox(height: 24),
              _buildModernSideAction(
                icon: Icons.bookmark_border_rounded,
                label: "Save",
                onTap: () {},
              ),
            ],
          ),
        ),

        // 4. BOTTOM INFO PANEL (Frosted Glass Style)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8), Colors.black],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username & Badge
                _buildUserHeader(creatorId),
                const SizedBox(height: 12),
                
                // Title and Price Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data['title'] ?? 'Product Details',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      price,
                      style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  data['description'] ?? data['content'] ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.5),
                ),
                
                const SizedBox(height: 25),
                
                // Primary Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: const Text("CONTACT SELLER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: u?['photoURL'] != null ? NetworkImage(u!['photoURL']) : null,
                  backgroundColor: Colors.grey[800],
                ),
              ),
              const SizedBox(width: 10),
              Text("@${u?['username'] ?? 'user'}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                child: const Text("Follow", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernSideAction({required IconData icon, required String label, required VoidCallback onTap, Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  void _toggleLike(Map<String, dynamic> data) async {
    if (currentUserId == null) return;
    final docRef = FirebaseFirestore.instance.collection(_activeCollection).doc(widget.postId.trim());
    List likes = List.from(data['likes'] ?? []);
    bool wasLiked = likes.contains(currentUserId);

    setState(() {
      if (wasLiked) {
        likes.remove(currentUserId);
      } else {
        likes.add(currentUserId);
        HapticFeedback.lightImpact();
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
}