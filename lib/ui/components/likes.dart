import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikeButton extends StatelessWidget {
  final String postId;
  final List<String> likes;

  const LikeButton({super.key, required this.postId, required this.likes});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bool isLiked = likes.contains(uid);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            color: isLiked ? const Color(0xFFE91E63) : Colors.white,
            size: 26,
          ),
          onPressed: () => _handleLike(uid),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
        ),
        Text(
          "${likes.length}",
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Future<void> _handleLike(String uid) async {
    if (uid.isEmpty) return;
    HapticFeedback.mediumImpact();

    final docRef = FirebaseFirestore.instance.collection('events').doc(postId);

    if (likes.contains(uid)) {
      await docRef.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await docRef.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }
}