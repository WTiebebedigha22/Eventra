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

  // Aesthetic colors: Ventra Blue & Jiji Green
  static const Color brandColor = Color(0xFF3E5992);
  static const Color jijiGreen = Color(0xFF3BA73A);
  static const Color surfaceColor = Colors.white;

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
        await userRef.collection('followers').doc(currentUid).set({
          'followedAt': FieldValue.serverTimestamp(),
        });
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

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text("Share Profile"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report_problem_outlined, color: Colors.red),
              title: const Text("Report User", style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMe = widget.userId == currentUid;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
          builder: (context, snapshot) {
            final name = (snapshot.data?.data() as Map?)?['username'] ?? "Profile";
            return Text(
              isMe ? "My Profile" : "@$name",
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            );
          },
        ),
        leading: !isMe ? const BackButton(color: Colors.black) : null,
        actions: [
          IconButton(
            icon: Icon(isMe ? Icons.settings_outlined : Icons.more_horiz, color: Colors.black),
            onPressed: isMe ? () => context.push('/settings') : _showMoreOptions,
          ),
        ],
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
                      const SizedBox(height: 10),
                      _buildHeaderAvatar(userData, isMe, widget.userId),
                      const SizedBox(height: 12),
                      Text(
                        userData['displayName'] ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      if (userData['bio'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                          child: Text(
                            userData['bio'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _buildStatsRow(userData),
                      const SizedBox(height: 20),
                      _buildActionButtons(isMe),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                _buildSliverTabBar(),
              ],
              body: TabBarView(
                children: [
                  _buildPostsGrid(),
                  _buildLikedGrid(),
                  _buildSavedGrid(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeaderAvatar(Map<String, dynamic> initialData, bool isMe, String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.hasData && snapshot.data!.exists
            ? snapshot.data!.data() as Map<String, dynamic>
            : initialData;
        final String? photoURL = userData['photoURL'];

        return Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade100, width: 2),
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey[100],
                backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
                child: (photoURL == null || photoURL.isEmpty) ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
              ),
            ),
            if (isMe)
              Positioned(
                bottom: 5,
                right: 5,
                child: GestureDetector(
                  onTap: () => HapticFeedback.lightImpact(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: brandColor, shape: BoxShape.circle),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _statItem("${data['followingCount'] ?? 0}", "Following"),
        _statDivider(),
        _statItem("${data['followerCount'] ?? 0}", "Followers"),
        _statDivider(),
        _statItem("${data['totalLikes'] ?? 0}", "Likes"),
      ],
    );
  }

  Widget _statDivider() => Container(height: 15, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 15));

  Widget _statItem(String count, String label) => Column(
        children: [
          Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      );

  Widget _buildActionButtons(bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              isMe ? "Edit Profile" : (isFollowing ? "Unfollow" : "Follow"),
              isMe || isFollowing ? Colors.white : jijiGreen,
              isMe || isFollowing ? Colors.black : Colors.white,
              isMe ? () => context.push('./edit') : _toggleFollow,
            ),
          ),
          const SizedBox(width: 8),
          _squareIconButton(isMe ? Icons.share_outlined : Icons.mail_outline_rounded, () {}),
        ],
      ),
    );
  }

  Widget _actionButton(String text, Color bg, Color txtColor, VoidCallback onTap) => SizedBox(
        height: 44,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: txtColor,
            elevation: 0,
            side: BorderSide(color: bg == Colors.white ? Colors.grey.shade300 : Colors.transparent),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      );

  Widget _squareIconButton(IconData icon, VoidCallback onTap) => Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(icon: Icon(icon, size: 20, color: Colors.black), onPressed: onTap),
      );

  Widget _buildSliverTabBar() => SliverPersistentHeader(
        pinned: true,
        delegate: _SliverAppBarDelegate(
          TabBar(
            indicatorColor: Colors.black,
            indicatorWeight: 1.5,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey.shade400,
            tabs: const [
              Tab(icon: Icon(Icons.grid_on_rounded)),
              Tab(icon: Icon(Icons.favorite_border_rounded)),
              Tab(icon: Icon(Icons.bookmark_outline_rounded)),
            ],
          ),
        ),
      );

  // --- GRIDS ---

  Widget _buildPostsGrid() => _buildBaseGrid(
      FirebaseFirestore.instance.collection('posts').where('creatorId', isEqualTo: widget.userId).snapshots(), "No posts yet");

  Widget _buildLikedGrid() => _buildBaseGrid(
      FirebaseFirestore.instance.collection('posts').where('likedBy', arrayContains: widget.userId).snapshots(), "No liked posts");

  Widget _buildSavedGrid() => _buildBaseGrid(
      FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('bookmarks').snapshots(), "No saved items");

  Widget _buildBaseGrid(Stream<QuerySnapshot> stream, String emptyMsg) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return Center(child: Text(emptyMsg, style: const TextStyle(color: Colors.grey)));

        return GridView.builder(
          padding: const EdgeInsets.all(1),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.75, // TikTok Style Vertical Ratio
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String media = data['imageUrl'] ?? data['mediaUrl'] ?? '';
            final String price = data['price'] ?? '';

            return GestureDetector(
              onTap: () => context.push('/post/${docs[index].id}', extra: data),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(media, fit: BoxFit.cover),
                  if (price.isNotEmpty)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                        child: Text(price, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(Icons.play_arrow_outlined, color: Colors.white70, size: 16),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(context, offset, overlaps) => Container(
        decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
        child: _tabBar,
      );
  @override
  bool shouldRebuild(_SliverAppBarDelegate old) => false;
}