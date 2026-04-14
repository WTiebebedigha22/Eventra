import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class DiscoverUsersScreen extends StatefulWidget {
  const DiscoverUsersScreen({super.key});

  @override
  State<DiscoverUsersScreen> createState() => _DiscoverUsersScreenState();
}

class _DiscoverUsersScreenState extends State<DiscoverUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Theme Constants matching your app
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color tiktokRed = Color(0xFFFE2C55);
  static const Color searchFieldBg = Color(0xFFF1F1F2);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: _buildSearchField(),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Real-time Search Logic: 
        // If query is empty, show suggested users. 
        // If typing, perform prefix search on 'username'.
        stream: _searchQuery.isEmpty
            ? FirebaseFirestore.instance.collection('users').limit(20).snapshots()
            : FirebaseFirestore.instance
                .collection('users')
                .where('username', isGreaterThanOrEqualTo: _searchQuery)
                .where('username', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading users"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: tiktokRed));
          }

          // Filter out the logged-in user so they don't follow themselves
          final docs = snapshot.data!.docs.where((doc) => doc.id != _currentUid).toList();

          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 80, color: Color(0xFFF8F8F8)),
            itemBuilder: (context, index) {
              final userData = docs[index].data() as Map<String, dynamic>;
              final userId = docs[index].id;
              return _UserTile(userId: userId, userData: userData, currentUid: _currentUid);
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: searchFieldBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
          });
        },
        decoration: InputDecoration(
          hintText: "Search by username",
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 18),
          suffixIcon: _searchQuery.isNotEmpty 
            ? GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = "");
                },
                child: const Icon(Icons.cancel, color: Colors.grey, size: 18),
              ) 
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 60, color: Colors.grey[200]),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty ? "No users found" : "No results for '$_searchQuery'",
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final String currentUid;

  const _UserTile({required this.userId, required this.userData, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    // Nested StreamBuilder to handle real-time "Follow" button state
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('followers')
          .doc(currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        final bool isFollowing = snapshot.hasData && snapshot.data!.exists;

        return ListTile(
          onTap: () => context.push('/profile/$userId'),
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFF1F4F9),
            backgroundImage: (userData['photoURL'] != null && userData['photoURL'].isNotEmpty)
                ? NetworkImage(userData['photoURL'])
                : null,
            child: (userData['photoURL'] == null) ? const Icon(Icons.person, color: Colors.grey) : null,
          ),
          title: Text(
            userData['username'] ?? 'User',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            userData['bio'] ?? 'Hello! I am new here.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          trailing: _FollowButton(
            isFollowing: isFollowing,
            onTap: () => _toggleFollow(isFollowing),
          ),
        );
      },
    );
  }

  Future<void> _toggleFollow(bool isFollowing) async {
    HapticFeedback.mediumImpact();
    final batch = FirebaseFirestore.instance.batch();
    
    final targetUserRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(currentUid);
    final followerDocRef = targetUserRef.collection('followers').doc(currentUid);
    final followingDocRef = currentUserRef.collection('following').doc(userId);

    if (isFollowing) {
      // Unfollow Logic
      batch.delete(followerDocRef);
      batch.delete(followingDocRef);
      batch.update(targetUserRef, {'followerCount': FieldValue.increment(-1)});
      batch.update(currentUserRef, {'followingCount': FieldValue.increment(-1)});
    } else {
      // Follow Logic
      batch.set(followerDocRef, {'followedAt': FieldValue.serverTimestamp()});
      batch.set(followingDocRef, {'followedAt': FieldValue.serverTimestamp()});
      batch.update(targetUserRef, {'followerCount': FieldValue.increment(1)});
      batch.update(currentUserRef, {'followingCount': FieldValue.increment(1)});
    }

    await batch.commit();
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;

  const _FollowButton({required this.isFollowing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      width: 90,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: isFollowing ? Colors.white : const Color(0xFFFE2C55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: isFollowing ? const BorderSide(color: Color(0xFFE1E1E2)) : BorderSide.none,
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          isFollowing ? "Following" : "Follow",
          style: TextStyle(
            color: isFollowing ? Colors.black : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}