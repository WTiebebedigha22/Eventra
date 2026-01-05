import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/posts/post.dart';

class PostProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- State ---
  final List<Post> _posts = [];
  List<Post> get posts => List.unmodifiable(_posts); 
  
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
      if (_auth.currentUser?.uid == receiverId) return; 
      
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
      // Rollback on failure
      if (isLiked) {
        _posts[index].likes.add(uid);
      } else {
        _posts[index].likes.remove(uid);
      }
      notifyListeners();
    }
  }

  // --- Post Creation ---
  // Updated to receive a Post object from the UI (which already contains the ImgBB URL)
  Future<void> uploadPost(Post post) async {
    try {
      // 1. Save to Firestore
      // We use post.toFirestore() which now includes username and userProfileUrl
      final docRef = await _firestore.collection('posts').add(post.toFirestore());

      // 2. Local Update: Create a version of the post with the new ID for instant display
      final postWithId = Post(
        id: docRef.id,
        userId: post.userId,
        username: post.username,
        userProfileUrl: post.userProfileUrl,
        content: post.content,
        mediaUrl: post.mediaUrl,
        timestamp: DateTime.now(), // Local approximation until refresh
        likes: [],
        location: post.location,
        eventDate: post.eventDate,
      );

      _posts.insert(0, postWithId);
      notifyListeners();
    } catch (e) {
      debugPrint('Upload error: $e');
      throw Exception('Failed to upload post: $e');
    }
  }
  // --- Post Deletion ---
  Future<void> deletePost(String postId) async {
    // 1. Find the post and its index for a potential rollback
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final deletedPost = _posts[index];

    // 2. Optimistic UI Update: Remove locally first
    _posts.removeAt(index);
    notifyListeners();

    try {
      // 3. Delete from Firestore
      await _firestore.collection('posts').doc(postId).delete();
      
      // Optional: If you use Firebase Storage for images, 
      // you would delete the file here as well. 
      // If using ImgBB, the image remains on their servers.
      
      debugPrint('Post deleted successfully from Firestore');
    } catch (e) {
      // 4. Rollback: If Firestore fails, put the post back
      _posts.insert(index, deletedPost);
      notifyListeners();
      
      debugPrint('Error deleting post: $e');
      throw Exception('Could not delete post. Please try again.');
    }
  }
}