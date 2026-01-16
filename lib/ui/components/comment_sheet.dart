import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();

  Future<void> _postComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _commentController.text.trim().isEmpty) return;

    final commentText = _commentController.text.trim();
    _commentController.clear();

    final batch = FirebaseFirestore.instance.batch();
    final commentRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.postId)
        .collection('comments')
        .doc();

    batch.set(commentRef, {
      'text': commentText,
      'userName': user.displayName ?? 'Anonymous',
      'userProfile': user.photoURL ?? '', // Captures the Google/Firebase profile pic
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(FirebaseFirestore.instance.collection('events').doc(widget.postId), {
      'commentCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Drag Indicator
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          height: 4, width: 40,
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
        ),
        const Text("Comments", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(color: Color(0xFF262626), height: 30),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .doc(widget.postId)
                .collection('comments')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)));
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  String profilePic = doc['userProfile'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PROFILE PICTURE
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white10,
                          backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                          child: profilePic.isEmpty ? const Icon(Icons.person, color: Colors.white54, size: 20) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doc['userName'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(doc['text'], style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        // INPUT FIELD
        Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
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
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF0F0F0F),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFFE91E63),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: _postComment,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}