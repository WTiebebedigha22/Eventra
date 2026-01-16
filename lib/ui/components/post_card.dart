import 'package:flutter/material.dart';
import 'package:ventra/services/social_service.dart';
import 'package:ventra/ui/components/comment_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostCard extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> data;

  const PostCard({required this.postId, required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final List likes = data['likes'] ?? [];
    final bool isLiked = likes.contains(FirebaseAuth.instance.currentUser?.uid);
    final social = SocialService();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      color: const Color(0xFF0F0F0F),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Content Placeholder
          Container(height: 300, color: Colors.white10, child: const Center(child: Icon(Icons.image, color: Colors.white24))),
          
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                _actionButton(
                  icon: isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  label: '${likes.length}',
                  color: isLiked ? const Color(0xFFE91E63) : Colors.white,
                  onTap: () => social.toggleLike(postId, likes),
                ),
                const SizedBox(width: 20),
                _actionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${data['commentCount'] ?? 0}',
                  color: Colors.white,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: const Color(0xFF181818),
                    builder: (context) => CommentsScreen(postId: postId),
                  ),
                ),
                const SizedBox(width: 20),
                _actionButton(
                  icon: Icons.share_outlined,
                  label: '${data['shareCount'] ?? 0}',
                  color: Colors.white,
                  onTap: () => social.sharePost(postId, data['text'] ?? ""),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}