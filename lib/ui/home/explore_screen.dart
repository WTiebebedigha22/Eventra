import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class MasonryExploreScreen extends StatefulWidget {
  const MasonryExploreScreen({super.key});

  @override
  State<MasonryExploreScreen> createState() => _MasonryExploreScreenState();
}

class _MasonryExploreScreenState extends State<MasonryExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color backgroundColor = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  // Helper to convert Timestamp to DateTime safely
  DateTime _getDateTime(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is Timestamp) return timestamp.toDate();
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          if (_isSearching) _buildSearchBar(),
          _buildTabBar(),
          _buildTabBarView(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          "Discover",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        collapseMode: CollapseMode.pin,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list_rounded, color: Colors.black87),
          onPressed: () => _showFilterDialog(),
        ),
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.black87),
          onPressed: () => setState(() => _isSearching = !_isSearching),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search posts or events...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: "FOR YOU", icon: Icon(Icons.explore)),
            Tab(text: "EVENTS", icon: Icon(Icons.event)),
            Tab(text: "POSTS", icon: Icon(Icons.grid_on)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildAllContent(),
          _buildEventsGrid(),
          _buildPostsGrid(),
        ],
      ),
    );
  }

  // TAB 1: ALL CONTENT (Posts + Events combined)
  Widget _buildAllContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, postsSnapshot) {
        if (postsSnapshot.hasError) {
          return _buildErrorWidget(postsSnapshot.error);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .orderBy('eventDate', descending: true)
              .snapshots(),
          builder: (context, eventsSnapshot) {
            if (eventsSnapshot.hasError) {
              return _buildErrorWidget(eventsSnapshot.error);
            }

            if (postsSnapshot.connectionState == ConnectionState.waiting ||
                eventsSnapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerGrid();
            }

            final List<Map<String, dynamic>> items = [];
            
            // Add posts - FIXED: Convert timestamp safely
            postsSnapshot.data?.docs.forEach((doc) {
              final data = doc.data() as Map<String, dynamic>;
              items.add({
                ...data,
                'id': doc.id,
                'type': 'post',
                'timestamp': _getDateTime(data['createdAt']),
              });
            });
            
            // Add events - FIXED: Convert timestamp safely
            eventsSnapshot.data?.docs.forEach((doc) {
              final data = doc.data() as Map<String, dynamic>;
              items.add({
                ...data,
                'id': doc.id,
                'type': 'event',
                'timestamp': _getDateTime(data['eventDate'] ?? data['createdAt']),
              });
            });
            
            // Sort by timestamp (newest first)
            items.sort((a, b) {
              final tA = a['timestamp'] as DateTime;
              final tB = b['timestamp'] as DateTime;
              return tB.compareTo(tA);
            });
            
            // Apply search filter
            var filteredItems = items;
            if (_searchQuery.isNotEmpty) {
              filteredItems = items.where((item) {
                final title = (item['title'] ?? item['description'] ?? '').toLowerCase();
                final location = (item['location'] ?? '').toLowerCase();
                return title.contains(_searchQuery) || location.contains(_searchQuery);
              }).toList();
            }
            
            if (filteredItems.isEmpty) {
              return _buildEmptyState(_searchQuery.isNotEmpty ? 'No results found' : 'No content yet');
            }
            
            return MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                return _buildMasonryTile(filteredItems[index]);
              },
            );
          },
        );
      },
    );
  }

  // TAB 2: EVENTS ONLY
  Widget _buildEventsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .orderBy('eventDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerGrid();
        }

        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return _buildEmptyState('No events found');
        }
        
        var items = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'id': doc.id,
            'type': 'event',
            'timestamp': _getDateTime(data['eventDate'] ?? data['createdAt']),
          };
        }).toList();
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          items = items.where((item) {
            final title = (item['title'] ?? item['description'] ?? '').toLowerCase();
            final location = (item['location'] ?? '').toLowerCase();
            return title.contains(_searchQuery) || location.contains(_searchQuery);
          }).toList();
        }
        
        if (items.isEmpty) {
          return _buildEmptyState(_searchQuery.isNotEmpty ? 'No matching events' : 'No events yet');
        }
        
        return MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildMasonryTile(items[index]);
          },
        );
      },
    );
  }

  // TAB 3: POSTS ONLY
  Widget _buildPostsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerGrid();
        }

        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return _buildEmptyState('No posts found');
        }
        
        var items = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'id': doc.id,
            'type': 'post',
            'timestamp': _getDateTime(data['createdAt']),
          };
        }).toList();
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          items = items.where((item) {
            final title = (item['title'] ?? item['description'] ?? '').toLowerCase();
            return title.contains(_searchQuery);
          }).toList();
        }
        
        if (items.isEmpty) {
          return _buildEmptyState(_searchQuery.isNotEmpty ? 'No matching posts' : 'No posts yet');
        }
        
        return MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildMasonryTile(items[index]);
          },
        );
      },
    );
  }

  Widget _buildMasonryTile(Map<String, dynamic> item) {
    final String imageUrl = item['imageUrl'] ?? item['mediaUrl'] ?? '';
    final bool isEvent = item['type'] == 'event';
    final String title = item['title'] ?? item['description'] ?? '';
    final String? location = item['location'];
    final dynamic price = item['price'];

    return GestureDetector(
      onTap: () => _navigateToDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 180,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      color: primaryColor.withOpacity(0.1),
                      child: const Icon(
                        Icons.broken_image,
                        color: primaryColor,
                        size: 40,
                      ),
                    ),
                  ),
                  // Type Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isEvent
                              ? [primaryColor, primaryColor.withOpacity(0.8)]
                              : [Colors.orange, Colors.deepOrange],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isEvent ? Icons.event : Icons.article,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isEvent ? 'EVENT' : 'POST',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Price Badge (Events only)
                  if (price != null && price > 0 && isEvent)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatPrice(price),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      height: 1.4,
                    ),
                  ),
                  if (location != null && location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
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

  String _formatPrice(dynamic price) {
    if (price == null) return 'FREE';
    final format = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    return format.format(price);
  }

  Widget _buildShimmerGrid() {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          height: 150 + (index % 3) * 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new content',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          if (_searchQuery.isNotEmpty)
            TextButton(
              onPressed: () => _searchController.clear(),
              child: const Text('Clear search'),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text(
            "Unable to load content",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            error?.toString() ?? 'Unknown error occurred',
            style: TextStyle(color: Colors.grey.shade600),
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
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Latest'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Popular'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Near me'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> item) {
    final String? id = item['id'] as String?;

    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to open item — missing ID."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    
    if (item['type'] == 'event') {
      context.push('/home/event/$id');
    } else {
      context.push('/post/$id');
    }
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double offset, bool overlaps) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate old) => false;
}