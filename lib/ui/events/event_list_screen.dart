import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/posts/post.dart';
import '../../providers/post_provider.dart';

// Theme Constants
const Color primaryPink = Color(0xFFE91E63); 
const Color backgroundColor = Colors.black;
const Color cardColor = Color(0xFF181818); 
const Color textColor = Colors.white;

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
    // Fetch live posts immediately upon landing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchPosts(isRefresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        context.read<PostProvider>().fetchPosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'EVENTRA',
          style: TextStyle(color: primaryPink, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: textColor),
            onPressed: () => context.push('/home/search'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: textColor),
            onPressed: () => context.push('/settings/activity'),
          ),
        ],
      ),
      body: Consumer<PostProvider>(
        builder: (context, provider, child) {
          // 1. Show Skeleton if data is loading for the first time
          if (provider.isLoading && provider.posts.isEmpty) {
            return _buildSkeletonLoader();
          }

          // 2. Handle Empty State
          if (provider.posts.isEmpty) {
            return _buildEmptyState();
          }

          // 3. Main Live Feed
          return RefreshIndicator(
            color: primaryPink,
            onRefresh: () => provider.fetchPosts(isRefresh: true),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: _buildCategoryFilters()),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < provider.posts.length) {
                        return _buildPostCard(context, provider.posts[index]);
                      } else {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator(color: primaryPink)),
                        );
                      }
                    },
                    childCount: provider.posts.length + (provider.hasMore ? 1 : 0),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- SKELETON LOADER UI ---
  Widget _buildSkeletonLoader() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[900]!,
        highlightColor: Colors.grey[800]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.white),
              title: Container(height: 10, width: 100, color: Colors.white),
            ),
            Container(height: 300, width: double.infinity, color: Colors.white),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(height: 10, width: 200, color: Colors.white),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- LIVE POST CARD ---
  Widget _buildPostCard(BuildContext context, Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: post.userProfileUrl != null 
                  ? NetworkImage(post.userProfileUrl!) 
                  : null,
              backgroundColor: Colors.white,
              child: post.userProfileUrl == null ? const Icon(Icons.person, color: primaryPink) : null,
            ),
            title: Text(post.username ?? "Eventra User", 
                style: const TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            subtitle: post.location != null 
                ? Text(post.location!, style: const TextStyle(color: primaryPink, fontSize: 12))
                : null,
            trailing: const Icon(Icons.more_vert, color: Colors.white54),
          ),
          
          GestureDetector(
            onDoubleTap: () => context.read<PostProvider>().toggleLike(post.id, "currentUserId", "Current User"),
            child: AspectRatio(
              aspectRatio: 1,
              child: post.mediaUrl != null 
                  ? Image.network(post.mediaUrl!, fit: BoxFit.cover)
                  : Container(color: cardColor),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(post.likes.contains("currentUserId") ? Icons.favorite : Icons.favorite_border, 
                     color: post.likes.contains("currentUserId") ? primaryPink : Colors.white),
                const SizedBox(width: 16),
                const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
                const SizedBox(width: 16),
                const Icon(Icons.share_rounded, color: Colors.white),
                const Spacer(),
                if (post.eventDate != null)
                  const Icon(Icons.calendar_today_outlined, color: primaryPink, size: 20),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: "${post.username ?? 'User'} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: post.content),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    const categories = ['All', 'Parties', 'Seminars', 'Tech Events', 'Art', 'Rentals', 'Services'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(categories[index]),
            selected: index == 0,
            selectedColor: primaryPink,
            onSelected: (_) {},
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
          Icon(Icons.feed_outlined, size: 64, color: textColor.withOpacity(0.2)),
          const Text("No live posts yet.", style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}