import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart'; 
import 'package:ventra/ui/components/event_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // --- State Variables ---
  String _selectedFilter = 'All'; 

  // --- Theme Colors ---
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

  /// Combines 'posts' and 'events' collections into a single sorted list
  Stream<List<Map<String, dynamic>>> _getCombinedFeed() {
    final postsStream = FirebaseFirestore.instance.collection('posts').snapshots();
    final eventsStream = FirebaseFirestore.instance.collection('events').snapshots();

    return CombineLatestStream.combine2(
      postsStream,
      eventsStream,
      (QuerySnapshot postsSnap, QuerySnapshot eventsSnap) {
        final posts = postsSnap.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {...data, 'id': doc.id, 'itemType': 'post'};
        }).toList();

        final events = eventsSnap.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {...data, 'id': doc.id, 'itemType': 'event'};
        }).toList();

        List<Map<String, dynamic>> combined = [...posts, ...events];

        combined.sort((a, b) {
          // Flexible date parsing to prevent crashes if keys differ
          final dateA = (a['date'] ?? a['createdAt']) as Timestamp? ?? Timestamp.now();
          final dateB = (b['date'] ?? b['createdAt']) as Timestamp? ?? Timestamp.now();
          return dateB.compareTo(dateA);
        });

        return combined;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: () async => setState(() {}),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // --- Custom Header ---
            SliverAppBar(
              backgroundColor: backgroundColor,
              elevation: 0,
              floating: true,
              centerTitle: false,
              title: const Text(
                "Ventra",
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  letterSpacing: -1.2,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: textColor),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
            ),

            // --- Filter Selection Row ---
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: ['All', 'Events', 'Posts'].map((filter) {
                    final bool isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedFilter = filter);
                        },
                        selectedColor: primaryColor,
                        backgroundColor: Colors.grey[100],
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // --- Main Feed Stream ---
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getCombinedFeed(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: _buildStateMessage(Icons.error_outline, "Error loading feed", "${snapshot.error}"),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(child: _SkeletonLoader());
                }

                final allItems = snapshot.data ?? [];

                // Logic: Filter items based on selection
                final filteredItems = allItems.where((item) {
                  if (_selectedFilter == 'All') return true;
                  // matches 'event' or 'post' based on the filter string minus the 's'
                  String typeMatch = _selectedFilter.toLowerCase().replaceAll('s', '');
                  return item['itemType'] == typeMatch;
                }).toList();

                if (filteredItems.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildStateMessage(
                      Icons.search_off_rounded, 
                      "No $_selectedFilter found", 
                      "Try changing your filter or check back later."
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => EventCard(event: filteredItems[index]),
                      childCount: filteredItems.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateMessage(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: subtleText)),
          ),
        ],
      ),
    );
  }
}

// --- Visual Skeleton Loading Widget ---
class _SkeletonLoader extends StatelessWidget {
  const _SkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        height: 320,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(28),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100, height: 12, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 12),
                Container(width: 200, height: 24, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}