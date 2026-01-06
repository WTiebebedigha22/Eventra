import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final String commentText = _commentController.text.trim();
    _commentController.clear();

    try {
      // Get current user data for the comment snapshot
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
      final userData = userDoc.data() as Map<String, dynamic>;

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'text': commentText,
        'uid': currentUid,
        'username': userData['username'],
        'profilePic': userData['photoURL'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Increment comment count on the post
      await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint("Error posting comment: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildCommentList()),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 50, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 10),
                Text("No comments yet. Start the conversation!", 
                  style: TextStyle(color: Colors.white.withOpacity(0.4))),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return _commentTile(data);
          },
        );
      },
    );
  }

  Widget _commentTile(Map<String, dynamic> data) {
    // Format timestamp
    String timeAgo = "";
    if (data['createdAt'] != null) {
      final DateTime date = (data['createdAt'] as Timestamp).toDate();
      timeAgo = DateFormat.jm().format(date); // Example: 9:41 AM
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: data['profilePic'] != null ? NetworkImage(data['profilePic']) : null,
            child: data['profilePic'] == null ? const Icon(Icons.person, size: 20) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    children: [
                      TextSpan(text: "${data['username']} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: data['text']),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(timeAgo, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
        left: 16,
        right: 8,
        top: 10,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF181818),
        border: Border(top: BorderSide(color: Color(0xFF262626))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Add a comment...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                border: InputBorder.none,
              ),
            ),
          ),
          TextButton(
            onPressed: _postComment,
            child: const Text("Post", 
              style: TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}