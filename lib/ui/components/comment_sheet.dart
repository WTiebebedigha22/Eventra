import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
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
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;
  String? _replyingToCommentId;
  String? _replyingToUserName;

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color backgroundColor = Colors.white;
  static const Color inputBg = Color(0xFFF8F9FA);
  static const Color dividerColor = Color(0xFFEEF2F6);

  DocumentReference get _parentRef =>
      FirebaseFirestore.instance.collection(widget.collection).doc(widget.postId.trim());

  @override
  void initState() {
    super.initState();
  }

  void _setReply(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  Future<void> _toggleLike(String commentId, List likedBy) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    HapticFeedback.lightImpact();
    final docRef = _parentRef.collection('comments').doc(commentId);

    try {
      if (likedBy.contains(uid)) {
        await docRef.update({'likedBy': FieldValue.arrayRemove([uid])});
      } else {
        await docRef.update({'likedBy': FieldValue.arrayUnion([uid])});
      }
    } catch (e) {
      debugPrint("Error toggling like: $e");
    }
  }

  Future<void> _postComment() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _commentController.text.trim();
    if (user == null || text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final batch = FirebaseFirestore.instance.batch();

    try {
      if (_replyingToCommentId != null) {
        // REPLY
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
        // MAIN COMMENT
        final commentRef = _parentRef.collection('comments').doc();
        batch.set(commentRef, {
          'text': text,
          'userName': user.displayName ?? 'User',
          'userProfile': user.photoURL ?? '',
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'likedBy': [],
        });
        
        // Increment comment count
        batch.update(_parentRef, {
          'commentCount': FieldValue.increment(1)
        });
      }

      await batch.commit();
      _commentController.clear();
      _cancelReply();
      FocusScope.of(context).unfocus();
      
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint("_postComment error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post comment: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
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
              stream: _parentRef
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: primaryColor));
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) => _buildCommentItem(docs[index], index == docs.length - 1),
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "No comments yet",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Be the first to comment!",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(DocumentSnapshot doc, bool isLast) {
    final data = doc.data() as Map<String, dynamic>;
    final List likedBy = data['likedBy'] ?? [];
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final bool isLiked = likedBy.contains(currentUid);
    final DateTime createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final timeAgo = _formatTimeAgo(createdAt);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(data['userProfile'], data['uid']),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          data['userName'] ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['text'] ?? '',
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildActionBtn(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          likedBy.length.toString(),
                          color: isLiked ? Colors.red : Colors.grey[600],
                          onTap: () => _toggleLike(doc.id, likedBy),
                        ),
                        const SizedBox(width: 20),
                        _buildActionBtn(
                          Icons.reply_rounded,
                          "Reply",
                          color: Colors.grey[600],
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
        if (!isLast) const Divider(height: 1, indent: 60, color: dividerColor),
      ],
    );
  }

  Widget _buildAvatar(String? url, String? uid) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = currentUid == uid;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: (url != null && url.isNotEmpty) ? CachedNetworkImageProvider(url) : null,
          backgroundColor: Colors.grey.shade200,
          child: (url == null || url.isEmpty) ? const Icon(Icons.person, size: 20) : null,
        ),
        if (!isMe && uid != null && uid.isNotEmpty)
          Positioned(
            bottom: -2,
            right: -2,
            child: GestureDetector(
              onTap: () => _toggleFollow(uid),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_alt, size: 10, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _toggleFollow(String targetUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid == targetUid) return;

    HapticFeedback.mediumImpact();
    final batch = FirebaseFirestore.instance.batch();
    final followRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(targetUid);

    final doc = await followRef.get();

    try {
      if (doc.exists) {
        batch.delete(followRef);
      } else {
        batch.set(followRef, {'timestamp': FieldValue.serverTimestamp()});
      }
      await batch.commit();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(doc.exists ? 'Unfollowed' : 'Following'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint("Error toggling follow: $e");
    }
  }

  Widget _buildActionBtn(IconData icon, String label, {Color? color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color ?? Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildRepliesList(String parentId) {
    return StreamBuilder<QuerySnapshot>(
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
          padding: const EdgeInsets.only(top: 12),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final reply = snapshot.data!.docs[index];
              final r = reply.data() as Map<String, dynamic>;
              final replyTime = (r['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
              final replyTimeAgo = _formatTimeAgo(replyTime);
              
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: (r['userProfile'] != null && r['userProfile'].isNotEmpty)
                        ? CachedNetworkImageProvider(r['userProfile'])
                        : null,
                    backgroundColor: Colors.grey.shade200,
                    child: (r['userProfile'] == null || r['userProfile'].isEmpty)
                        ? const Icon(Icons.person, size: 12)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              r['userName'] ?? 'User',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              replyTimeAgo,
                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r['text'] ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
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
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            "Comments",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const Divider(height: 1, color: dividerColor),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingToUserName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 14, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Replying to $_replyingToUserName",
                      style: TextStyle(fontSize: 12, color: primaryColor),
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: "Add a comment...",
                    filled: true,
                    fillColor: inputBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  onPressed: _isSending ? null : _postComment,
                  icon: Icon(
                    Icons.send_rounded,
                    color: _isSending ? Colors.grey : primaryColor,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _isSending ? Colors.grey.shade100 : primaryColor.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}