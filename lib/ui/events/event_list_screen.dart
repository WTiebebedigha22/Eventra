import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

// Internal Imports
import '../../providers/post_provider.dart';
import '../components/event_card.dart';

// Theme Constants
const Color primaryColor = Color(0xFF3E5992); 
const Color backgroundColor = Colors.white; // Matches your HomeShell
const Color textColor = Colors.black54;

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch live posts immediately
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
      backgroundColor: backgroundColor,
      body: Consumer<PostProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            backgroundColor: const Color(0xFF181818),
            color: primaryColor,
            onRefresh: () => provider.fetchPosts(isRefresh: true),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Dynamic AppBar
                SliverAppBar(
                  backgroundColor: backgroundColor,
                  floating: true,
                  pinned: false,
                  elevation: 0,
                  title: const Text(
                    'EVENTRA',
                    style: TextStyle(
                      color: primaryColor, 
                      fontWeight: FontWeight.w900, 
                      fontSize: 22,
                      letterSpacing: -1,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search, color: textColor),
                      onPressed: () => context.push('/search'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: textColor),
                      onPressed: () => context.push('/settings/activity'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                // 2. Category Filters
                SliverToBoxAdapter(child: _buildCategoryFilters()),

                // 3. Conditional Content
                if (provider.isLoading && provider.posts.isEmpty)
                  SliverFillRemaining(child: _buildSkeletonLoader())
                else if (provider.posts.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < provider.posts.length) {
                            final post = provider.posts[index];
                            
                            // Transform Post model to Map for the EventCard 
                            // ensuring the 'id' is explicitly passed.
                            return EventCard(event: post.toMap()..['id'] = post.id);
                          } else {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(child: CircularProgressIndicator(color: primaryColor)),
                            );
                          }
                        },
                        childCount: provider.posts.length + (provider.hasMore ? 1 : 0),
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

  Widget _buildCategoryFilters() {
    final categories = ['All', 'Parties', 'Seminars', 'Tech', 'Art', 'Rentals'];
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(categories[index]),
            selected: index == 0,
            selectedColor: primaryColor,
            labelStyle: TextStyle(
              color: index == 0 ? Colors.white : Colors.black45,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onSelected: (_) {},
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      itemCount: 2,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[900]!,
        highlightColor: Colors.grey[800]!,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 280,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
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
          Icon(Icons.event_available_outlined, size: 64, color: Colors.black54),
          const SizedBox(height: 16),
          const Text("No live events from this right now.", 
            style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}