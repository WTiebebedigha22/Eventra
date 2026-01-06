import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class LikeButton extends StatefulWidget {
  final String postId;
  final List<dynamic> likes; // Initial list of UIDs who liked

  const LikeButton({
    super.key, 
    required this.postId, 
    required this.likes
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    // Check if user already liked this post
    isLiked = widget.likes.contains(currentUid);

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleLike() async {
    HapticFeedback.lightImpact();
    _controller.forward(from: 0.0);

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    setState(() {
      isLiked = !isLiked;
    });

    if (isLiked) {
      // Add UID to likes array and increment count
      await postRef.update({
        'likes': FieldValue.arrayUnion([currentUid]),
        'likeCount': FieldValue.increment(1),
      });
    } else {
      // Remove UID from likes array and decrement count
      await postRef.update({
        'likes': FieldValue.arrayRemove([currentUid]),
        'likeCount': FieldValue.increment(-1),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? const Color(0xFFE91E63) : Colors.white,
          size: 28,
        ),
        onPressed: _handleLike,
      ),
    );
  }
}