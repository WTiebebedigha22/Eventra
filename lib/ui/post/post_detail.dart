import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<Map<String, dynamic>?> _postFuture;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  String _activeCollection = 'posts';
  bool _isHeartAnimating = false;
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
      } else {
        setState(() => _activeCollection = 'posts');
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (!snapshot.hasData || snapshot.data == null) return const Center(child: Text("Not found", style: TextStyle(color: Colors.white)));
          
          return _buildTikTokJijiBody(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildTikTokJijiBody(Map<String, dynamic> data) {
    final String media = data['imageUrl'] ?? data['mediaUrl'] ?? '';
    final String creatorId = data['userId'] ?? data['creatorId'] ?? '';
    final List likes = data['likes'] ?? [];
    final bool isLiked = likes.contains(currentUserId);
    final String price = data['price'] ?? "Contact for Price";

    return Stack(
      children: [
        // 1. FULLSCREEN MEDIA (TikTok Style)
        GestureDetector(
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
                : Image.network(media, fit: BoxFit.cover),
          ),
        ),

        // 2. GRADIENT OVERLAY (For readability)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black45, Colors.transparent, Colors.transparent, Colors.black87],
              stops: [0, 0.2, 0.6, 1],
            ),
          ),
        ),

        // 3. RIGHT SIDEBAR (TikTok Style Interactions)
        Positioned(
          right: 12,
          bottom: 120,
          child: Column(
            children: [
              _buildSideAction(
                icon: isLiked ? Icons.favorite : Icons.favorite,
                color: isLiked ? Colors.red : Colors.white,
                label: "${likes.length}",
                onTap: () => _toggleLike(data),
              ),
              const SizedBox(height: 20),
              _buildSideAction(
                icon: Icons.chat_bubble_rounded,
                label: "Comments",
                onTap: () {},
              ),
              const SizedBox(height: 20),
              _buildSideAction(
                icon: Icons.share_rounded,
                label: "Share",
                onTap: () => Share.share("Check this out!"),
              ),
            ],
          ),
        ),

        // 4. BOTTOM INFO & JIJI CTA
        Positioned(
          left: 16,
          bottom: 40,
          right: 80, // Leave space for the sidebar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(creatorId).snapshots(),
                builder: (context, userSnap) {
                  final u = userSnap.hasData ? (userSnap.data!.data() as Map<String, dynamic>?) : null;
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(u?['photoURL'] ?? ''),
                      ),
                      const SizedBox(width: 10),
                      Text("@${u?['username'] ?? 'user'}", 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              // Price Badge (Jiji Style)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3BA73A), // Jiji Green
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(height: 8),
              // Content/Description
              Text(data['description'] ?? data['content'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 15),
              // Jiji Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3BA73A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  child: const Text("SHOW CONTACT / VIEW ITEM", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
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
          child: Icon(icon, color: color, size: 35),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _toggleLike(Map<String, dynamic> data) async {
    if (currentUserId == null) return;
    final docRef = FirebaseFirestore.instance.collection(_activeCollection).doc(widget.postId.trim());
    List likes = data['likes'] ?? [];
    if (likes.contains(currentUserId)) {
      await docRef.update({'likes': FieldValue.arrayRemove([currentUserId])});
    } else {
      HapticFeedback.lightImpact();
      await docRef.update({'likes': FieldValue.arrayUnion([currentUserId])});
    }
    setState(() { _postFuture = _loadData(); });
  }
}