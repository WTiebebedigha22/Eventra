import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class SocialService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  // Toggle Like: Adds/Removes UID from the likes array
  Future<void> toggleLike(String postId, List likes) async {
    if (_uid == null) return;
    HapticFeedback.mediumImpact();
    
    DocumentReference postRef = _db.collection('posts').doc(postId);
    if (likes.contains(_uid)) {
      await postRef.update({'likes': FieldValue.arrayRemove([_uid])});
    } else {
      await postRef.update({'likes': FieldValue.arrayUnion([_uid])});
    }
  }

  // Add Comment: Uses a Batch to add the comment and increment the count
  Future<void> addComment(String postId, String text) async {
    if (_uid == null || text.trim().isEmpty) return;

    WriteBatch batch = _db.batch();
    DocumentReference commentRef = _db.collection('posts').doc(postId).collection('comments').doc();
    DocumentReference postRef = _db.collection('posts').doc(postId);

    batch.set(commentRef, {
      'userId': _uid,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    batch.update(postRef, {'commentCount': FieldValue.increment(1)});
    await batch.commit();
  }

  // Share: Increments counter and opens system dialog
  Future<void> sharePost(String postId, String postText) async {
    HapticFeedback.lightImpact();
    await _db.collection('posts').doc(postId).update({
      'shareCount': FieldValue.increment(1)
    });
    await Share.share("Check out this post: $postText");
  }
}