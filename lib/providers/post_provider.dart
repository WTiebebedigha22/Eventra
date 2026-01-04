import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../models/posts/post.dart';

class PostProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- State ---
  final List<Post> _posts = [];
  List<Post> get posts => List.unmodifiable(_posts); // Encapsulation
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 10;

  // --- Notification Engine ---
  Future<void> _sendNotification({
    required String receiverId,
    required String senderName,
    required String type,
    required String message,
  }) async {
    try {
      if (_auth.currentUser?.uid == receiverId) return; // Don't notify self
      
      await _firestore.collection('notifications').add({
        'userId': receiverId,
        'title': '$senderName $message',
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'senderId': _auth.currentUser?.uid,
      });
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }

  // --- Pagination Logic ---
  Future<void> fetchPosts({bool isRefresh = false}) async {
    if (_isLoading) return;
    if (!isRefresh && !_hasMore) return;

    _isLoading = true;
    if (isRefresh) {
      _lastDocument = null;
      _hasMore = true;
    }
    notifyListeners();

    try {
      Query query = _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (isRefresh) _posts.clear();

      if (snapshot.docs.length < _pageSize) {
        _hasMore = false;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        for (var doc in snapshot.docs) {
          _posts.add(Post.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>));
        }
      }
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Interaction Logic ---
  Future<void> toggleLike(String postId, String postAuthorId, String senderName) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Find post in local state
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final Post post = _posts[index];
    final bool isLiked = post.likes.contains(uid);

    // 1. Optimistic UI Update
    if (isLiked) {
      post.likes.remove(uid);
    } else {
      post.likes.add(uid);
    }
    notifyListeners();

    // 2. Firebase Update
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      if (isLiked) {
        await postRef.update({'likes': FieldValue.arrayRemove([uid])});
      } else {
        await postRef.update({'likes': FieldValue.arrayUnion([uid])});
        await _sendNotification(
          receiverId: postAuthorId,
          senderName: senderName,
          type: 'like',
          message: 'liked your post.',
        );
      }
    } catch (e) {
      // 3. Rollback on failure
      if (isLiked) {
        _posts[index].likes.add(uid);
      } else {
        _posts[index].likes.remove(uid);
      }
      notifyListeners();
      debugPrint('Like error: $e');
    }
  }

  // --- Image Compression ---
  Future<File?> _compressImage(File file) async {
    try {
      final dir = await path_provider.getTemporaryDirectory();
      final targetPath = "${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg";

      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      debugPrint("Compression error: $e");
      return file; // Fallback to original if compression fails
    }
  }

  // --- Post Creation ---
  Future<void> createPost({
    required String content,
    File? mediaFile,
    DateTime? eventDate,
    String? location,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in.");

    try {
      String? mediaUrl;
      if (mediaFile != null) {
        File? compressedFile = await _compressImage(mediaFile);
        final storageRef = _storage.ref().child('posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        final uploadTask = await storageRef.putFile(compressedFile ?? mediaFile);
        mediaUrl = await uploadTask.ref.getDownloadURL();
      }

      final newPostRef = _firestore.collection('posts').doc();
      
      final postData = {
        'userId': user.uid,
        'content': content,
        'mediaUrl': mediaUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'eventDate': eventDate != null ? Timestamp.fromDate(eventDate) : null,
        'location': location,
        'likes': [],
      };

      await newPostRef.set(postData);
      
      // Refresh to show the new post at the top
      await fetchPosts(isRefresh: true);
    } catch (e) {
      debugPrint('Create post error: $e');
      throw Exception('Failed to create post: $e');
    }
  }
}