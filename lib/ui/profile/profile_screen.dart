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
  static const Color primaryPink = Color(0xFFE91E63);

  // --- REPAIR LOGIC START ---
  Future<void> _runDatabaseRepair() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Starting database repair...")),
    );

    try {
      final batch = FirebaseFirestore.instance.batch();
      int repairedCount = 0;

      // 1. Repair Posts (Check for missing createdAt)
      final postQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('creatorId', isEqualTo: widget.userId)
          .get();

      for (var doc in postQuery.docs) {
        if (!doc.data().containsKey('createdAt') || doc.data()['createdAt'] == null) {
          batch.update(doc.reference, {'createdAt': FieldValue.serverTimestamp()});
          repairedCount++;
        }
      }

      // 2. Repair Events (Check for missing createdAt)
      final eventQuery = await FirebaseFirestore.instance
          .collection('events')
          .where('creatorId', isEqualTo: widget.userId)
          .get();

      for (var doc in eventQuery.docs) {
        if (!doc.data().containsKey('createdAt') || doc.data()['createdAt'] == null) {
          batch.update(doc.reference, {'createdAt': FieldValue.serverTimestamp()});
          repairedCount++;
        }
      }

      if (repairedCount > 0) {
        await batch.commit();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Fixed $repairedCount items! Refreshing...")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No broken data found. Check your UIDs.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Repair failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
  // --- REPAIR LOGIC END ---

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
      if (mounted) {
        setState(() => isFollowing = !isFollowing);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Action failed. Check connection.")),
        );
      }
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
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: !isMe ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ) : null,
          title: Text(isMe ? "My Profile" : "Profile", 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            // REPAIR BUTTON - Click this once to fix data!, just a Test feature
            IconButton(
              icon: const Icon(Icons.build_circle_outlined, color: Colors.orange),
              onPressed: _runDatabaseRepair,
            ),
            if (isMe) IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () => context.push('/settings'),
            )
          ],
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return _buildErrorState();
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: primaryPink));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("User not found", style: TextStyle(color: Colors.white)));
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;

            return Column(
              children: [
                _buildProfileHeader(userData),
                _buildStatsRow(userData),
                
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

                const SizedBox(height: 10),

                const TabBar(
                  indicatorColor: primaryPink,
                  labelColor: Colors.white,
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
          backgroundColor: const Color(0xFF262626),
          backgroundImage: (data['photoURL'] != null && data['photoURL'].toString().isNotEmpty) 
              ? NetworkImage(data['photoURL']) 
              : null,
          child: (data['photoURL'] == null || data['photoURL'].toString().isEmpty) 
              ? const Icon(Icons.person, size: 40, color: Colors.white) 
              : null,
        ),
        const SizedBox(height: 12),
        Text("${data['username'] ?? 'unknown'}", 
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
        Text("$count", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback action) {
    return SizedBox(
      width: double.infinity,
      height: 40,
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
    stream: FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: uid) // Changed from 'creatorId'
        .orderBy('timestamp', descending: true) // Changed from 'createdAt'
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        debugPrint("Query Error: ${snapshot.error}");
        return _buildErrorState();
      }
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      
      final docs = snapshot.data!.docs;
      if (docs.isEmpty) return _buildEmptyState(Icons.camera_alt_outlined, "No posts yet");

      return GridView.builder(
        padding: const EdgeInsets.all(2),
        itemCount: docs.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
        itemBuilder: (context, index) {
          final data = docs[index].data() as Map<String, dynamic>;
          // Your model uses 'mediaUrl' for the image
          return Image.network(
            data['mediaUrl'] ?? '', 
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(color: Colors.grey[900]),
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
          // 1. TEMPORARY FIX: Comment out the orderBy line below. 
          // If the events appear, you know the issue is a missing 'createdAt' field or a missing Index.
          .orderBy('createdAt', descending: true) 
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // 2. CRITICAL: Print the error to the console.
          // If an Index is missing, Firestore will provide a LINK in the log to create it.
          debugPrint("Firestore Error: ${snapshot.error}");
          return _buildErrorState();
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryPink));
        }

        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return _buildEmptyState(Icons.event_note_rounded, "No events organized");
        }

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
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('bookmarks')
          .orderBy('savedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorState();
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
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: (data['imageUrl'] != null) 
            ? Image.network(data['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
            : Container(width: 50, height: 50, color: Colors.grey[800], child: const Icon(Icons.event)),
        ),
        title: Text(data['title'] ?? 'Event', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(data['description'] ?? '', 
          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: () => context.push('/home/event/${doc.id}'),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white24, size: 50),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("Data fetch error. Check Firestore indexes.",
          textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent)),
      ),
    );
  }
}