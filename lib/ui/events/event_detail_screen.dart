import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    // Light Theme Palette
    const Color primaryColor = Color(0xFF3E5992);
    const Color textMain = Color(0xFF1C1E21);
    const Color textSub = Color(0xFF65676B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Post', style: TextStyle(color: textMain, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Ensure 'events' matches your collection name in Firestore
        stream: FirebaseFirestore.instance.collection('events').doc(eventId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading post"));
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          // FIX: Explicitly check if the document exists in Firestore
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Post not found", style: TextStyle(color: textSub, fontWeight: FontWeight.bold)),
                  Text("ID: $eventId", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Go Back"))
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (User Info)
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: data['userProfile'] != null ? NetworkImage(data['userProfile']) : null,
                    backgroundColor: Colors.grey[200],
                    child: data['userProfile'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
                  ),
                  title: Text(data['userName'] ?? 'Anonymous', 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: textMain)),
                  subtitle: Text(data['location'] ?? 'No location', 
                    style: const TextStyle(color: textSub, fontSize: 13)),
                ),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(data['description'] ?? '', 
                    style: const TextStyle(fontSize: 16, color: textMain, height: 1.4)),
                ),

                // Post Image
                if (data['imageUrl'] != null)
                  Image.network(
                    data['imageUrl'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      height: 200, color: Colors.grey[100], child: const Icon(Icons.broken_image)
                    ),
                  ),

                // Interaction Stats
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.thumb_up, color: primaryColor, size: 14),
                      const SizedBox(width: 4),
                      Text("${(data['likes'] as List?)?.length ?? 0}", style: const TextStyle(color: textSub)),
                      const Spacer(),
                      Text("${data['commentCount'] ?? 0} comments", style: const TextStyle(color: textSub)),
                    ],
                  ),
                ),

                const Divider(height: 1),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(Icons.thumb_up_off_alt, "Like", () => _handleLike(data), primaryColor),
                    _buildActionButton(Icons.chat_bubble_outline, "Comment", () {}, textSub),
                    _buildActionButton(Icons.share_outlined, "Share", () {}, textSub),
                  ],
                ),

                const Divider(height: 1),
                const SizedBox(height: 24),

                // Contact User Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _contactUser(context, data['creatorId']),
                    icon: const Icon(Icons.messenger_outline),
                    label: const Text("Contact User", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: color),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  // Real-time Like Logic
  Future<void> _handleLike(Map<String, dynamic> data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final List likes = data['likes'] ?? [];
    final docRef = FirebaseFirestore.instance.collection('events').doc(eventId);

    if (likes.contains(uid)) {
      await docRef.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await docRef.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }

  void _contactUser(BuildContext context, String? creatorId) {
    if (creatorId == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Starting conversation..."), behavior: SnackBarBehavior.floating),
    );
  }
}