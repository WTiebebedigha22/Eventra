import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  // Helper to determine which collection to pull from
  // If your app knows if it's an event or post before navigating, 
  // you can pass a 'type' parameter. Otherwise, we check both.
  Stream<DocumentSnapshot> _getCombinedStream() {
    // We try the 'posts' collection first
    return FirebaseFirestore.instance.collection('posts').doc(postId).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme as per your previous code
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("Details", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _getCombinedStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          // If not found in 'posts', we try searching 'events'
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('events').doc(postId).get(),
              builder: (context, eventSnapshot) {
                if (eventSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
                  return _buildNotFoundState();
                }
                return _buildContent(eventSnapshot.data!.data() as Map<String, dynamic>);
              },
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          return _buildContent(data);
        },
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. User Header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[900],
              backgroundImage: data['userProfileUrl'] != null ? NetworkImage(data['userProfileUrl']) : null,
              child: data['userProfileUrl'] == null ? const Icon(Icons.person, color: Colors.white24) : null,
            ),
            title: Text(data['username'] ?? 'Anonymous', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(data['location'] ?? '', 
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ),

          // 2. Main Media
          if (data['mediaUrl'] != null || data['imageUrl'] != null)
            Image.network(
              data['mediaUrl'] ?? data['imageUrl'],
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.grey[900],
                child: const Icon(Icons.broken_image, color: Colors.white24),
              ),
            ),

          // 3. Info Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (for Events) or Username (for Posts)
                Text(
                  data['title'] ?? data['username'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Content / Description
                Text(
                  data['content'] ?? data['description'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 20),
                
                // Date logic
                if (data['eventDate'] != null)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Date: ${data['eventDate']}",
                        style: const TextStyle(color: Colors.blueAccent),
                      ),
                    ],
                  ),
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
          const Icon(Icons.search_off, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          const Text("Post Not Found", 
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text("Database ID Searched:", style: TextStyle(color: Colors.white54)),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              postId,
              style: const TextStyle(color: Colors.amber, fontFamily: 'monospace', fontSize: 14),
            ),
          ),
          const Text(
            "Check if this ID exists in your Firestore 'posts' or 'events' collection.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}