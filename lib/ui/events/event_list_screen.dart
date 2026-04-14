import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ventra/models/posts/post.dart';

// Internal Imports
import '../../providers/post_provider.dart';
import '../components/event_card.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final ScrollController _scrollController = ScrollController();
  // Jiji-style: Track the active filter
  String _activeFilter = 'All'; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchPosts(isRefresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      context.read<PostProvider>().fetchPosts();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F7), // Jiji-style light grey background
      body: Consumer<PostProvider>(
        builder: (context, provider, child) {
          // Logic to filter the posts based on selected category
          final filteredPosts = _activeFilter == 'All' 
              ? provider.posts 
              : provider.posts.where((p) => p.category == _activeFilter).toList();

          return RefreshIndicator(
            color: Colors.white,
            backgroundColor: Colors.deepPurple,
            onRefresh: () => provider.fetchPosts(isRefresh: true),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Jiji Header Style
                SliverAppBar(
                  backgroundColor: Colors.deepPurple,
                  floating: true,
                  pinned: true,
                  elevation: 0,
                  centerTitle: false,
                  title: const Text(
                    'EVENTRA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 0.5,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () => context.push('/search'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                // 2. Sticky Category Filters
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CategoryHeaderDelegate(
                    onCategorySelected: (cat) {
                      setState(() => _activeFilter = cat);
                    },
                    activeFilter: _activeFilter,
                  ),
                ),

                // 3. Content
                if (provider.isLoading && provider.posts.isEmpty)
                  SliverFillRemaining(child: _buildSkeletonLoader())
                else if (filteredPosts.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < filteredPosts.length) {
                            final post = filteredPosts[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: EventCard(event: post.toMap()..['id'] = post.id),
                            );
                          } else {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(color: Colors.deepPurple),
                              ),
                            );
                          }
                        },
                        childCount: filteredPosts.length + (provider.hasMore ? 1 : 0),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      itemCount: 3,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No $_activeFilter found",
            style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

extension on Post {
  get category => null;
}

// Delegate for the Sticky Filter Bar
class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Function(String) onCategorySelected;
  final String activeFilter;

  _CategoryHeaderDelegate({required this.onCategorySelected, required this.activeFilter});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final categories = ['All', 'Parties', 'Seminars', 'Tech', 'Art', 'Rentals', 'Workshops', 'Music', 'Sports', 'Food'];
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final isSelected = activeFilter == categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: isSelected,
              onSelected: (val) => onCategorySelected(categories[index]),
              selectedColor: Colors.deepPurple,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: isSelected ? Colors.deepPurple : Colors.grey[300]!),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  double get maxExtent => 64.0;
  @override
  double get minExtent => 64.0;
  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) => 
      oldDelegate.activeFilter != activeFilter;
}