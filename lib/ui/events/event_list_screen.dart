import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Assume these colors are consistently defined
const Color primaryPink = Color(0xFFE91E63); 
const Color secondaryPurple = Color(0xFF9C27B0);
const Color backgroundColor = Colors.black;
const Color cardColor = Color(0xFF181818); 
const Color textColor = Colors.white;

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  // --- Mock Data ---
  final List<Map<String, String>> mockEvents = const [
    {
      'id': '1', 
      'title': 'Midnight Synthwave Rave', 
      'subtitle': 'The Retro Bar | 10:00 PM', 
      'category': 'Music',
      'imageUrl': 'https://picsum.photos/seed/1/600/400',
    },
    {
      'id': '2', 
      'title': 'The Code Clash Hackathon', 
      'subtitle': 'Tech Hub HQ | All Day', 
      'category': 'Tech',
      'imageUrl': 'https://picsum.photos/seed/2/600/400',
    },
    {
      'id': '3', 
      'title': 'Indie Film Premiere: "Echoes"', 
      'subtitle': 'Grand Cinema | 7:00 PM', 
      'category': 'Arts',
      'imageUrl': 'https://picsum.photos/seed/3/600/400',
    },
    {
      'id': '4', 
      'title': 'Future of Web3 Conference', 
      'subtitle': 'Metropolitan Center | 9:00 AM', 
      'category': 'Tech',
      'imageUrl': 'https://picsum.photos/seed/4/600/400',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text(
          'Eventra',
          style: TextStyle(
            color: primaryPink, 
            fontSize: 28, 
            fontWeight: FontWeight.bold
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: textColor),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: textColor),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Horizontal Category Filters (Spotify-style chips)
          SliverToBoxAdapter(
            child: _buildCategoryFilters(),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 2. Event Feed (Instagram-style cards)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final event = mockEvents[index % mockEvents.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildEventCard(context, event),
                );
              },
              childCount: 8, // Show a few repeating cards for scrolling demo
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildCategoryFilters() {
    const categories = ['All', 'Music', 'Tech', 'Arts', 'Food', 'Sport', 'Community'];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == 0; // Assume 'All' is selected by default
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.black : textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              selected: isSelected,
              selectedColor: primaryPink,
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? primaryPink : textColor.withOpacity(0.5),
                ),
              ),
              onSelected: (selected) {
                // TODO: Implement category filtering logic
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, String> event) {
    return GestureDetector(
      onTap: () {
        // Navigate to the EventDetailScreen using GoRouter
        // Path: /home/explore/event/:id
        context.go('/home/explore/event/${event['id']}');
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 8.0),
        decoration: const BoxDecoration(
          color: backgroundColor, // Background matches screen
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Hero Animation
            Hero(
              tag: 'event-${event['id']}', // Must match EventDetailScreen tag
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(event['imageUrl']!),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Text Details (Instagram-style, below the image)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title']!,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event['subtitle']!,
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      Chip(
                        label: Text(
                          event['category']!,
                          style: const TextStyle(color: textColor, fontSize: 12),
                        ),
                        backgroundColor: primaryPink.withOpacity(0.8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}