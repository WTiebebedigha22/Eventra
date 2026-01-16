import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:ventra/ui/components/likes.dart'; 
import 'package:ventra/ui/components/comment_sheet.dart'; 

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const EventCard({super.key, required this.event});

  void _openComments(BuildContext context) {
    HapticFeedback.lightImpact(); // Consistent with your home screen feel
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, // Start at 60% of screen
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false, // CRITICAL: Fixes the 'height' error in BottomSheets
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F0F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          // Pass the scroll controller to allow scrolling inside the sheet
          child: CommentsScreen(postId: event['id']), 
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final String imageUrl = event['imageUrl'] ?? '';

    return GestureDetector(
      onTap: () => context.push('/home/event/${event['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // Added a fallback color if image fails to load
          color: Colors.grey[900], 
          image: imageUrl.isNotEmpty 
            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
            : null,
        ),
        child: Stack(
          children: [
            // Dark Gradient Overlay - Optimized colors
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1), 
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.9)
                  ],
                ),
              ),
            ),
            
            // Price Tag
            Positioned(
              top: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: Text(
                  (event['price'] == 0 || event['price'] == null) ? "FREE" : "\$${event['price']}", 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                ),
              ),
            ),

            // Event Details
            Positioned(
              bottom: 20,
              left: 20,
              right: 80, // Prevent text from overlapping the vertical buttons
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                          "${event['location'] ?? 'Location'} • ${event['date'] ?? 'Soon'}", 
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Vertical Action Column
            Positioned(
              bottom: 15,
              right: 10,
              child: Column(
                children: [
                  _buildIconButton(
                    icon: Icons.bookmark_border_rounded, 
                    onTap: () => _toggleBookmark(context, currentUid),
                  ),
                  const SizedBox(height: 5),
                  _buildIconButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: "${event['commentCount'] ?? 0}",
                    onTap: () => _openComments(context),
                  ),
                  const SizedBox(height: 5),
                  LikeButton(
                    postId: event['id'], 
                    likes: List<String>.from(event['likes'] ?? []),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to keep the vertical column clean
  Widget _buildIconButton({required IconData icon, String? label, required VoidCallback onTap}) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white, size: 26),
          onPressed: onTap,
          constraints: const BoxConstraints(), // Removes extra padding
          padding: const EdgeInsets.all(8),
        ),
        if (label != null)
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
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