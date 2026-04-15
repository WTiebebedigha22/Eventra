import 'dart:ui';
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

  // Jiji-inspired Green
  static const Color jijiGreen = Color(0xFF3BA73A);

  @override
  Widget build(BuildContext context) {
    final social = SocialService();
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      // Listening to specific post updates (likes, price changes, etc.)
      stream: FirebaseFirestore.instance.collection('events').doc(postId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.hasData && snapshot.data!.exists 
            ? snapshot.data!.data() as Map<String, dynamic> 
            : initialData;

        final List likes = data['likedBy'] ?? [];
        final bool isLiked = likes.contains(currentUser?.uid);
        final String price = data['price']?.toString() ?? "Free";

        return Container(
          height: 520, // Slightly taller for better aspect ratio in feeds
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                // 1. Background Media
                _buildBackgroundMedia(data['imageUrl']),

                // 2. High-Contrast Gradient (Bottom-heavy for text legibility)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.9),
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Price Badge (Glassmorphism + Jiji Green)
                Positioned(
                  top: 20,
                  right: 20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: jijiGreen.withOpacity(0.9),
                        ),
                        child: Text(
                          price.contains('₦') || price.toLowerCase() == 'free' ? price : "₦$price",
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Interaction Sidebar
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
                      const SizedBox(height: 20),
                      _buildFloatingAction(
                        icon: Icons.chat_bubble_rounded,
                        label: "Chat",
                        onTap: () => _showComments(context),
                      ),
                      const SizedBox(height: 20),
                      _buildFloatingAction(
                        icon: Icons.share_rounded,
                        label: "Share",
                        onTap: () {
                          HapticFeedback.lightImpact();
                          social.sharePost(postId, data['title'] ?? "");
                        },
                      ),
                    ],
                  ),
                ),

                // 5. Bottom Info Layer
                Positioned(
                  left: 20,
                  bottom: 20,
                  right: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildUserHeader(context, data['creatorId']),
                      const SizedBox(height: 12),
                      Text(
                        data['title'] ?? "Untitled Event",
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 20,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data['text'] ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85), 
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // CTA Button
                      ElevatedButton(
                        onPressed: () => context.push('/event-details/$postId'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: jijiGreen,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          "VIEW DETAILS", 
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
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
    return url != null
        ? Image.network(
            url,
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(color: Colors.grey[900]);
            },
            errorBuilder: (context, e, s) => Container(
              color: Colors.grey[900],
              child: const Icon(Icons.broken_image, color: Colors.white24),
            ),
          )
        : Container(color: Colors.grey[900]);
  }

  Widget _buildFloatingAction({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap, 
    Color color = Colors.white
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label, 
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 12, 
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
      ],
    );
  }

  Widget _buildUserHeader(BuildContext context, String? creatorId) {
    if (creatorId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(creatorId).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.hasData ? snapshot.data!.data() as Map<String, dynamic>? : null;
        final name = userData?['username'] ?? "User";
        final photo = userData?['photoURL'];

        return GestureDetector(
          onTap: () => context.push('/profile/$creatorId'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: (photo != null) ? NetworkImage(photo) : null,
                  backgroundColor: Colors.grey[800],
                  child: (photo == null) ? const Icon(Icons.person, size: 16, color: Colors.white) : null,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "@$name",
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 15,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
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