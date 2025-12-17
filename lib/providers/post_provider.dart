import 'dart:io';
import 'package:flutter/foundation.dart';
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

  // --- State for Pagination ---
  final List<Post> _posts = [];
  List<Post> get posts => _posts;
  
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

  // --- Standardized Feed Logic (Pagination) ---
  
  /// Fetches the first page or next page of posts
  Future<void> fetchPosts({bool isRefresh = false}) async {
    if (_isLoading || (!_hasMore && !isRefresh)) return;

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
        _posts.addAll(snapshot.docs.map((doc) => Post.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList());
      }
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Interaction Logic ---
  Future<void> toggleLike(String postId, List<String> currentLikes, String postAuthorId, String senderName) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final bool isLiked = currentLikes.contains(uid);
    final postRef = _firestore.collection('posts').doc(postId);

    try {
      if (isLiked) {
        await postRef.update({'likes': FieldValue.arrayRemove([uid])});
      } else {
        await postRef.update({'likes': FieldValue.arrayUnion([uid])});
        if (uid != postAuthorId) {
          await _sendNotification(
            receiverId: postAuthorId,
            senderName: senderName,
            type: 'like',
            message: 'liked your post.',
          );
        }
      }
      // Update local state to reflect UI change immediately
      int index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        isLiked ? _posts[index].likes.remove(uid) : _posts[index].likes.add(uid);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Like error: $e');
    }
  }

  // --- Image Compression ---
  Future<File?> _compressImage(File file) async {
    final dir = await path_provider.getTemporaryDirectory();
    final targetPath = "${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg";

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70, // Reduces size significantly without visible quality loss
    );

    return result != null ? File(result.path) : null;
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
        // Apply compression
        File? compressedFile = await _compressImage(mediaFile);
        if (compressedFile != null) {
          final storageRef = _storage.ref().child('posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}');
          final uploadTask = await storageRef.putFile(compressedFile);
          mediaUrl = await uploadTask.ref.getDownloadURL();
        }
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
      await fetchPosts(isRefresh: true); // Reload feed to show new post
    } catch (e) {
      debugPrint('Create post error: $e');
      throw Exception('Failed to create post.');
    }
  }
}