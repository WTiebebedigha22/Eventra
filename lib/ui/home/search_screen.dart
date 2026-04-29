import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../components/event_card.dart'; // Ensure this path is correct

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _activeQuery = "";
  Timer? _debounce;
  static const Color primaryColor = Colors.deepPurple; // Define your primary color here

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Prevents querying Firestore on every single keystroke.
  /// Waits 500ms after the user stops typing to trigger the rebuild.
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _activeQuery = query.trim().toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          title: _buildSearchBar(),
          bottom: const TabBar(
            indicatorColor: primaryColor,
            indicatorWeight: 3,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: "Explore"),
              Tab(text: "People"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _activeQuery.isEmpty ? _buildDiscoveryFeed() : _buildEventResults(),
            _activeQuery.isEmpty ? _buildSuggestedPeople() : _buildUserResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: "Search events, tags, or people...",
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: primaryColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _activeQuery = "");
                  },
                  child: const Icon(Icons.cancel, color: Colors.black26, size: 18),
                )
              : null,
        ),
      ),
    );
  }

  // ─── TAB 1: EXPLORE / EVENTS ──────────────────────────────────────────────

  Widget _buildDiscoveryFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('events')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingIndicator();
        final docs = snapshot.data!.docs;
        
        return MasonryGridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
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

  Widget _buildEventResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('events')
          .where('title_lowercase', isGreaterThanOrEqualTo: _activeQuery)
          .where('title_lowercase', isLessThanOrEqualTo: '$_activeQuery\uf8ff')
          .limit(15)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingIndicator();
        final results = snapshot.data!.docs;
        
        if (results.isEmpty) return _buildNoResults("No events found for '$_activeQuery'");

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final data = results[index].data() as Map<String, dynamic>;
            data['id'] = results[index].id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EventCard(event: data),
            );
          },
        );
      },
    );
  }

  Widget _buildDiscoveryCard(Map<String, dynamic> event) {
    return InkWell(
      onTap: () => context.push('/home/event/${event['id']}'),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.network(
                  event['imageURL'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.black12),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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

  // ─── TAB 2: PEOPLE ────────────────────────────────────────────────────────

  Widget _buildSuggestedPeople() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .orderBy('followerCount', descending: true)
          .limit(15)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingIndicator();
        final docs = snapshot.data!.docs.where((d) => d.id != currentUid).toList();

        return ListView.separated(
          padding: const EdgeInsets.only(top: 10),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
          itemBuilder: (context, index) {
            final user = docs[index].data() as Map<String, dynamic>;
            return _buildUserTile(user);
          },
        );
      },
    );
  }

  Widget _buildUserResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: _activeQuery)
          .where('username', isLessThanOrEqualTo: '$_activeQuery\uf8ff')
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingIndicator();
        final results = snapshot.data!.docs;

        if (results.isEmpty) return _buildNoResults("No people found matching '$_activeQuery'");

        return ListView.separated(
          padding: const EdgeInsets.only(top: 10),
          itemCount: results.length,
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
          itemBuilder: (context, index) {
            final user = results[index].data() as Map<String, dynamic>;
            return _buildUserTile(user);
          },
        );
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[100],
        backgroundImage: user['photoURL'] != null ? NetworkImage(user['photoURL']) : null,
        child: user['photoURL'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
      ),
      title: Text(
        user['displayName'] ?? 'User',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        "@${user['username'] ?? ''}",
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black12),
      onTap: () => context.push('/user/${user['uid'] ?? user['id']}'),
    );
  }

  // ─── UTILS ────────────────────────────────────────────────────────────────

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2));
  }

  Widget _buildNoResults(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: Colors.black12),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.black45)),
        ],
      ),
    );
  }
}