import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this
import 'package:ventra/services/social_service.dart';
import 'package:ventra/ui/components/comment_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostCard extends StatelessWidget {
  final String postId;
  // We keep the initial data for a "fast" first paint, but we'll rely on the stream
  final Map<String, dynamic> initialData;

  const PostCard({required this.postId, required this.initialData, super.key});

  static const Color primaryColor = Color(0xFF3E5992);
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;
  static const Color cardBg = Colors.white;

  @override
  Widget build(BuildContext context) {
    final social = SocialService();
    final currentUser = FirebaseAuth.instance.currentUser;

    // 1. Wrap the card in a StreamBuilder to listen for real-time updates
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('events').doc(postId).snapshots(),
      builder: (context, snapshot) {
        // Use live data if available, otherwise fallback to initial data
        final data = snapshot.hasData && snapshot.data!.exists 
            ? snapshot.data!.data() as Map<String, dynamic> 
            : initialData;

        final List likes = data['likedBy'] ?? []; // Note: Ensure this matches your DB key
        final bool isLiked = likes.contains(currentUser?.uid);
        final int commentCount = data['commentCount'] ?? 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- User Header ---
              _buildHeader(data),

              // --- Post Text Content ---
              if (data['text'] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    data['text'],
                    style: const TextStyle(fontSize: 15, color: textColor, height: 1.4),
                  ),
                ),

              // --- Post Image Content ---
              if (data['imageUrl'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ClipRRect(
                    child: Image.network(
                      data['imageUrl'],
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const SizedBox.shrink(),
                    ),
                  ),
                ),

              // --- Interaction Bar ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _actionButton(
                      icon: isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      label: '${likes.length}',
                      activeColor: Colors.redAccent,
                      isActive: isLiked,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        social.toggleLike(postId, likes);
                      },
                    ),
                    const SizedBox(width: 16),
                    _actionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '$commentCount', // Updated from Live Data
                      activeColor: primaryColor,
                      isActive: false,
                      onTap: () => _showComments(context),
                    ),
                    const SizedBox(width: 16),
                    _actionButton(
                      icon: Icons.share_outlined,
                      label: '${data['shareCount'] ?? 0}',
                      activeColor: primaryColor,
                      isActive: false,
                      onTap: () => social.sharePost(postId, data['text'] ?? ""),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primaryColor.withOpacity(0.1),
            backgroundImage: data['userProfile'] != null ? NetworkImage(data['userProfile']) : null,
            child: data['userProfile'] == null ? const Icon(Icons.person, size: 20, color: primaryColor) : null,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['userName'] ?? "Anonymous", style: const TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              Text(data['timeAgo'] ?? "Just now", style: const TextStyle(fontSize: 12, color: subtleText)),
            ],
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.more_horiz, color: subtleText), onPressed: () {}),
        ],
      ),
    );
  }

  void _showComments(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsScreen(postId: postId),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color activeColor,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: isActive ? activeColor : subtleText, size: 22),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : subtleText,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}