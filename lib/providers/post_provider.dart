import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/posts/post.dart';

class PostProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Notification Engine ---
  
  /// Internal helper to write a notification to Firestore
  Future<void> _sendNotification({
    required String receiverId,
    required String senderName,
    required String type, // 'like', 'comment', 'booking'
    required String message,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': receiverId,
        'title': '$senderName $message',
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'senderId': _auth.currentUser?.uid,
      });
    } catch (e) {
      debugPrint('Notification failed to send: $e');
    }
  }

  // --- Feed Stream ---
  Stream<List<Post>> get postsStream {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  // --- Interaction Logic ---

  /// Toggles like status and triggers notification
  Future<void> toggleLike(String postId, List<String> currentLikes, String postAuthorId, String senderName) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final bool isLiked = currentLikes.contains(uid);
    final postRef = _firestore.collection('posts').doc(postId);

    try {
      if (isLiked) {
        // Unlike
        await postRef.update({
          'likes': FieldValue.arrayRemove([uid])
        });
      } else {
        // Like
        await postRef.update({
          'likes': FieldValue.arrayUnion([uid])
        });

        // Only send notification if liking someone else's post
        if (uid != postAuthorId) {
          await _sendNotification(
            receiverId: postAuthorId,
            senderName: senderName,
            type: 'like',
            message: 'liked your post.',
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  // --- Post Creation Logic ---
  Future<void> createPost({
    required String content,
    File? mediaFile,
    DateTime? eventDate,
    String? location,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in.");

    String? mediaUrl;

    try {
      if (mediaFile != null) {
        final storageRef = _storage.ref().child('posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}');
        final uploadTask = storageRef.putFile(mediaFile);
        final snapshot = await uploadTask.whenComplete(() {});
        mediaUrl = await snapshot.ref.getDownloadURL();
      }

      final postData = Post(
        id: '', 
        userId: user.uid,
        content: content,
        mediaUrl: mediaUrl,
        timestamp: DateTime.now(), 
        eventDate: eventDate,
        location: location,
      ).toFirestore();

      await _firestore.collection('posts').add(postData);
    } catch (e) {
      debugPrint('Error creating post: $e');
      throw Exception('Failed to create post. Please try again.');
    }
  }
}