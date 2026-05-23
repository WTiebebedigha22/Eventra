import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ventra/services/social_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:ventra/ui/components/comment_sheet.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class PostCard extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> initialData;

  const PostCard({required this.postId, required this.initialData, super.key});

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color accentColor = Color(0xFFFF6B6B);
  static const Color successColor = Color(0xFF4CAF50);

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
        final double price = (data['price'] ?? 0).toDouble();
        final bool isFree = price == 0;
        
        final eventDate = data['eventDate'] as Timestamp?;
        final formattedDate = eventDate != null
            ? DateFormat('EEE, MMM d • h:mm a').format(eventDate.toDate())
            : 'Date TBD';
        
        final commentCount = data['commentCount'] ?? 0;

        /// MEDIA HANDLING (IMAGE + VIDEO)
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                /// MEDIA BACKGROUND
                _buildBackgroundMedia(mediaList),

                /// GRADIENT OVERLAY
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.85),
                        ],
                        stops: const [0.0, 0.3, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                /// CATEGORY BADGE
                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildCategoryBadge(data['category'] ?? 'Event'),
                ),

                /// PRICE BADGE
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildPriceBadge(isFree, price),
                ),

                /// ACTION BUTTONS SIDEBAR
                Positioned(
                  right: 12,
                  bottom: 100,
                  child: Column(
                    children: [
                      _buildActionButton(
                        icon: isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                        color: isLiked ? accentColor : Colors.white,
                        label: _formatCount(likes.length),
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          social.toggleLike(postId, likes);
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: _formatCount(commentCount),
                        onTap: () => _showComments(context),
                      ),
                      const SizedBox(height: 20),
                      _buildActionButton(
                        icon: Icons.share_outlined,
                        label: "Share",
                        onTap: () => social.sharePost(postId, data['title'] ?? ""),
                      ),
                    ],
                  ),
                ),

                /// EVENT INFO
                Positioned(
                  left: 16,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            formattedDate,
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.white70),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              data['location'] ?? "Location TBD",
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildViewDetailsButton(context, postId),
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

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            category,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBadge(bool isFree, double price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFree ? [successColor, successColor.withOpacity(0.8)] : [primaryColor, primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFree ? Icons.celebration : Icons.confirmation_number,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            isFree ? 'FREE' : _formatPrice(price),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    final format = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    return format.format(price);
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildViewDetailsButton(BuildContext context, String eventId) {
    return ElevatedButton(
      onPressed: () => context.push('/event/$eventId'),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        "VIEW DETAILS",
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
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
          onTap: () => context.push('/user/$creatorId'),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: user?['photoURL'] != null && user!['photoURL'].isNotEmpty
                    ? CachedNetworkImageProvider(user['photoURL'])
                    : null,
                backgroundColor: Colors.white24,
                child: user?['photoURL'] == null
                    ? const Icon(Icons.person, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                "@${user?['username'] ?? 'Organizer'}",
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackgroundMedia(List<Map<String, dynamic>> mediaList) {
    if (mediaList.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Icon(Icons.event, size: 64, color: Colors.grey[700]),
        ),
      );
    }

    final first = mediaList.first;

    if (first['type'] == 'video') {
      return _PostVideoPlayer(videoUrl: first['url']);
    }

    return CachedNetworkImage(
      imageUrl: first['url'],
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Container(
        color: Colors.grey[900],
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[900],
        child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
      ),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => CommentsScreen(
          postId: postId,
          collection: 'events',
        ),
      ),
    );
  }
}

/// VIDEO PLAYER WIDGET
class _PostVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _PostVideoPlayer({required this.videoUrl});

  @override
  State<_PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<_PostVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    await _controller.initialize();
    _controller.setLooping(true);
    _controller.play();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
          if (!_controller.value.isPlaying)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
            ),
        ],
      ),
    );
  }
}