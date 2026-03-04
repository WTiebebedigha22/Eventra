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
  final FocusNode _commentFocusNode = FocusNode();
  
  bool _isSending = false;
  String? _replyingToCommentId;
  String? _replyingToUserName;

  // --- Theme ---
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Colors.white;
  static const Color inputBg = Color(0xFFF8F9FA);
  static const Color textColor = Color(0xFF1C1E21);

  void _setReply(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
    });
    _commentFocusNode.requestFocus();
  }

  Future<void> _toggleLike(String commentId, List likedBy) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId);

    if (likedBy.contains(uid)) {
      await docRef.update({'likedBy': FieldValue.arrayRemove([uid])});
    } else {
      HapticFeedback.lightImpact();
      await docRef.update({'likedBy': FieldValue.arrayUnion([uid])});
    }
  }

  Future<void> _toggleFollow(String targetUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid == targetUid) return;

    final batch = FirebaseFirestore.instance.batch();
    final followRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid).collection('following').doc(targetUid);
    
    // For simplicity, we assume if the doc exists, we unfollow. 
    // In a production app, check state first.
    final doc = await followRef.get();
    
    if (doc.exists) {
      batch.delete(followRef);
    } else {
      HapticFeedback.mediumImpact();
      batch.set(followRef, {'timestamp': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  Future<void> _postComment() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _commentController.text.trim();
    if (user == null || text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final batch = FirebaseFirestore.instance.batch();
    final eventRef = FirebaseFirestore.instance.collection('events').doc(widget.postId.trim());

    try {
      if (_replyingToCommentId != null) {
        // --- POSTING A REPLY ---
        final replyRef = eventRef.collection('comments').doc(_replyingToCommentId).collection('replies').doc();
        batch.set(replyRef, {
          'text': text,
          'userName': user.displayName ?? 'User',
          'userProfile': user.photoURL ?? '',
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // --- POSTING A MAIN COMMENT ---
        final commentRef = eventRef.collection('comments').doc();
        batch.set(commentRef, {
          'text': text,
          'userName': user.displayName ?? 'User',
          'userProfile': user.photoURL ?? '',
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'likedBy': [],
        });
        batch.set(eventRef, {'commentCount': FieldValue.increment(1)}, SetOptions(merge: true));
      }

      await batch.commit();
      _commentController.clear();
      setState(() { _replyingToCommentId = null; _replyingToUserName = null; });
      FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('events').doc(widget.postId).collection('comments').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) => _buildCommentItem(docs[index]),
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildCommentItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final List likedBy = data['likedBy'] ?? [];
    final bool isLiked = likedBy.contains(FirebaseAuth.instance.currentUser?.uid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatarWithFollow(data['userProfile'], data['uid']),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['userName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(data['text'], style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildActionBtn(isLiked ? Icons.favorite : Icons.favorite_border, "${likedBy.length}", 
                          color: isLiked ? Colors.red : Colors.grey, onTap: () => _toggleLike(doc.id, likedBy)),
                        const SizedBox(width: 20),
                        _buildActionBtn(Icons.reply_rounded, "Reply", onTap: () => _setReply(doc.id, data['userName'])),
                      ],
                    ),
                    _buildRepliesList(doc.id), // Recursive-ish replies
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 50),
      ],
    );
  }

  Widget _buildAvatarWithFollow(String? url, String uid) {
    final isMe = FirebaseAuth.instance.currentUser?.uid == uid;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(radius: 20, backgroundImage: url != null ? NetworkImage(url) : null, child: url == null ? const Icon(Icons.person) : null),
        if (!isMe)
          Positioned(
            bottom: -4,
            right: -4,
            child: GestureDetector(
              onTap: () => _toggleFollow(uid),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                child: const Icon(Icons.add, size: 12, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRepliesList(String parentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').doc(widget.postId).collection('comments').doc(parentId).collection('replies').orderBy('createdAt', descending: false).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: snapshot.data!.docs.map((d) {
              final r = d.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(radius: 10, backgroundImage: NetworkImage(r['userProfile'])),
                    const SizedBox(width: 8),
                    Expanded(child: Text("${r['userName']} ${r['text']}", style: const TextStyle(fontSize: 12))),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildActionBtn(IconData icon, String label, {Color color = Colors.grey, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 12, color: color))]),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingToUserName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Text("Replying to $_replyingToUserName", style: const TextStyle(fontSize: 12, color: primaryColor)),
                const Spacer(),
                GestureDetector(onTap: () => setState(() => _replyingToUserName = null), child: const Icon(Icons.close, size: 14)),
              ]),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  decoration: InputDecoration(hintText: "Add a comment...", filled: true, fillColor: inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: _isSending ? null : _postComment, icon: Icon(Icons.send_rounded, color: _isSending ? Colors.grey : primaryColor)),
            ],
          ),
        ],
      ),
    );
  }
}