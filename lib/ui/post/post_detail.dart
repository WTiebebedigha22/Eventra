import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart'; // Ensure this is in your pubspec.yaml

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<Map<String, dynamic>?> _postFuture;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _postFuture = _fetchPostOrEvent();
  }

  Future<Map<String, dynamic>?> _fetchPostOrEvent() async {
    try {
      final String cleanId = widget.postId.trim();
      // Try posts
      var doc = await FirebaseFirestore.instance.collection('posts').doc(cleanId).get();
      if (doc.exists) return doc.data();
      
      // Try events
      doc = await FirebaseFirestore.instance.collection('events').doc(cleanId).get();
      if (doc.exists) return doc.data();
    } catch (e) {
      debugPrint("Firestore Error: $e");
    }
    return null;
  }

  // --- SOCIAL ACTIONS ---

  void _handleLike(Map<String, dynamic> data) async {
    if (currentUserId == null) return;

    final String cleanId = widget.postId.trim();
    // Determine if it's a post or event to update the right collection
    final String collection = (data['type'] == 'event' || data.containsKey('eventDate')) ? 'events' : 'posts';
    
    DocumentReference docRef = FirebaseFirestore.instance.collection(collection).doc(cleanId);
    List likes = data['likes'] ?? [];

    if (likes.contains(currentUserId)) {
      await docRef.update({'likes': FieldValue.arrayRemove([currentUserId])});
    } else {
      await docRef.update({'likes': FieldValue.arrayUnion([currentUserId])});
      // Logic for creating notification could go here as per your rules
    }
    _refresh(); // Refresh UI to show updated like count
  }

  void _handleShare(Map<String, dynamic> data) {
    final String text = "Check out this ${data['title'] ?? 'post'} on our app!\n\n${data['content'] ?? ''}";
    Share.share(text);
  }

  void _refresh() {
    setState(() {
      _postFuture = _fetchPostOrEvent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("Post", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _postFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (!snapshot.hasData || snapshot.data == null) return _buildNotFoundState();

            return _buildContent(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    final List likes = data['likes'] ?? [];
    final bool isLiked = likes.contains(currentUserId);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header
          ListTile(
            leading: CircleAvatar(
              backgroundImage: data['userProfileUrl'] != null ? NetworkImage(data['userProfileUrl']) : null,
              child: data['userProfileUrl'] == null ? const Icon(Icons.person) : null,
            ),
            title: Text(data['username'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(data['location'] ?? '', style: const TextStyle(color: Colors.white60)),
          ),

          // Media
          if (data['mediaUrl'] != null || data['imageUrl'] != null)
            Image.network(data['mediaUrl'] ?? data['imageUrl'], width: double.infinity, fit: BoxFit.contain),

          // --- INTERACTION BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, 
                       color: isLiked ? Colors.red : Colors.white),
                  onPressed: () => _handleLike(data),
                ),
                Text("${likes.length}", style: const TextStyle(color: Colors.white)),
                const SizedBox(width: 15),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                  onPressed: () {
                    // Navigate to your comment screen or show a modal
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Comments coming soon!")));
                  },
                ),
                const SizedBox(width: 15),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  onPressed: () => _handleShare(data),
                ),
              ],
            ),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['title'] != null)
                  Text(data['title'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(data['content'] ?? data['description'] ?? '', 
                     style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: Colors.white10),
          const Text("Post Not Found", style: TextStyle(color: Colors.white, fontSize: 18)),
          TextButton(onPressed: _refresh, child: const Text("Retry"))
        ],
      ),
    );
  }
}