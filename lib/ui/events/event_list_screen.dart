import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
// Internal Imports
import '../../providers/post_provider.dart';
import '../components/event_card.dart';
import '../post/tag_people.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _activeFilter = 'All';
  bool _isScrolling = false;

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;

  final List<String> _categories = [
    'All', 'Music', 'Parties', 'Tech', 'Art', 
    'Seminars', 'Workshops', 'Sports', 'Food', 'Rentals'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Fetch both events and posts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllContent();
    });
    
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchAllContent() async {
    final provider = context.read<PostProvider>();
    await provider.fetchPosts(isRefresh: true);
    await _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    // Fetch events from Firestore
    final eventsSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .orderBy('createdAt', descending: true)
        .get();
    
    final provider = context.read<PostProvider>();
    // You'll need to add events to your provider or handle them separately
  }

  void _onScroll() {
    final isScrolling = _scrollController.position.userScrollDirection != ScrollDirection.idle;
    if (_isScrolling != isScrolling) {
      setState(() => _isScrolling = isScrolling);
    }
    
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      context.read<PostProvider>().fetchPosts();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: primaryColor,
        onRefresh: () => _fetchAllContent(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildCategoryFilter(),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: primaryColor,
      floating: true,
      pinned: true,
      elevation: 0,
      expandedHeight: 100,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Eventra',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => context.push('/notifications'),
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => context.push('/search'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: GestureDetector(
          onTap: () => context.push('/search'),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.search, color: Colors.grey[400], size: 20),
                const SizedBox(width: 12),
                Text(
                  'Search events...',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🔍',
                    style: TextStyle(fontSize: 14, color: primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _CategoryHeaderDelegate(
        categories: _categories,
        activeFilter: _activeFilter,
        onCategorySelected: (cat) {
          setState(() => _activeFilter = cat);
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getCombinedFeed(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildSkeletonLoader(),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  const Text("Unable to load content"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _fetchAllContent(),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          );
        }

        final items = snapshot.data ?? [];
        
        if (items.isEmpty) {
          return SliverFillRemaining(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildEmptyState(),
            ),
          );
        }

        // Filter by category
        var filteredItems = items;
        if (_activeFilter != 'All') {
          filteredItems = items.where((item) {
            final category = item['category'] ?? '';
            return category == _activeFilter;
          }).toList();
        }

        if (filteredItems.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "No $_activeFilter events found",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = filteredItems[index];
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EventCard(event: item),
                  ),
                );
              },
              childCount: filteredItems.length,
            ),
          ),
        );
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _getCombinedFeed() {
    final postsStream = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();

    final eventsStream = FirebaseFirestore.instance
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Rx.combineLatest2<QuerySnapshot, QuerySnapshot, List<Map<String, dynamic>>>(
      postsStream,
      eventsStream,
      (postsSnapshot, eventsSnapshot) {
        final List<Map<String, dynamic>> items = [];
        
        // Add posts
        for (var doc in postsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          items.add({
            ...data,
            'id': doc.id,
            'type': 'post',
            'timestamp': data['createdAt'] ?? DateTime.now(),
          });
        }
        
        // Add events
        for (var doc in eventsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          items.add({
            ...data,
            'id': doc.id,
            'type': 'event',
            'timestamp': data['createdAt'] ?? DateTime.now(),
          });
        }
        
        // Sort by timestamp (newest first)
        items.sort((a, b) {
          final tA = a['timestamp'] is Timestamp 
              ? (a['timestamp'] as Timestamp).toDate() 
              : a['timestamp'] as DateTime;
          final tB = b['timestamp'] is Timestamp 
              ? (b['timestamp'] as Timestamp).toDate() 
              : b['timestamp'] as DateTime;
          return tB.compareTo(tA);
        });
        
        return items;
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 12,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_outlined,
              size: 50,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No events found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Check back later for new events",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _fetchAllContent(),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String activeFilter;
  final Function(String) onCategorySelected;

  _CategoryHeaderDelegate({
    required this.categories,
    required this.activeFilter,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = activeFilter == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) => onCategorySelected(category),
                selectedColor: primaryColor,
                backgroundColor: Colors.white,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? primaryColor : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  double get maxExtent => 60;
  @override
  double get minExtent => 60;
  
  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return oldDelegate.activeFilter != activeFilter;
  }
}

// Add this import at the top if you don't have rxdart
