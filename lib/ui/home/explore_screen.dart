import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

class MasonryExploreScreen extends StatefulWidget {
  const MasonryExploreScreen({super.key});

  @override
  State<MasonryExploreScreen> createState() => _MasonryExploreScreenState();
}

class _MasonryExploreScreenState extends State<MasonryExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Define the stream as a late variable to persist it
  late Stream<List<Map<String, dynamic>>> _masonryStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize the stream once so all TabBarView children share the same data source
    _masonryStream = _getMasonryFeed();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> _getMasonryFeed() {
    final posts = FirebaseFirestore.instance.collection('posts').snapshots();
    final events = FirebaseFirestore.instance.collection('events').snapshots();

    // CombineLatestStream creates a new stream. .asBroadcastStream() allows 
    // multiple StreamBuilders (tabs) to listen to it simultaneously.
    return CombineLatestStream.combine2(posts, events, (pSnap, eSnap) {
      final pList = pSnap.docs
          .map((d) => {...d.data(), 'id': d.id, 'type': 'post'})
          .toList();
      final eList = eSnap.docs
          .map((d) => {...d.data(), 'id': d.id, 'type': 'event'})
          .toList();

      final combined = [...pList, ...eList];
      
      combined.sort((a, b) {
        final tA = (a['createdAt'] ?? a['date']) as Timestamp? ?? Timestamp.now();
        final tB = (b['createdAt'] ?? b['date']) as Timestamp? ?? Timestamp.now();
        return tB.compareTo(tA);
      });
      
      return combined;
    }).asBroadcastStream(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildHeader(),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMasonryGrid('all'),
            _buildMasonryGrid('event'),
            _buildMasonryGrid('post'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      title: const Text(
        "Explore",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 26,
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.deepPurple,
        labelColor: Colors.deepPurple,
        indicatorWeight: 3,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: "All"),
          Tab(text: "Events"),
          Tab(text: "Posts"),
        ],
      ),
    );
  }

  Widget _buildMasonryGrid(String filter) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // Use the persisted stream variable here
      stream: _masonryStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepPurple),
          );
        }

        final data = snapshot.data ?? [];
        
        if (data.isEmpty) {
          return const Center(child: Text("No items found."));
        }

        final items = filter == 'all'
            ? data
            : data.where((i) => i['type'] == filter).toList();

        if (items.isEmpty) {
          return Center(child: Text("No ${filter}s found."));
        }

        return MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildMasonryTile(item);
          },
        );
      },
    );
  }

  Widget _buildMasonryTile(Map<String, dynamic> item) {
    final String imageUrl = item['imageUrl'] ?? item['mediaUrl'] ?? '';
    final bool isEvent = item['type'] == 'event';

    return GestureDetector(
      onTap: () => _navigateToDetail(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
              if (isEvent)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4),
            child: Text(
              item['title'] ?? item['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.deepPurple),
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> item) {
    final String? id = item['id'] as String?;

    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open item — missing ID.")),
      );
      return;
    }

    if (item['type'] == 'event') {
      context.push('/home/event/$id');
    } else {
      context.push('/post/$id');
    }
  }
}