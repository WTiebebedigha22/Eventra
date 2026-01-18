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

  // --- Theme Colors ---
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color accentColor = Colors.white;

  void _openComments(BuildContext context) {
    HapticFeedback.mediumImpact(); 
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7, 
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false, 
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white, // Updated to Light Theme
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(child: CommentsScreen(postId: event['id'])),
            ],
          ),
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
        height: 320, // Slightly taller for better aspect ratio
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.grey[200], 
          image: imageUrl.isNotEmpty 
            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
            : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // --- High-Contrast Gradient ---
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.4, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            
            // --- Price Tag ---
            Positioned(
              top: 16,
              left: 16, // Moved to left for better visual balance
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  color: primaryColor,
                  child: Text(
                    (event['price'] == 0 || event['price'] == null) ? "FREE" : "\$${event['price']}", 
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),

            // --- Bottom Content ---
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event['title'] ?? 'Untitled Event', 
                          style: const TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              event['date'] ?? 'Soon', 
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                event['location'] ?? 'Location', 
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

                  // Actions Column
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      children: [
                        _buildActionButton(
                          icon: Icons.bookmark_outline_rounded, 
                          onTap: () => _toggleBookmark(context, currentUid),
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: "${event['commentCount'] ?? 0}",
                          onTap: () => _openComments(context),
                        ),
                        const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, String? label, required VoidCallback onTap}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label, 
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
          ),
        ],
      ],
    );
  }

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