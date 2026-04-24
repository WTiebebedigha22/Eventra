import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ventra/services/social_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:ventra/ui/components/comment_sheet.dart';
import 'package:video_player/video_player.dart';

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
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(postId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.hasData && snapshot.data!.exists
            ? snapshot.data!.data() as Map<String, dynamic>
            : initialData;

        final List likes = data['likedBy'] ?? [];
        final bool isLiked = likes.contains(currentUser?.uid);
        final String price = data['price']?.toString() ?? "Free";

        /// ✅ MEDIA HANDLING (IMAGE + VIDEO)
        List<Map<String, dynamic>> mediaList = [];

        if (data['media'] != null) {
          mediaList = List<Map<String, dynamic>>.from(data['media']);
        } else if (data['mediaUrls'] != null) {
          mediaList = List<String>.from(data['mediaUrls'])
              .map((url) => {
                    'url': url,
                    'type': url.contains('.mp4') ? 'video' : 'image',
                  })
              .toList();
        } else if (data['imageUrl'] != null) {
          mediaList = [
            {'url': data['imageUrl'], 'type': 'image'}
          ];
        }

        return Container(
          height: 520,
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
                /// ✅ MEDIA BACKGROUND
                _buildBackgroundMedia(mediaList),

                /// GRADIENT
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
                      ),
                    ),
                  ),
                ),

                /// PRICE BADGE
                Positioned(
                  top: 20,
                  right: 20,
                  child: _buildPrice(price),
                ),

                /// SIDEBAR
                Positioned(
                  right: 12,
                  bottom: 100,
                  child: Column(
                    children: [
                      _buildFloatingAction(
                        icon: isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_outline_rounded,
                        color: isLiked ? Colors.redAccent : Colors.white,
                        label: "${likes.length}",
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          social.toggleLike(postId, likes);
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildFloatingAction(
                        icon: Icons.chat_bubble,
                        label: "Chat",
                        onTap: () => _showComments(context),
                      ),
                      const SizedBox(height: 20),
                      _buildFloatingAction(
                        icon: Icons.share,
                        label: "Share",
                        onTap: () =>
                            social.sharePost(postId, data['title'] ?? ""),
                      ),
                    ],
                  ),
                ),

                /// BOTTOM INFO
                Positioned(
                  left: 20,
                  bottom: 20,
                  right: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserHeader(context, data['creatorId']),
                      const SizedBox(height: 12),

                      Text(
                        data['title'] ?? "Untitled Event",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        data['text'] ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),

                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: () =>
                            context.push('/event/${postId}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: jijiGreen,
                        ),
                        child: const Text("VIEW DETAILS"),
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

  /// ✅ MEDIA RENDERER
  Widget _buildBackgroundMedia(List<Map<String, dynamic>> mediaList) {
    if (mediaList.isEmpty) {
      return Container(color: Colors.grey[900]);
    }

    final first = mediaList.first;

    if (first['type'] == 'video') {
      return _PostVideoPlayer(videoUrl: first['url']);
    }

    return Image.network(
      first['url'],
      fit: BoxFit.cover,
      height: double.infinity,
      width: double.infinity,
    );
  }

  /// VIDEO PLAYER
  Widget _buildPrice(String price) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: jijiGreen.withOpacity(0.9),
          child: Text(
            price.contains('₦') || price.toLowerCase() == 'free'
                ? price
                : "₦$price",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(icon, color: color),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildUserHeader(BuildContext context, String? creatorId) {
    if (creatorId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(creatorId)
          .snapshots(),
      builder: (context, snapshot) {
        final user = snapshot.data?.data() as Map<String, dynamic>?;

        return GestureDetector(
          onTap: () => context.push('/profile/$creatorId'),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage:
                    user?['photoURL'] != null
                        ? NetworkImage(user!['photoURL'])
                        : null,
              ),
              const SizedBox(width: 8),
              Text("@${user?['username'] ?? "User"}",
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
        );
      },
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => CommentsScreen(postId: postId),
    );
  }
}

/// 🎬 VIDEO PLAYER FOR POSTS
class _PostVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _PostVideoPlayer({required this.videoUrl});

  @override
  State<_PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<_PostVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) => setState(() {}))
      ..setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    _controller.value.isPlaying
        ? _controller.pause()
        : _controller.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container(color: Colors.black);
    }

    return GestureDetector(
      onTap: _toggle,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          if (!_controller.value.isPlaying)
            const Icon(Icons.play_circle, color: Colors.white, size: 60),
        ],
      ),
    );
  }
}