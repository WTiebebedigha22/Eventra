import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../components/event_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _activeQuery = "";
  Timer? _debounce;
  bool _isSearching = false;
  late TabController _tabController;
  
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color backgroundColor = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    setState(() => _isSearching = query.isNotEmpty);
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _activeQuery = query.trim().toLowerCase();
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _activeQuery = "";
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _activeQuery.isEmpty ? _buildDiscoveryFeed() : _buildEventResults(),
                _activeQuery.isEmpty ? _buildSuggestedPeople() : _buildUserResults(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      title: const Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text(
          "Search",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 28,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: Colors.white,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          autofocus: false,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: "Search events, tags, or people...",
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: primaryColor, size: 22),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: _clearSearch,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: primaryColor,
        indicatorWeight: 3,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: const [
          Tab(text: "EVENTS", icon: Icon(Icons.event)),
          Tab(text: "PEOPLE", icon: Icon(Icons.people)),
        ],
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }
        
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error);
        }
        
        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return _buildEmptyState('No events available');
        }
        
        return MasonryGridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          physics: const BouncingScrollPhysics(),
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
    if (_activeQuery.isEmpty) {
      return const SizedBox();
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('events')
          .where('title_lowercase', isGreaterThanOrEqualTo: _activeQuery)
          .where('title_lowercase', isLessThanOrEqualTo: '$_activeQuery\uf8ff')
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }
        
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error);
        }
        
        final results = snapshot.data?.docs ?? [];
        
        if (results.isEmpty) {
          return _buildNoResults("No events found for '$_activeQuery'");
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
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
    final String imageUrl = event['imageURL'] ?? event['imageUrl'] ?? '';
    
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/home/event/${event['id']}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl.isNotEmpty ? imageUrl : '',
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 140,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 140,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            event['category'] ?? 'Event',
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'] ?? 'Unnamed Event',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 10, color: Colors.grey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          event['location'] ?? 'Location TBD',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  if (event['price'] != null && event['price'] > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '\$${event['price']}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }
        
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error);
        }
        
        final docs = snapshot.data?.docs.where((d) => d.id != currentUid).toList() ?? [];
        
        if (docs.isEmpty) {
          return _buildEmptyState('No users found');
        }
        
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final user = docs[index].data() as Map<String, dynamic>;
            user['uid'] = docs[index].id;
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }
        
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error);
        }
        
        final results = snapshot.data?.docs ?? [];
        
        if (results.isEmpty) {
          return _buildNoResults("No people found for '$_activeQuery'");
        }
        
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          physics: const BouncingScrollPhysics(),
          itemCount: results.length,
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final user = results[index].data() as Map<String, dynamic>;
            user['uid'] = results[index].id;
            return _buildUserTile(user);
          },
        );
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final String photoURL = user['photoURL'] ?? '';
    final String displayName = user['displayName'] ?? user['username'] ?? 'User';
    final String username = user['username'] ?? '';
    final int followerCount = user['followerCount'] ?? 0;
    final String uid = user['uid'] ?? user['id'];
    
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade100,
        backgroundImage: photoURL.isNotEmpty ? CachedNetworkImageProvider(photoURL) : null,
        child: photoURL.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Row(
        children: [
          Text(
            "@$username",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatCount(followerCount),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Text(" followers", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "View",
          style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/user/$uid');
      },
    );
  }

  // ─── UTILS ────────────────────────────────────────────────────────────────

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
    );
  }

  Widget _buildErrorWidget(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            error?.toString() ?? 'An error occurred',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _clearSearch,
            child: const Text('Clear search'),
          ),
        ],
      ),
    );
  }
}