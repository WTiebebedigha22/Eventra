import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isSending = false;

  // --- Theme Colors ---
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Colors.white;
  static const Color inputBg = Color(0xFFF8F9FA);
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

  Future<void> _postComment() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _commentController.text.trim();
    
    if (user == null || text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    HapticFeedback.lightImpact();

    try {
      // 1. Reference to the specific event
      final eventRef = FirebaseFirestore.instance.collection('events').doc(widget.postId);

      // 2. Safety Check: Verify parent document exists to prevent NOT_FOUND error
      final eventDoc = await eventRef.get();
      
      if (!eventDoc.exists) {
        throw "The event you are commenting on no longer exists.";
      }

      final batch = FirebaseFirestore.instance.batch();
      
      // 3. Prepare Comment Reference
      final commentRef = eventRef.collection('comments').doc();

      batch.set(commentRef, {
        'text': text,
        'userName': user.displayName ?? 'Guest User',
        'userProfile': user.photoURL ?? '',
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Update the parent counter
      batch.update(eventRef, {
        'commentCount': FieldValue.increment(1),
      });

      // Execute atomic transaction
      await batch.commit();
      
      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Comments", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor)
            ),
          ),
          const Divider(height: 1, thickness: 0.5),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return _buildErrorState();
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildCommentTile(data);
                  },
                );
              },
            ),
          ),

          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> data) {
    final DateTime? date = (data['createdAt'] as Timestamp?)?.toDate();
    final timeStr = date != null ? DateFormat('h:mm a').format(date) : "just now";

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: inputBg,
            backgroundImage: (data['userProfile']?.toString().isNotEmpty ?? false)
                ? NetworkImage(data['userProfile'])
                : null,
            child: (data['userProfile']?.toString().isEmpty ?? true)
                ? const Icon(Icons.person_rounded, color: Colors.grey, size: 20)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data['userName'] ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                    ),
                    Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data['text'] ?? '',
                  style: const TextStyle(fontSize: 14, color: subtleText, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              decoration: InputDecoration(
                hintText: "Add a comment...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                filled: true,
                fillColor: inputBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isSending ? null : _postComment,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: _isSending ? Colors.grey[300] : primaryColor,
              child: _isSending 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text("No comments yet", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
          const Text("Be the first to say something!", style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Text("Unable to load comments", style: TextStyle(color: Colors.redAccent)),
    );
  }
}