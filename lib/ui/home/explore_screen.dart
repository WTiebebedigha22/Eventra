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

class _MasonryExploreScreenState extends State<MasonryExploreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Stream<List<Map<String, dynamic>>> _getMasonryFeed() {
    final posts = FirebaseFirestore.instance.collection('posts').snapshots();
    final events = FirebaseFirestore.instance.collection('events').snapshots();

    return CombineLatestStream.combine2(posts, events, (pSnap, eSnap) {
      final pList = pSnap.docs.map((d) => {...d.data(), 'id': d.id, 'type': 'post'}).toList();
      final eList = eSnap.docs.map((d) => {...d.data(), 'id': d.id, 'type': 'event'}).toList();

      return [...pList, ...eList]..sort((a, b) {
        final tA = (a['createdAt'] ?? a['date']) as Timestamp? ?? Timestamp.now();
        final tB = (b['createdAt'] ?? b['date']) as Timestamp? ?? Timestamp.now();
        return tB.compareTo(tA);
      });
    });
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
      title: const Text("Explore", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 26)),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF3E5992),
        labelColor: const Color(0xFF3E5992),
        unselectedLabelColor: Colors.grey,
        tabs: const [Tab(text: "All"), Tab(text: "Events"), Tab(text: "Posts")],
      ),
    );
  }

  Widget _buildMasonryGrid(String filter) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getMasonryFeed(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final items = filter == 'all' 
            ? snapshot.data! 
            : snapshot.data!.where((i) => i['type'] == filter).toList();

        return MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: const EdgeInsets.all(8),
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
    
    return GestureDetector(
      onTap: () => context.push('/post-detail/${item['id']}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(height: 100, color: Colors.grey[200]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Text(
              item['title'] ?? item['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}