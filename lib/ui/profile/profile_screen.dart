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

  static const Color primaryColor = Color(0xFF3E5992);
  static const Color accentColor = Color(0xFFF1F4F9);

  @override
  void initState() {
    super.initState();
    if (widget.userId != currentUid) {
      _checkFollowStatus();
    }
  }

  // --- LOGIC ---

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

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    final bool isMe = widget.userId == currentUid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading profile"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryColor));

          if (!snapshot.data!.exists) return _buildNotFound(isMe);

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildSliverAppBar(isMe, userData['username'] ?? "Profile"),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildProfileHeader(userData),
                      _buildStatsRow(userData),
                      _buildActionArea(isMe),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                _buildStickyTabBar(),
              ],
              body: TabBarView(
                children: [
                  _buildUserPostsGrid(widget.userId),
                  _buildUserEventsList(widget.userId),
                  _buildSavedEventsList(widget.userId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(bool isMe, String username) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: !isMe ? const BackButton(color: Colors.black) : null,
      title: Text(
        username,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        if (isMe)
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () => context.push('/settings'),
          )
      ],
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> data) {
    final photoUrl = data['photoURL'] as String?;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: accentColor,
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['username'] ?? 'User',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  data['bio'] ?? 'Welcome to my profile!',
                  style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem("Posts", data['postCount'] ?? 0),
          _divider(),
          _statItem("Followers", data['followerCount'] ?? 0),
          _divider(),
          _statItem("Following", data['followingCount'] ?? 0),
        ],
      ),
    );
  }

  Widget _statItem(String label, int count) {
    return Column(
      children: [
        Text("$count", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _divider() => Container(height: 20, width: 1, color: Colors.grey[300]);

  Widget _buildActionArea(bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: isMe
          ? _buildButton("Edit Profile", accentColor, Colors.black, () => context.push('/profile/edit'))
          : _buildButton(
              isFollowing ? "Unfollow" : "Follow",
              isFollowing ? accentColor : primaryColor,
              isFollowing ? Colors.black : Colors.white,
              _toggleFollow,
              isLoading: isLoadingFollow,
            ),
    );
  }

  Widget _buildButton(String label, Color bg, Color text, VoidCallback action, {bool isLoading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: TextButton(
        onPressed: isLoading ? null : action,
        style: TextButton.styleFrom(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))
            : Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStickyTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        const TabBar(
          indicatorColor: primaryColor,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(icon: Icon(Icons.grid_view_rounded)),
            Tab(icon: Icon(Icons.event_available_rounded)),
            Tab(icon: Icon(Icons.bookmark_outline_rounded)),
          ],
        ),
      ),
    );
  }

  // --- CONTENT GRIDS ---

  Widget _buildUserPostsGrid(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('creatorId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return _buildEmptyState(Icons.grid_on_rounded, "No posts yet");

        return GridView.builder(
          padding: const EdgeInsets.all(1),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => context.push('/post/${docs[index].id}'),
              child: Image.network(
                data['mediaUrl'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: accentColor, child: const Icon(Icons.broken_image)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserEventsList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('creatorId', isEqualTo: uid)
          .orderBy('eventDate', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return _buildEmptyState(Icons.event_note_rounded, "No events organized");

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) => _eventTile(docs[index]),
        );
      },
    );
  }

  Widget _buildSavedEventsList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('bookmarks').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return _buildEmptyState(Icons.bookmark_border_rounded, "No saved events");
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) => _eventTile(docs[index]),
        );
      },
    );
  }

  Widget _eventTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (data['imageUrl'] != null)
              ? Image.network(data['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
              : Container(width: 50, height: 50, color: accentColor, child: const Icon(Icons.event)),
        ),
        title: Text(data['title'] ?? 'Event', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(data['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () => context.push('/home/event/${doc.id}'),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String msg) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.grey[200]),
            const SizedBox(height: 12),
            Text(msg, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );

  Widget _buildNotFound(bool isMe) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_rounded, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("User not found", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (isMe)
              TextButton(onPressed: () => context.push('/profile/edit'), child: const Text("Setup Profile")),
          ],
        ),
      );
}

// --- TABBAR DELEGATE ---

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}