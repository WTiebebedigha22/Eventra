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
  bool isInitializing = false; // Track profile creation state
  static const Color primaryColor = Color(0xFF3E5992);

  @override
  void initState() {
    super.initState();
    if (widget.userId != currentUid) {
      _checkFollowStatus();
    }
  }

  // Helper to create the document if it's missing
  Future<void> _initializeProfile() async {
    setState(() => isInitializing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': user.displayName ?? 'User_${user.uid.substring(0, 5)}',
          'email': user.email,
          'photoURL': user.photoURL ?? '',
          'bio': 'Welcome to my profile!',
          'postCount': 0,
          'followerCount': 0,
          'followingCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => isInitializing = false);
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
    if (isLoadingFollow) return;
    setState(() {
      isFollowing = !isFollowing;
      isLoadingFollow = true;
    });
    HapticFeedback.mediumImpact();

    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(currentUid);
    final followerRef = userRef.collection('followers').doc(currentUid);

    try {
      if (isFollowing) {
        await followerRef.set({'followedAt': FieldValue.serverTimestamp()});
        await userRef.update({'followerCount': FieldValue.increment(1)});
        await currentUserRef.update({'followingCount': FieldValue.increment(1)});
      } else {
        await followerRef.delete();
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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: !isMe
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => context.pop(),
                )
              : null,
          title: Text(isMe ? "My Profile" : "Profile",
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          actions: [
            if (isMe)
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.black54),
                onPressed: () => context.push('/settings'),
              )
          ],
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text("Error loading profile"));
            if (snapshot.connectionState == ConnectionState.waiting || isInitializing) {
              return const Center(child: CircularProgressIndicator(color: primaryColor));
            }

            // --- IMPROVED NOT FOUND STATE ---
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_outline, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text("User not found", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    if (isMe) ...[
                      const Text("Your profile hasn't been set up yet."),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.push('/profile/edit'),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        child: const Text("Setup Profile Now", style: TextStyle(color: Colors.white)),
                      )
                    ] else
                      const Text("This user doesn't seem to exist."),
                  ],
                ),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;

            return Column(
              children: [
                _buildProfileHeader(userData),
                _buildStatsRow(userData),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: isMe
                      ? _buildActionButton("Edit Profile", Colors.grey[200]!, Colors.black, () => context.push('/profile/edit'))
                      : _buildActionButton(
                          isFollowing ? "Unfollow" : "Follow",
                          isFollowing ? Colors.grey[200]! : primaryColor,
                          isFollowing ? Colors.black : Colors.white,
                          _toggleFollow),
                ),
                const TabBar(
                  indicatorColor: primaryColor,
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(icon: Icon(Icons.grid_on_rounded)),
                    Tab(icon: Icon(Icons.event_note_rounded)),
                    Tab(icon: Icon(Icons.bookmark_outline_rounded)),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildUserPostsGrid(widget.userId),
                      _buildUserEventsList(widget.userId),
                      _buildSavedEventsList(widget.userId),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- UI BUILDERS ---
  Widget _buildProfileHeader(Map<String, dynamic> data) {
    return Column(
      children: [
        const SizedBox(height: 10),
        CircleAvatar(
          radius: 45,
          backgroundColor: Colors.grey[200],
          backgroundImage: (data['photoURL'] != null && data['photoURL'].toString().isNotEmpty) ? NetworkImage(data['photoURL']) : null,
          child: (data['photoURL'] == null || data['photoURL'].toString().isEmpty) ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
        ),
        const SizedBox(height: 12),
        Text("${data['username'] ?? 'User'}", style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        if (data['bio'] != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Text(data['bio'], textAlign: TextAlign.center, style: TextStyle(color: Colors.black.withOpacity(0.6))),
          ),
      ],
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
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
        Text("$count", style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionButton(String label, Color bgColor, Color textColor, VoidCallback action) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildUserPostsGrid(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').where('creatorId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return _buildEmptyState(Icons.camera_alt_outlined, "No posts yet");
        return GridView.builder(
          padding: const EdgeInsets.all(2),
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Image.network(data['mediaUrl'] ?? '', fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey[200]));
          },
        );
      },
    );
  }

  Widget _buildUserEventsList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').where('creatorId', isEqualTo: uid).snapshots(),
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
      color: Colors.grey[50],
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (data['imageUrl'] != null) ? Image.network(data['imageUrl'], width: 50, height: 50, fit: BoxFit.cover) : Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.event, color: Colors.grey)),
        ),
        title: Text(data['title'] ?? 'Event', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        subtitle: Text(data['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => context.push('/home/event/${doc.id}'),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[300], size: 50),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}