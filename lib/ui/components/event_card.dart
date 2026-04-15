import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'likes.dart'; 
import 'comment_sheet.dart'; 

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const EventCard({super.key, required this.event});

  static const Color primaryColor = Color(0xFF3E5992);

  // --- Logic Helpers ---
  bool get _isEvent => event['itemType'] == 'event';
  String get _collectionName => _isEvent ? 'events' : 'posts';
  
  // Ensures we get the right ID for the creator regardless of field naming
  String? get _creatorId => event['uid'] ?? event['authorId'] ?? event['userId'];

  /// Fetches the creator's profile data from the 'users' collection
  Future<Map<String, dynamic>?> _getCreatorData() async {
    if (_creatorId == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(_creatorId).get();
    return doc.data();
  }

  void _openComments(BuildContext context) {
    HapticFeedback.lightImpact(); 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75, 
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
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
        height: 380, 
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Stack(
          children: [
            // --- Background Media ---
            Positioned.fill(
              child: Hero(
                tag: 'media_${event['id']}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: imageUrl.isNotEmpty 
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white24)),
                ),
              ),
            ),
            
            // --- Dark Gradient Overlay ---
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.9)],
                    stops: const [0.4, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            
            // --- Price Tag ---
            if (_isEvent)
              Positioned(
                top: 16,
                left: 16, 
                child: _buildGlassTag(
                  child: Text(
                    (event['price'] == 0 || event['price'] == null) ? "FREE" : "₦${event['price']}", 
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13),
                  ),
                  color: primaryColor.withOpacity(0.8),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUserHeader(context), // Re-styled for tap-to-profile
                        const SizedBox(height: 12),
                        _isEvent ? _buildEventDetails() : _buildPostCaption(),
                      ],
                    ),
                  ),

                  // Actions Column
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      children: [
                        _buildActionButton(
                          icon: Icons.bookmark_outline_rounded, 
                          onTap: () => _toggleBookmark(context, currentUid),
                        ),
                        const SizedBox(height: 16),
                        _buildActionButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: "${event['commentCount'] ?? 0}",
                          onTap: () => _openComments(context),
                        ),
                        const SizedBox(height: 16),
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

  // --- Profile Navigation Header ---
  Widget _buildUserHeader(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getCreatorData(),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final String username = userData?['username'] ?? 'loading...';
        final String? profilePic = userData?['photoURL'] ?? userData?['profilePic'];

        return GestureDetector(
          onTap: () {
            if (_creatorId != null) {
              // Redirects to the respective user profile
              context.push('/user/$_creatorId');
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white24,
                  backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
                  child: profilePic == null ? const Icon(Icons.person, size: 12, color: Colors.white) : null,
                ),
                const SizedBox(width: 8),
                Text(
                  "@$username",
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassTag({required Widget child, Color? color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: color ?? Colors.white.withOpacity(0.2),
          child: child,
        ),
      ),
    );
  }

  Widget _buildEventDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event['title'] ?? 'Untitled Event', 
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          event['location'] ?? 'Location TBA',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildPostCaption() {
    return Text(
      event['content'] ?? event['description'] ?? '',
      style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.3),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActionButton({required IconData icon, String? label, required VoidCallback onTap}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }

  Future<void> _toggleBookmark(BuildContext context, String uid) async {
    final bookmarkRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('bookmarks').doc(event['id']);
    final doc = await bookmarkRef.get();

    if (doc.exists) {
      await bookmarkRef.delete();
      if (context.mounted) _showToast(context, "Removed from saved");
    } else {
      await bookmarkRef.set({...event, 'savedAt': FieldValue.serverTimestamp()});
      if (context.mounted) _showToast(context, "Saved!");
    }
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}