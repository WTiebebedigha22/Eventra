import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          elevation: 0.5, // Subtle shadow for a premium feel
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
        // If query is empty, show the Discovery/Recommendation Feed
        body: TabBarView(
          children: [
            _searchQuery.isEmpty ? _buildDiscoveryFeed() : _buildEventResults(),
            _buildUserResults(), // User search handles its own empty/not-empty logic
          ],
        ),
      ),
    );
  }

  // --- NEW: RECOMMENDED/DISCOVERY FEED ---
  Widget _buildDiscoveryFeed() {
    return StreamBuilder<QuerySnapshot>(
      // Recommendation Logic: Get 20 latest events
      // In a more advanced app, you'd filter by user interests
      stream: FirebaseFirestore.instance
          .collection('events')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryColor));
        
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("No trending events yet. Check back soon!"));
        }

        // Using MasonryGridView for that "Instagram Explore" staggered look
        return MasonryGridView.count(
          padding: const EdgeInsets.all(12),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            data['id'] = docs[index].id;
            
            // You can create a smaller "GridEventCard" component for this view
            return _buildDiscoveryCard(data);
          },
        );
      },
    );
  }

  Widget _buildDiscoveryCard(Map<String, dynamic> event) {
    return InkWell(
      onTap: () => context.push('/home/event/${event['id']}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              event['imageURL'] ?? 'https://via.placeholder.com/300',
              fit: BoxFit.cover,
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

  // --- TAB 1: EVENT SEARCH (Title + Tags) ---
  Widget _buildEventResults() {
    // [Keep your existing _buildEventResults logic here]
    // ...
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('tags', arrayContains: _searchQuery.toLowerCase())
          .limit(15)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryColor));
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
        return EventCard(event: data);
      },
    );
  }

  // --- TAB 2: USER SEARCH ---
  Widget _buildUserResults() {
    // Return early if no search is happening to keep the 'People' tab clean
    if (_searchQuery.isEmpty) return _buildEmptyPeopleState();

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
              onTap: () => context.push('/user/${user['uid']}'),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyPeopleState() {
    return const Center(
      child: Text("Search for your friends by username", 
        style: TextStyle(color: Colors.black38, fontSize: 14)),
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