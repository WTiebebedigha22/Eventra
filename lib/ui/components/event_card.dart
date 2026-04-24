import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'likes.dart'; 
import 'comment_sheet.dart'; 

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const EventCard({super.key, required this.event});

  static const Color primaryColor = Colors.deepPurpleAccent;

  bool get _isEvent => event['itemType'] == 'event';
  String get _collectionName => _isEvent ? 'events' : 'posts';
  String? get _creatorId => event['uid'] ?? event['authorId'] ?? event['userId'];

  String get _mediaUrl =>
      event['mediaUrl'] ?? event['imageUrl'] ?? '';

  String get _mediaType =>
      event['mediaType'] ??
      (_mediaUrl.endsWith('.mp4') ? 'video' : 'image');

  Future<Map<String, dynamic>?> _getCreatorData() async {
    if (_creatorId == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_creatorId)
        .get();
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
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
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
    final String currentUid =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    return GestureDetector(
      onTap: () => context.push('/home/event/${event['id']}'),
      child: Container(
        height: 380,
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Stack(
          children: [
            /// ─── MEDIA BACKGROUND ───
            Positioned.fill(
              child: Hero(
                tag: 'media_${event['id']}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: _buildMedia(),
                ),
              ),
            ),

            /// ─── GRADIENT ───
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.4, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            /// ─── PRICE ───
            if (_isEvent)
              Positioned(
                top: 16,
                left: 16,
                child: _buildGlassTag(
                  child: Text(
                    (event['price'] == 0 || event['price'] == null)
                        ? "FREE"
                        : "₦${event['price']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  color: primaryColor.withOpacity(0.8),
                ),
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
                      children: [
                        _buildUserHeader(context),
                        const SizedBox(height: 12),
                        _isEvent
                            ? _buildEventDetails()
                            : _buildPostCaption(),
                      ],
                    ),
                  ),

                  /// ACTIONS
                  Column(
                    children: [
                      _buildActionButton(
                        icon: Icons.bookmark_outline,
                        onTap: () =>
                            _toggleBookmark(context, currentUid),
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        icon: Icons.chat_bubble_outline,
                        label: "${event['commentCount'] ?? 0}",
                        onTap: () => _openComments(context),
                      ),
                      const SizedBox(height: 16),
                      LikeButton(
                        postId: event['id'],
                        likes: List<String>.from(
                            event['likes'] ?? []),
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

  /// ─────────────────────────────
  /// MEDIA BUILDER (IMAGE + VIDEO)
  /// ─────────────────────────────
  Widget _buildMedia() {
    if (_mediaUrl.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child:
            const Icon(Icons.broken_image, color: Colors.white24),
      );
    }

    if (_mediaType == 'video') {
      return _VideoPlayerWidget(url: _mediaUrl);
    }

    return Image.network(
      _mediaUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[900],
        child: const Icon(Icons.broken_image,
            color: Colors.white24),
      ),
    );
  }

  /// ─── USER HEADER ───
  Widget _buildUserHeader(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getCreatorData(),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final username = userData?['username'] ?? '...';
        final photo = userData?['photoURL'];

        return GestureDetector(
          onTap: () {
            if (_creatorId != null) {
              context.push('/user/$_creatorId');
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage:
                    photo != null ? NetworkImage(photo) : null,
                backgroundColor: Colors.white24,
              ),
              const SizedBox(width: 8),
              Text(
                "@$username",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ],
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
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          event['title'] ?? '',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        Text(
          event['location'] ?? '',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildPostCaption() {
    return Text(
      event['content'] ?? '',
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            backgroundColor: Colors.black45,
            child: Icon(icon, color: Colors.white),
          ),
        ),
        if (label != null)
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Future<void> _toggleBookmark(
      BuildContext context, String uid) async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(event['id']);

    final doc = await ref.get();

    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set(event);
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
  State<_VideoPlayerWidget> createState() =>
      _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.network(widget.url)
          ..initialize().then((_) {
            setState(() {});
            _controller.setLooping(true);
            _controller.play();
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container(color: Colors.black);
    }

    return GestureDetector(
      onTap: () {
        if (_controller.value.isPlaying) {
          _controller.pause();
        } else {
          _controller.play();
        }
        setState(() {});
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          if (!_controller.value.isPlaying)
            const Icon(Icons.play_circle_fill,
                color: Colors.white, size: 60),
        ],
      ),
    );
  }
}