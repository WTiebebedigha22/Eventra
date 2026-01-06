// lib/screens/home/search_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../components/event_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  static const Color primaryPink = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Container(
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF262626)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search events or people...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: primaryPink, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
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
            indicatorColor: primaryPink,
            indicatorWeight: 3,
            labelColor: Colors.white,
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
          Icon(Icons.manage_search_rounded, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text("Find your next experience or friend", 
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
        ],
      ),
    );
  }

  // --- TAB 1: EVENT SEARCH ---
  Widget _buildEventResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events') // pulling from events
          .where('title', isGreaterThanOrEqualTo: _searchQuery)
          .where('title', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryPink));
        final results = snapshot.data!.docs;

        if (results.isEmpty) return _buildNoResultsText("No events found.");

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final data = results[index].data() as Map<String, dynamic>;
            data['id'] = results[index].id;
            return EventCard(event: data);
          },
        );
      },
    );
  }

  // --- TAB 2: USER SEARCH ---
  Widget _buildUserResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users') // pulling from users
          .where('username', isGreaterThanOrEqualTo: _searchQuery.toLowerCase())
          .where('username', isLessThanOrEqualTo: '${_searchQuery.toLowerCase()}\uf8ff')
          .limit(15)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryPink));
        final results = snapshot.data!.docs;

        if (results.isEmpty) return _buildNoResultsText("No users found.");

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final user = results[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white10,
                backgroundImage: user['photoURL'] != null ? NetworkImage(user['photoURL']) : null,
                child: user['photoURL'] == null ? const Icon(Icons.person, color: Colors.white54) : null,
              ),
              title: Text(user['displayName'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text("@${user['username']}", style: const TextStyle(color: Colors.grey)),
              onTap: () => context.push('/profile/${user['uid']}'), // Navigates to the ProfileScreen you just fixed!
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
        child: Text(text, style: const TextStyle(color: Colors.white54)),
      ),
    );
  }
}