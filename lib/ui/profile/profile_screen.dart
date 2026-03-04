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
  bool isLoadingFollow = false;

  static const Color tiktokRed = Color(0xFFFE2C55);

  @override
  void initState() {
    super.initState();
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

  // --- ACTIONS ---

  Future<void> _toggleFollow() async {
    if (isLoadingFollow) return;
    HapticFeedback.mediumImpact();

    setState(() {
      isFollowing = !isFollowing;
      isLoadingFollow = true;
    });

    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(currentUid);

    try {
      if (isFollowing) {
        await userRef.collection('followers').doc(currentUid).set({'followedAt': FieldValue.serverTimestamp()});
        await userRef.update({'followerCount': FieldValue.increment(1)});
        await currentUserRef.update({'followingCount': FieldValue.increment(1)});
      } else {
        await userRef.collection('followers').doc(currentUid).delete();
        await userRef.update({'followerCount': FieldValue.increment(-1)});
        await currentUserRef.update({'followingCount': FieldValue.increment(-1)});
      }
    } catch (e) {
      if (mounted) setState(() => isFollowing = !isFollowing);
    } finally {
      if (mounted) setState(() => isLoadingFollow = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMe = widget.userId == currentUid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(isMe ? "My Profile" : "Profile", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: !isMe ? const BackButton(color: Colors.black) : null,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildHeaderAvatar(userData, isMe),
                      const SizedBox(height: 12),
                      Text("@${userData['username'] ?? 'user'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 16),
                      _buildStatsRow(userData),
                      const SizedBox(height: 20),
                      _buildActionButtons(isMe),
                      const SizedBox(height: 16),
                      if (userData['bio'] != null)
                        Text(userData['bio'], style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                _buildTikTokTabBar(),
              ],
              body: TabBarView(
                children: [
                  _buildPostsGrid(), // Tab 1: User's Posts
                  _buildLikedGrid(), // Tab 2: Posts User Liked
                  _buildSavedGrid(), // Tab 3: User's Bookmarks
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeaderAvatar(Map<String, dynamic> data, bool isMe) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 45,
          backgroundImage: data['photoURL'] != null ? NetworkImage(data['photoURL']) : null,
          child: data['photoURL'] == null ? const Icon(Icons.person, size: 40) : null,
        ),
        if (isMe)
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              child: const Icon(Icons.add, size: 14, color: Colors.white),
            ),
          )
      ],
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _statItem("${data['followingCount'] ?? 0}", "Following"),
        _divider(),
        _statItem("${data['followerCount'] ?? 0}", "Followers"),
        _divider(),
        _statItem("${data['totalLikes'] ?? 0}", "Likes"),
      ],
    );
  }

  Widget _statItem(String count, String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    child: Column(children: [
      Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
    ]),
  );

  Widget _divider() => Container(height: 15, width: 1, color: Colors.black12);

  Widget _buildActionButtons(bool isMe) {
    if (isMe) {
      return _wideButton("Edit Profile", Colors.white, Colors.black, () => context.push('/edit-profile'));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(child: _wideButton(isFollowing ? "Unfollow" : "Follow", isFollowing ? Colors.white : tiktokRed, isFollowing ? Colors.black : Colors.white, _toggleFollow)),
          const SizedBox(width: 8),
          _squareButton(Icons.send_outlined, () {}),
        ],
      ),
    );
  }

  Widget _wideButton(String text, Color bg, Color txtColor, VoidCallback onTap) => Container(
    height: 45,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg, elevation: 0,
        side: const BorderSide(color: Colors.black12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(text, style: TextStyle(color: txtColor, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _squareButton(IconData icon, VoidCallback onTap) => Container(
    height: 45, width: 45,
    decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(4)),
    child: IconButton(icon: Icon(icon, size: 20, color: Colors.black), onPressed: onTap),
  );

  Widget _buildTikTokTabBar() => SliverPersistentHeader(
    pinned: true,
    delegate: _SliverAppBarDelegate(
      const TabBar(
        indicatorColor: Colors.black,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        tabs: [
          Tab(icon: Icon(Icons.grid_on_outlined)),
          Tab(icon: Icon(Icons.favorite_border_rounded)),
          Tab(icon: Icon(Icons.bookmark_outline_rounded)),
        ],
      ),
    ),
  );

  // --- DATA GRIDS ---

  Widget _buildPostsGrid() {
    return _buildBaseGrid(
      FirebaseFirestore.instance.collection('posts').where('creatorId', isEqualTo: widget.userId).snapshots(),
      "No posts yet",
    );
  }

  Widget _buildLikedGrid() {
    // Queries posts where the current profile owner's UID is in the likedBy array
    return _buildBaseGrid(
      FirebaseFirestore.instance.collection('posts').where('likedBy', arrayContains: widget.userId).snapshots(),
      "No liked posts",
    );
  }

  Widget _buildSavedGrid() {
    // Queries the specific user's bookmarks collection
    return _buildBaseGrid(
      FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('bookmarks').snapshots(),
      "No saved items",
    );
  }

  Widget _buildBaseGrid(Stream<QuerySnapshot> stream, String emptyMsg) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return Center(child: Text(emptyMsg, style: const TextStyle(color: Colors.grey)));

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, childAspectRatio: 3/4, crossAxisSpacing: 1, mainAxisSpacing: 1,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Image.network(data['mediaUrl'] ?? '', fit: BoxFit.cover);
          },
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(context, offset, overlaps) => Container(color: Colors.white, child: _tabBar);
  @override bool shouldRebuild(_SliverAppBarDelegate old) => false;
}