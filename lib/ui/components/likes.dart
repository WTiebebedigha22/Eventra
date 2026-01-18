import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikeButton extends StatelessWidget {
  final String postId;
  final List<String> likes;

  const LikeButton({super.key, required this.postId, required this.likes});

  // --- Theme Colors ---
  static const Color likedColor = Color(0xFFE91E63); // Vibrant Heart Red
  static const Color unlikedColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bool isLiked = likes.contains(uid);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _handleLike(uid),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // Using a translucent background to match the Bookmark/Comment buttons
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                key: ValueKey<bool>(isLiked),
                color: isLiked ? likedColor : unlikedColor,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "${likes.length}",
          style: const TextStyle(
            color: Colors.white, // Changed to white for visibility on Card gradient
            fontSize: 12, 
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(0, 1))
            ]
          ),
        ),
      ],
    );
  }

  Future<void> _handleLike(String uid) async {
    if (uid.isEmpty) return;

    // Trigger haptics immediately for responsiveness
    HapticFeedback.mediumImpact();

    final docRef = FirebaseFirestore.instance.collection('events').doc(postId);

    try {
      if (likes.contains(uid)) {
        await docRef.update({
          'likes': FieldValue.arrayRemove([uid])
        });
      } else {
        await docRef.update({
          'likes': FieldValue.arrayUnion([uid])
        });
      }
    } catch (e) {
      debugPrint("Error updating likes: $e");
    }
  }
}