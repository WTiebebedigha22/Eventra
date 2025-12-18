import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PostService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getPostsStream() {
    return _db.collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // CREATE: Add a new event post
  Future<void> createPost({
    required String title,
    required String description,
    required String imageUrl,
    required String category,
    required double price,
    required String date,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('posts').add({
      'authorId': uid,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'price': price,
      'date': date,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}