import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'likes.dart';
import 'comment_sheet.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const EventCard({super.key, required this.event});

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFFFF6B6B);

  bool get _isEvent => event['type'] == 'event' || event['itemType'] == 'event';
  String get _collectionName => _isEvent ? 'events' : 'posts';
  String? get _creatorId => event['creatorId'] ?? event['uid'] ?? event['authorId'] ?? event['userId'];

  String get _mediaUrl => event['mediaUrl'] ?? event['imageUrl'] ?? event['mediaUrls']?.first ?? '';

  String get _mediaType => event['mediaType'] ?? (_mediaUrl.endsWith('.mp4') ? 'video' : 'image');

  Future<Map<String, dynamic>?> _getCreatorData() async {
    if (_creatorId == null) return null;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_creatorId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error fetching creator data: $e');
      return null;
    }
  }

  void _openComments(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: CommentsScreen(postId: event['id'], collection: _collectionName),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (_isEvent) {
          context.push('/home/event/${event['id']}');
        } else {
          context.push('/post/${event['id']}');
        }
      },
      child: Container(
        height: 400,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            /// ─── MEDIA BACKGROUND ───
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: _buildMedia(),
              ),
            ),

            /// ─── GRADIENT OVERLAY ───
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.3, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            /// ─── TYPE BADGE ───
            Positioned(
              top: 16,
              left: 16,
              child: _buildTypeBadge(),
            ),

            /// ─── PRICE BADGE (Events only) ───
            if (_isEvent)
              Positioned(
                top: 16,
                right: 16,
                child: _buildPriceBadge(),
              ),

            /// ─── CONTENT ───
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
                        _buildUserHeader(context),
                        const SizedBox(height: 12),
                        if (_isEvent)
                          _buildEventDetails()
                        else
                          _buildPostCaption(),
                      ],
                    ),
                  ),

                  /// ACTION BUTTONS
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        icon: Icons.bookmark_outline,
                        isActive: false,
                        onTap: () => _toggleBookmark(context, currentUid),
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        icon: Icons.chat_bubble_outline,
                        label: _formatCount(event['commentCount'] ?? 0),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────
  // MEDIA BUILDER (IMAGE + VIDEO)
  // ─────────────────────────────
  Widget _buildMedia() {
    if (_mediaUrl.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: const Icon(Icons.broken_image, color: Colors.white24, size: 64),
      );
    }

    if (_mediaType == 'video') {
      return _VideoPlayerWidget(url: _mediaUrl);
    }

    return CachedNetworkImage(
      imageUrl: _mediaUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[900],
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[900],
        child: const Icon(Icons.broken_image, color: Colors.white24, size: 64),
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isEvent ? primaryColor : Colors.orange,
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
            _isEvent ? Icons.event : Icons.article,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            _isEvent ? 'EVENT' : 'POST',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBadge() {
    final price = event['price'];
    final isFree = price == null || price == 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFree ? [Colors.green, Colors.green.shade700] : [primaryColor, primaryColor.withOpacity(0.8)],
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

  String _formatPrice(dynamic price) {
    if (price == null) return 'FREE';
    final format = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    return format.format(price);
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  /// ─── USER HEADER ───
  Widget _buildUserHeader(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getCreatorData(),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final username = userData?['username'] ?? userData?['displayName'] ?? 'Anonymous';
        final photoUrl = userData?['photoURL'];

        return GestureDetector(
          onTap: () {
            if (_creatorId != null && _creatorId!.isNotEmpty) {
              context.push('/user/$_creatorId');
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(photoUrl)
                    : null,
                backgroundColor: Colors.white24,
                child: photoUrl == null || photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                "@$username",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventDetails() {
    final date = event['eventDate'] as Timestamp?;
    final formattedDate = date != null
        ? DateFormat('MMM d, h:mm a').format(date.toDate())
        : 'Date TBD';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          event['title'] ?? 'Untitled Event',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.location_on, size: 12, color: Colors.white70),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                event['location'] ?? 'Location TBD',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 12, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              formattedDate,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostCaption() {
    return Text(
      event['content'] ?? '',
      style: const TextStyle(color: Colors.white, fontSize: 14),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    bool isActive = false,
    String? label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? secondaryColor : Colors.white,
              size: 22,
            ),
          ),
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleBookmark(BuildContext context, String uid) async {
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to bookmark')),
      );
      return;
    }

    HapticFeedback.lightImpact();
    
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(event['id']);

    final doc = await ref.get();

    try {
      if (doc.exists) {
        await ref.delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from bookmarks'), duration: Duration(seconds: 1)),
          );
        }
      } else {
        await ref.set({
          'id': event['id'],
          'title': event['title'] ?? event['content'],
          'imageUrl': _mediaUrl,
          'type': _isEvent ? 'event' : 'post',
          'savedAt': FieldValue.serverTimestamp(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to bookmarks'), duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
    }
  }
}

/// ─────────────────────────────
/// VIDEO PLAYER WIDGET
/// ─────────────────────────────
class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({required this.url});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url);
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