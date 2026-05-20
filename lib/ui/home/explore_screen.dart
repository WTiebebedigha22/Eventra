import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MasonryExploreScreen extends StatefulWidget {
  const MasonryExploreScreen({super.key});

  @override
  State<MasonryExploreScreen> createState() => _MasonryExploreScreenState();
}

class _MasonryExploreScreenState extends State<MasonryExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<List<Map<String, dynamic>>> _masonryStream;
  
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFF3F3D56);
  static const Color backgroundColor = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _masonryStream = _getMasonryFeed();
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

  Stream<List<Map<String, dynamic>>> _getMasonryFeed() {
    final posts = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
    
    final events = FirebaseFirestore.instance
        .collection('events')
        .orderBy('date', descending: true)
        .snapshots();

    return CombineLatestStream.combine2(posts, events, (pSnap, eSnap) {
      final pList = pSnap.docs
          .map((d) => {
                ...d.data(),
                'id': d.id,
                'type': 'post',
                'createdAt': d['createdAt'] ?? DateTime.now(),
              })
          .toList();
      
      final eList = eSnap.docs
          .map((d) => {
                ...d.data(),
                'id': d.id,
                'type': 'event',
                'createdAt': d['date'] ?? DateTime.now(),
              })
          .toList();

      final combined = [...pList, ...eList];
      
      combined.sort((a, b) {
        final tA = a['createdAt'] as DateTime;
        final tB = b['createdAt'] as DateTime;
        return tB.compareTo(tA);
      });
      
      return combined;
    }).asBroadcastStream();
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
          _buildMasonryGrid('all'),
          _buildMasonryGrid('event'),
          _buildMasonryGrid('post'),
        ],
      ),
    );
  }

  Widget _buildMasonryGrid(String filter) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _masonryStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  "Something went wrong",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
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

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerGrid();
        }

        final data = snapshot.data ?? [];
        
        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  "No items found",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Check back later for new content",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        var items = filter == 'all'
            ? data
            : data.where((i) => i['type'] == filter).toList();

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          items = items.where((item) {
            final title = (item['title'] ?? item['description'] ?? '').toLowerCase();
            final location = (item['location'] ?? '').toLowerCase();
            return title.contains(_searchQuery) || location.contains(_searchQuery);
          }).toList();
        }

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No results for '$_searchQuery'",
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildMasonryTile(item);
          },
        );
      },
    );
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
        return _ShimmerTile(
          height: 150 + (index % 3) * 50,
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
    final int? likesCount = item['likesCount'];
    final int? commentsCount = item['commentsCount'];

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
            // Image Section
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Hero(
                    tag: '${item['type']}_${item['id']}',
                    child: CachedNetworkImage(
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
                  ),
                  // Badge
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
                  // Price Badge
                  if (price != null && price > 0)
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
                          '\$${price.toString()}',
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
            // Content Section
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
                  if (likesCount != null || commentsCount != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (likesCount != null)
                          _buildStatChip(Icons.favorite, likesCount, Colors.red.shade400),
                        if (commentsCount != null) ...[
                          const SizedBox(width: 8),
                          _buildStatChip(Icons.comment, commentsCount, primaryColor),
                        ],
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

  Widget _buildStatChip(IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            _formatCount(count),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
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
            _buildFilterOption('Sort by newest', true),
            _buildFilterOption('Sort by popular', false),
            _buildFilterOption('Near me', false),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, bool isSelected) {
    return RadioListTile<bool>(
      value: true,
      groupValue: isSelected,
      onChanged: (_) {},
      title: Text(title),
      activeColor: primaryColor,
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

// FIXED: Shimmer Tile with proper animation controller
class _ShimmerTile extends StatefulWidget {
  final double height;
  const _ShimmerTile({required this.height});

  @override
  State<_ShimmerTile> createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<_ShimmerTile> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // FIXED: Added explicit duration to AnimationController
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Explicit duration
    )..repeat(); // repeat() now works because duration is set
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ShimmerLoading(
            animationValue: _shimmerController.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ShimmerLoading extends StatelessWidget {
  final double animationValue;
  final Widget child;

  const ShimmerLoading({
    super.key,
    required this.animationValue,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: const [
            Color(0xFFEBEBF4),
            Color(0xFFF4F4F8),
            Color(0xFFEBEBF4),
          ],
          stops: const [0.1, 0.3, 0.4],
          begin: Alignment(-1.0 + animationValue * 2, -0.3),
          end: Alignment(1.0 + animationValue * 2, 0.3),
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcATop,
      child: child,
    );
  }
}