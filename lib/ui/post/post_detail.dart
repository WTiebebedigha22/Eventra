import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

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

  @override
  void initState() {
    super.initState();
    _postFuture = _loadData();
  }

  // --- THE WATERFALL FETCH LOGIC ---
  Future<Map<String, dynamic>?> _loadData() async {
    final String id = widget.postId.trim();
    debugPrint("🛠️ Fetching Content ID: $id");

    try {
      // Step 1: Check the 'posts' collection
      DocumentSnapshot postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(id)
          .get();

      if (postDoc.exists && postDoc.data() != null) {
        debugPrint("✅ Found in 'posts'");
        setState(() => _activeCollection = 'posts');
        return postDoc.data() as Map<String, dynamic>;
      }

      // Step 2: Check the 'events' collection if posts failed
      DocumentSnapshot eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(id)
          .get();

      if (eventDoc.exists && eventDoc.data() != null) {
        debugPrint("✅ Found in 'events'");
        setState(() => _activeCollection = 'events');
        return eventDoc.data() as Map<String, dynamic>;
      }

      debugPrint("❌ ID not found in either collection.");
    } catch (e) {
      debugPrint("⚠️ Firestore Error: $e");
    }
    return null;
  }

  void _toggleLike(Map<String, dynamic> data) async {
    if (currentUserId == null) return;
    
    final docRef = FirebaseFirestore.instance
        .collection(_activeCollection)
        .doc(widget.postId.trim());
    
    List likes = data['likes'] ?? [];

    if (likes.contains(currentUserId)) {
      await docRef.update({'likes': FieldValue.arrayRemove([currentUserId])});
    } else {
      await docRef.update({'likes': FieldValue.arrayUnion([currentUserId])});
      setState(() => _isHeartAnimating = true);
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _isHeartAnimating = false);
      });
    }
    setState(() { _postFuture = _loadData(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(_activeCollection.toUpperCase(), 
          style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3E5992)));
          }
          
          if (!snapshot.hasData || snapshot.data == null) {
            return _buildNotFoundUI();
          }

          return _buildContentBody(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildContentBody(Map<String, dynamic> data) {
    // Handle dynamic keys (Ventra often uses mediaUrl or imageUrl)
    final String media = data['imageUrl'] ?? data['mediaUrl'] ?? '';
    final String userImg = data['userProfileUrl'] ?? '';
    final String username = data['username'] ?? 'User';
    final List likes = data['likes'] ?? [];
    final bool isLiked = likes.contains(currentUserId);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.white10,
              backgroundImage: userImg.isNotEmpty ? NetworkImage(userImg) : null,
              child: userImg.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
            ),
            title: Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(data['location'] ?? 'Ventra', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),

          // Main Media with Animation
          GestureDetector(
            onDoubleTap: () => _toggleLike(data),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 1, // Instagram Style
                  child: Image.network(
                    media,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: Colors.white10,
                      child: const Icon(Icons.broken_image, color: Colors.white24, size: 50),
                    ),
                  ),
                ),
                if (_isHeartAnimating)
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 400),
                    tween: Tween<double>(begin: 0, end: 1.2),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: const Icon(Icons.favorite, color: Colors.white, size: 100),
                      );
                    },
                  ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            children: [
              IconButton(
                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, 
                color: isLiked ? Colors.red : Colors.white),
                onPressed: () => _toggleLike(data),
              ),
              IconButton(icon: const Icon(Icons.mode_comment_outlined, color: Colors.white), onPressed: () {}),
              IconButton(
                icon: const Icon(Icons.send_outlined, color: Colors.white),
                onPressed: () => Share.share("Check out this post on Ventra: $media"),
              ),
            ],
          ),

          // Description Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${likes.length} likes", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                    children: [
                      TextSpan(text: "$username ", style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: data['description'] ?? data['content'] ?? ''),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text("RECOMMENDED FOR YOU", 
                  style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                _buildDiscoveryGrid(),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryGrid() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection(_activeCollection).limit(4).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 200);
        final docs = snapshot.data!.docs.where((d) => d.id != widget.postId).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final item = docs[index].data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (context) => PostDetailScreen(postId: docs[index].id))
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(item['imageUrl'] ?? item['mediaUrl'] ?? '', fit: BoxFit.cover),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotFoundUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, color: Colors.white24, size: 80),
          const SizedBox(height: 20),
          const Text("Content Missing", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("ID: ${widget.postId}", style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3E5992)),
            onPressed: () => Navigator.pop(context),
            child: const Text("Go Back"),
          )
        ],
      ),
    );
  }
}