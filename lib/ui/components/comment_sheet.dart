//improve this

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  // ✅ FIX: pass 'posts' or 'events' depending on where it's opened from
  // Defaults to 'posts' — pass 'events' when opening from EventDetailScreen
  final String collection;

  const CommentsScreen({
    super.key,
    required this.postId,
    this.collection = 'posts',
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  bool _isSending = false;
  String? _replyingToCommentId;
  String? _replyingToUserName;

  static const Color primaryColor = Colors.deepPurpleAccent;
  static const Color backgroundColor = Colors.white;
  static const Color inputBg = Color(0xFFF8F9FA);

  // ✅ FIX: single source of truth for the parent document reference
  DocumentReference get _parentRef =>
      FirebaseFirestore.instance.collection(widget.collection).doc(widget.postId.trim());

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

    final docRef = _parentRef.collection('comments').doc(commentId);

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
    final followRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(targetUid);

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

    try {
      if (_replyingToCommentId != null) {
        // --- REPLY ---
        final replyRef = _parentRef
            .collection('comments')
            .doc(_replyingToCommentId)
            .collection('replies')
            .doc();
        batch.set(replyRef, {
          'text': text,
          'userName': user.displayName ?? 'User',
          'userProfile': user.photoURL ?? '',
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // --- MAIN COMMENT ---
        final commentRef = _parentRef.collection('comments').doc();
        batch.set(commentRef, {
          'text': text,
          'userName': user.displayName ?? 'User',
          'userProfile': user.photoURL ?? '',
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'likedBy': [],
        });
        // ✅ increment commentCount on the correct parent doc
        batch.set(_parentRef, {'commentCount': FieldValue.increment(1)},
            SetOptions(merge: true));
      }

      await batch.commit();
      _commentController.clear();
      setState(() {
        _replyingToCommentId = null;
        _replyingToUserName = null;
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint("_postComment error: $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // ✅ FIX: uses _parentRef so collection is always correct
              stream: _parentRef
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint(">> Comments error: ${snapshot.error}");
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: primaryColor));
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No comments yet.\nBe the first to comment!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) =>
                      _buildCommentItem(docs[index]),
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
    final bool isLiked =
        likedBy.contains(FirebaseAuth.instance.currentUser?.uid);

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
                    Text(data['userName'] ?? 'User',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(data['text'] ?? '',
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildActionBtn(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          "${likedBy.length}",
                          color: isLiked ? Colors.red : Colors.grey,
                          onTap: () => _toggleLike(doc.id, likedBy),
                        ),
                        const SizedBox(width: 20),
                        _buildActionBtn(
                          Icons.reply_rounded,
                          "Reply",
                          onTap: () => _setReply(doc.id, data['userName'] ?? 'User'),
                        ),
                      ],
                    ),
                    _buildRepliesList(doc.id),
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

  Widget _buildAvatarWithFollow(String? url, String? uid) {
    final isMe = FirebaseAuth.instance.currentUser?.uid == uid;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage:
              (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
          child: (url == null || url.isEmpty)
              ? const Icon(Icons.person)
              : null,
        ),
        if (!isMe && uid != null)
          Positioned(
            bottom: -4,
            right: -4,
            child: GestureDetector(
              onTap: () => _toggleFollow(uid),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                    color: primaryColor, shape: BoxShape.circle),
                child:
                    const Icon(Icons.add, size: 12, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRepliesList(String parentId) {
    return StreamBuilder<QuerySnapshot>(
      // ✅ FIX: uses _parentRef so replies are also in the correct collection
      stream: _parentRef
          .collection('comments')
          .doc(parentId)
          .collection('replies')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: snapshot.data!.docs.map((d) {
              final r = d.data() as Map<String, dynamic>;
              final profileUrl = r['userProfile'] as String?;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundImage: (profileUrl != null &&
                              profileUrl.isNotEmpty)
                          ? NetworkImage(profileUrl)
                          : null,
                      child: (profileUrl == null || profileUrl.isEmpty)
                          ? const Icon(Icons.person, size: 10)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black87),
                          children: [
                            TextSpan(
                              text: "${r['userName'] ?? 'User'} ",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: r['text'] ?? ''),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildActionBtn(IconData icon, String label,
      {Color color = Colors.grey, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color))
      ]),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text("Comments",
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingToUserName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Text("Replying to $_replyingToUserName",
                    style: const TextStyle(
                        fontSize: 12, color: primaryColor)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() {
                    _replyingToUserName = null;
                    _replyingToCommentId = null;
                  }),
                  child: const Icon(Icons.close, size: 14),
                ),
              ]),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  decoration: InputDecoration(
                    hintText: "Add a comment...",
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isSending ? null : _postComment,
                icon: Icon(Icons.send_rounded,
                    color: _isSending ? Colors.grey : primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}