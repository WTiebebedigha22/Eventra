import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ventra/ui/components/likes.dart'; 
import 'package:ventra/ui/components/comments.dart'; 

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const EventCard({super.key, required this.event});

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Allows for rounded top corners
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F0F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: CommentsScreen(postId: event['id']),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return GestureDetector(
      onTap: () => context.push('/home/event/${event['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 280, // Slightly increased height for better spacing
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: NetworkImage(event['imageUrl'] ?? ''),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Dark Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent, 
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.9)
                  ],
                ),
              ),
            ),
            
            // Price Tag (Top Right)
            Positioned(
              top: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  event['price'] == 0 ? "FREE" : "\$${event['price']}", 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),

            // Event Details (Bottom Left)
            Positioned(
              bottom: 20,
              left: 20,
              right: 100, // Space for stacked action buttons
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'] ?? 'Untitled Event', 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFFE91E63)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${event['location']} • ${event['date'] ?? 'Soon'}", 
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Buttons (Bottom Right - Stacked Vertically)
            Positioned(
              bottom: 10,
              right: 10,
              child: Column(
                children: [
                  // Bookmark Button
                  IconButton(
                    icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white, size: 24),
                    onPressed: () => _toggleBookmark(context, currentUid),
                  ),
                  // Comment Button with Count
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 24),
                        onPressed: () => _openComments(context),
                      ),
                      Text(
                        "${event['commentCount'] ?? 0}",
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                  // Like Button
                  LikeButton(
                    postId: event['id'], 
                    likes: event['likes'] ?? [],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Logic remains the same ---
  Future<void> _toggleBookmark(BuildContext context, String uid) async {
    final bookmarkRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(event['id']);

    final doc = await bookmarkRef.get();

    if (doc.exists) {
      await bookmarkRef.delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Removed from saved events")),
        );
      }
    } else {
      await bookmarkRef.set({
        ...event,
        'savedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Event saved!")),
        );
      }
    }
  }
}