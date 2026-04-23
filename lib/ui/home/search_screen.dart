import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../components/event_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  static const Color primaryColor = Color(0xFF3E5992);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              style: const TextStyle(color: Colors.black, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search events, tags, or people...",
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: primaryColor, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.black54, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
              ),
            ),
          ),
          bottom: const TabBar(
            indicatorColor: primaryColor,
            indicatorWeight: 2,
            labelColor: primaryColor,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Explore"),
              Tab(text: "People"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _searchQuery.isEmpty ? _buildDiscoveryFeed() : _buildEventResults(),
            _searchQuery.isEmpty ? _buildSuggestedPeople() : _buildUserResults(),
          ],
        ),
      ),
    );
  }

  // ─── DISCOVERY FEED ───────────────────────────────────────────────────────

  Widget _buildDiscoveryFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No trending events yet. Check back soon!"));
        }

        return MasonryGridView.count(
          padding: const EdgeInsets.all(12),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            data['id'] = docs[index].id;
            return _buildDiscoveryCard(data);
          },
        );
      },
    );
  }

  Widget _buildDiscoveryCard(Map<String, dynamic> event) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 12 * 3) / 2; // 2 columns with 12px gaps

    return InkWell(
      onTap: () => context.push('/home/event/${event['id']}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _buildNetworkImage(
              url: event['imageURL'],
              width: cardWidth,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              event['title'] ?? 'Unnamed Event',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SHARED IMAGE HELPER ──────────────────────────────────────────────────

  Widget _buildNetworkImage({required String? url, required double width}) {
    // Vary height slightly per card for the staggered masonry effect
    final height = width * (0.75 + (url?.hashCode ?? 0).abs() % 30 / 100);

    if (url == null || url.isEmpty) {
      return _buildImagePlaceholder(width: width, height: height);
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildImagePlaceholder(width: width, height: height);
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildImagePlaceholder(width: width, height: height);
      },
    );
  }

  Widget _buildImagePlaceholder({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.black26, size: 32),
      ),
    );
  }

  // ─── EVENT SEARCH ─────────────────────────────────────────────────────────

  Widget _buildEventResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('tags', arrayContains: _searchQuery.toLowerCase())
          .limit(15)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }
        var results = snapshot.data!.docs;
        if (results.isEmpty) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .where('title', isGreaterThanOrEqualTo: _searchQuery)
                .where('title', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
                .limit(15)
                .snapshots(),
            builder: (context, titleSnapshot) {
              if (!titleSnapshot.hasData) return const SizedBox();
              if (titleSnapshot.data!.docs.isEmpty) {
                return _buildNoResultsText("No events or tags found.");
              }
              return _buildEventList(titleSnapshot.data!.docs);
            },
          );
        }
        return _buildEventList(results);
      },
    );
  }

  Widget _buildEventList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        data['id'] = docs[index].id;
        return EventCard(event: data);
      },
    );
  }

  // ─── SUGGESTED PEOPLE (shown when query is empty) ─────────────────────────

  Widget _buildSuggestedPeople() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('followerCount', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }

        final docs = snapshot.data!.docs
            .where((d) => d.id != currentUid)
            .toList();

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "No suggested people yet.",
              style: TextStyle(color: Colors.black38, fontSize: 14),
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  "Suggested People",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = docs[index].data() as Map<String, dynamic>;
                  return _buildSuggestedUserTile(user);
                },
                childCount: docs.length,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSuggestedUserTile(Map<String, dynamic> user) {
    final followerCount = user['followerCount'] as int? ?? 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[200],
        backgroundImage: user['photoURL'] != null ? NetworkImage(user['photoURL']) : null,
        child: user['photoURL'] == null
            ? const Icon(Icons.person, color: Colors.grey)
            : null,
      ),
      title: Text(
        user['displayName'] ?? 'User',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        "@${user['username'] ?? ''}",
        style: const TextStyle(color: Colors.black54, fontSize: 12),
      ),
      trailing: followerCount > 0
          ? Text(
              _formatCount(followerCount),
              style: const TextStyle(
                color: Colors.black38,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      onTap: () => context.push('/user/${user['uid']}'),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M followers';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K followers';
    return '$count followers';
  }

  // ─── USER SEARCH (shown when query is non-empty) ──────────────────────────

  Widget _buildUserResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: _searchQuery.toLowerCase())
          .where('username', isLessThanOrEqualTo: '${_searchQuery.toLowerCase()}\uf8ff')
          .limit(15)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }
        final results = snapshot.data!.docs;
        if (results.isEmpty) return _buildNoResultsText("No users found.");

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final user = results[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    user['photoURL'] != null ? NetworkImage(user['photoURL']) : null,
                child: user['photoURL'] == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              title: Text(
                user['displayName'] ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("@${user['username']}"),
              onTap: () => context.push('/user/${user['uid']}'),
            );
          },
        );
      },
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  Widget _buildNoResultsText(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Text(text, style: const TextStyle(color: Colors.black54)),
      ),
    );
  }
}