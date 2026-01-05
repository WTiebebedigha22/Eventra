import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({required this.userId, super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool isFollowing = false;
  static const Color primaryPink = Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    // Only check follow status if we are looking at someone else
    if (widget.userId != currentUid) {
      _checkFollowStatus();
    }
  }

  void _checkFollowStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('followers')
        .doc(currentUid)
        .get();
    if (mounted) setState(() => isFollowing = doc.exists);
  }

  Future<void> _toggleFollow() async {
    HapticFeedback.mediumImpact();
    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(currentUid);
    final followerRef = userRef.collection('followers').doc(currentUid);

    setState(() => isFollowing = !isFollowing);

    if (isFollowing) {
      await followerRef.set({'followedAt': FieldValue.serverTimestamp()});
      await userRef.update({'followerCount': FieldValue.increment(1)});
      await currentUserRef.update({'followingCount': FieldValue.increment(1)});
    } else {
      await followerRef.delete();
      await userRef.update({'followerCount': FieldValue.increment(-1)});
      await currentUserRef.update({'followingCount': FieldValue.increment(-1)});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMe = widget.userId == currentUid;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Only show back button if we pushed this screen (looking at someone else)
        leading: !isMe ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ) : null,
        title: Text(isMe ? "My Profile" : "Profile", 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (isMe) IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => context.push('/settings'),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryPink));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User not found", style: TextStyle(color: Colors.white)));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildProfileHeader(userData),
                _buildStatsRow(userData),
                
                // Dynamic Action Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: isMe 
                    ? _buildActionButton("Edit Profile", Colors.white10, () => context.push('/profile/edit'))
                    : _buildActionButton(
                        isFollowing ? "Unfollow" : "Follow", 
                        isFollowing ? Colors.white12 : primaryPink, 
                        _toggleFollow
                      ),
                ),

                const Divider(color: Color(0xFF262626), height: 40),
                
                // Grid of User's Posts
                _buildUserPostsGrid(widget.userId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> data) {
    return Column(
      children: [
        CircleAvatar(
          radius: 45,
          backgroundColor: const Color(0xFF262626),
          backgroundImage: data['photoURL'] != null ? NetworkImage(data['photoURL']) : null,
          child: data['photoURL'] == null ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
        ),
        const SizedBox(height: 12),
        Text("@${data['username']}", 
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        if (data['bio'] != null) Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
          child: Text(data['bio'], textAlign: TextAlign.center, 
            style: TextStyle(color: Colors.white.withOpacity(0.6))),
        ),
      ],
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem("Posts", data['postCount'] ?? 0),
          _statItem("Followers", data['followerCount'] ?? 0),
          _statItem("Following", data['followingCount'] ?? 0),
        ],
      ),
    );
  }

  Widget _statItem(String label, int count) {
    return Column(
      children: [
        Text("$count", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback action) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildUserPostsGrid(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').where('creatorId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
          itemBuilder: (context, index) {
            final post = docs[index].data() as Map<String, dynamic>;
            return Image.network(post['imageUrl'], fit: BoxFit.cover);
          },
        );
      },
    );
  }
}