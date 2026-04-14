import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ventra/services/social_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:ventra/ui/components/comment_sheet.dart';

class PostCard extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> initialData;

  const PostCard({required this.postId, required this.initialData, super.key});

  static const Color jijiGreen = Color(0xFF3BA73A);

  @override
  Widget build(BuildContext context) {
    final social = SocialService();
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('events').doc(postId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.hasData && snapshot.data!.exists 
            ? snapshot.data!.data() as Map<String, dynamic> 
            : initialData;

        final List likes = data['likedBy'] ?? [];
        final bool isLiked = likes.contains(currentUser?.uid);
        final String price = data['price'] ?? "Free";

        return Container(
          height: 500, // Fixed height for feed consistency
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // 1. TikTok Style Background Media
                _buildBackgroundMedia(data['imageUrl']),

                // 2. Gradient Overlay for Text Readability
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black45,
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black87
                        ],
                        stops: [0.0, 0.2, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Jiji Green Price Badge (Top Right)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: jijiGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      price,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // 4. Floating Interaction Sidebar (Right)
                Positioned(
                  right: 12,
                  bottom: 100,
                  child: Column(
                    children: [
                      _buildFloatingAction(
                        icon: isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                        color: isLiked ? Colors.redAccent : Colors.white,
                        label: "${likes.length}",
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          social.toggleLike(postId, likes);
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildFloatingAction(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: "Chat", // Jiji flavor
                        onTap: () => _showComments(context),
                      ),
                      const SizedBox(height: 18),
                      _buildFloatingAction(
                        icon: Icons.share_location_outlined,
                        label: "Share",
                        onTap: () => social.sharePost(postId, data['text'] ?? ""),
                      ),
                    ],
                  ),
                ),

                // 5. Bottom Info Area (TikTok Style)
                Positioned(
                  left: 16,
                  bottom: 16,
                  right: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserHeader(context, data['creatorId']),
                      const SizedBox(height: 8),
                      Text(
                        data['title'] ?? "",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['text'] ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      // Jiji Style Call to Action
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () => context.push('/event-details/$postId'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: jijiGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text("VIEW DETAILS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundMedia(String? url) {
    if (url == null) return Container(color: Colors.grey[900]);
    return Image.network(
      url,
      height: double.infinity,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, e, s) => Container(color: Colors.grey[900]),
    );
  }

  Widget _buildFloatingAction({required IconData icon, required String label, required VoidCallback onTap, Color color = Colors.white}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildUserHeader(BuildContext context, String? creatorId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(creatorId).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.hasData ? snapshot.data!.data() as Map<String, dynamic>? : null;
        final name = userData?['username'] ?? "User";
        final photo = userData?['photoURL'];

        return GestureDetector(
          onTap: () => context.push('/profile/$creatorId'),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: (photo != null) ? NetworkImage(photo) : null,
                backgroundColor: Colors.white24,
                child: (photo == null) ? const Icon(Icons.person, size: 14, color: Colors.white) : null,
              ),
              const SizedBox(width: 8),
              Text(
                "@$name",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        );
      },
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
}