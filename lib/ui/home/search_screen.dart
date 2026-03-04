import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../components/event_card.dart'; // Ensure this exists
//import '../post/post_detail.dart'; // Import the detail screen

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
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: "Search events, tags, or people...",
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: primaryColor, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.black54, size: 18),
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
            indicatorWeight: 3,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Events"),
              Tab(text: "People"),
            ],
          ),
        ),
        body: _searchQuery.isEmpty 
          ? _buildEmptyState() 
          : TabBarView(
              children: [
                _buildEventResults(),
                _buildUserResults(),
              ],
            ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.manage_search_rounded, size: 80, color: Colors.black12),
          const SizedBox(height: 16),
          const Text("Find your next experience or friend", 
            style: TextStyle(color: Colors.black54, fontSize: 16)),
        ],
      ),
    );
  }

  // --- TAB 1: EVENT SEARCH (Title + Tags) ---
  Widget _buildEventResults() {
    return StreamBuilder<QuerySnapshot>(
      // First check if search query matches any tags
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('tags', arrayContains: _searchQuery.toLowerCase())
          .limit(15)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryColor));
        
        var results = snapshot.data!.docs;

        // Fallback: If no tags found, search by Title prefix
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
              if (titleSnapshot.data!.docs.isEmpty) return _buildNoResultsText("No events or tags found.");
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
        return EventCard(event: data); // Navigation to PostDetail happens inside EventCard
      },
    );
  }

  // --- TAB 2: USER SEARCH ---
  Widget _buildUserResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: _searchQuery.toLowerCase())
          .where('username', isLessThanOrEqualTo: '${_searchQuery.toLowerCase()}\uf8ff')
          .limit(15)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryColor));
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
                backgroundImage: user['photoURL'] != null ? NetworkImage(user['photoURL']) : null,
                child: user['photoURL'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
              ),
              title: Text(user['displayName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("@${user['username']}"),
              onTap: () => context.push('/profile/${user['uid']}'),
            );
          },
        );
      },
    );
  }

  Widget _buildNoResultsText(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Text(text, style: const TextStyle(color: Colors.black54)),
      ),
    );
  }
}