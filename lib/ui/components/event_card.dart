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

  // --- Logic Helpers ---
  bool get _isEvent => event['itemType'] == 'event';
  String get _collectionName => _isEvent ? 'events' : 'posts';

  /// Fetches the creator's profile data from the 'users' collection
  Future<Map<String, dynamic>?> _getCreatorData() async {
    final String? creatorId = event['uid'] ?? event['authorId'];
    if (creatorId == null) return null;
    
    final doc = await FirebaseFirestore.instance.collection('users').doc(creatorId).get();
    return doc.data();
  }

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
            color: Colors.white, 
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
    final String imageUrl = event['imageUrl'] ?? event['mediaUrl'] ?? '';

    return GestureDetector(
      onTap: () => context.push('/home/event/${event['id']}'),
      child: Container(
        height: 320, 
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.grey[900], 
          image: imageUrl.isNotEmpty 
            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
            : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // --- High-Contrast Gradient Overlay ---
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.3, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            
            // --- Price Tag (Events Only) ---
            if (_isEvent)
              Positioned(
                top: 16,
                left: 16, 
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

            // --- Bottom Content Layer ---
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Information Side
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUserHeader(), // Fetches Username and Profile Pic
                        const SizedBox(height: 10),
                        _isEvent ? _buildEventDetails() : _buildPostCaption(),
                      ],
                    ),
                  ),

                  // Actions Side
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
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
                          collection: _collectionName, 
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

  // --- Dynamic User Header ---
  Widget _buildUserHeader() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getCreatorData(),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final String username = userData?['username'] ?? 'User';
        final String? profilePic = userData?['profilePic'] ?? userData?['photoURL'];

        return Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Colors.grey[800],
                backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
                child: profilePic == null 
                  ? const Icon(Icons.person, size: 18, color: Colors.white) 
                  : null,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event['title'] ?? 'Untitled Event', 
          style: const TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.bold, 
            color: Colors.white,
            height: 1.1,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                event['location'] ?? 'Location TBA',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostCaption() {
    final String content = event['content'] ?? event['description'] ?? '';
    return Text(
      content,
      style: const TextStyle(
        fontSize: 16, 
        color: Colors.white,
        height: 1.3,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
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
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removed from saved")));
      }
    } else {
      await bookmarkRef.set({
        ...event,
        'savedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved!")));
      }
    }
  }
}