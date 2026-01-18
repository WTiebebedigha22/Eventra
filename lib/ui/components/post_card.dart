import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ventra/services/social_service.dart';
import 'package:ventra/ui/components/comment_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostCard extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> data;

  const PostCard({required this.postId, required this.data, super.key});

  // --- Theme Colors ---
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;
  static const Color cardBg = Colors.white;

  @override
  Widget build(BuildContext context) {
    final List likes = data['likes'] ?? [];
    final bool isLiked = likes.contains(FirebaseAuth.instance.currentUser?.uid);
    final social = SocialService();

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
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  backgroundImage: data['userProfile'] != null 
                      ? NetworkImage(data['userProfile']) 
                      : null,
                  child: data['userProfile'] == null 
                      ? const Icon(Icons.person, size: 20, color: primaryColor) 
                      : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['userName'] ?? "Anonymous",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: textColor),
                    ),
                    Text(
                      data['timeAgo'] ?? "Just now",
                      style: const TextStyle(fontSize: 12, color: subtleText),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: subtleText),
                  onPressed: () {}, // Options menu
                ),
              ],
            ),
          ),

          // --- Post Text Content ---
          if (data['text'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                data['text'],
                style: const TextStyle(fontSize: 15, color: textColor, height: 1.4),
              ),
            ),

          // --- Post Image Content (Optional) ---
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
                  label: '${data['commentCount'] ?? 0}',
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
  }

  void _showComments(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: CommentsScreen(postId: postId),
      ),
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
            Icon(
              icon,
              color: isActive ? activeColor : subtleText,
              size: 22,
            ),
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