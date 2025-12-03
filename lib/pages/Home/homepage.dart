import 'package:flutter/material.dart';
// Assuming the file path is correct and ProfilePage returns visible content
import 'package:ventra/pages/Profile/profilepage.dart'; 

// 1. REFRACTORED: Changed to StatefulWidget to manage the currentIndex and Page View
class VentraHomepage extends StatefulWidget {
  const VentraHomepage({super.key});

  @override
  State<VentraHomepage> createState() => _VentraHomepageState();
}

class _VentraHomepageState extends State<VentraHomepage> {
  // State Variable to track the selected tab
  int _currentIndex = 0;

  // List of placeholder pages corresponding to the BottomNavigationBar items
  final List<Widget> _pages = const [
    _HomepageBody(),       // Index 0: Home Feed (Now contains the listings)
    _PlaceholderPage(title: 'Search/Categories'), // Index 1
    _PlaceholderPage(title: 'Post Listing'),      // Index 2
    _PlaceholderPage(title: 'Favorites'),         // Index 3
    ProfilePage(),           // Index 4 (Assuming it now has content)
  ];

  // Handler for BottomNavigationBar taps
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Only show the custom AppBar on the Home tab (Index 0)
      appBar: _currentIndex == 0 ? _buildAppBar(context) : null,
      
      // The body displays the page corresponding to the current index
      body: _pages[_currentIndex],
      
      // The bottomNavigationBar is managed by the state
      bottomNavigationBar: _buildBottomNavigationBar(context), 
    );
  }

  // --- 1. AppBar ---

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.textTheme.titleLarge?.color;

    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0.5,
      title: Row(
        children: [
          Icon(Icons.location_on_outlined, color: iconColor, size: 24),
          const SizedBox(width: 4),
          Text(
            'Lagos, Nigeria', 
            style: TextStyle(
              color: iconColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: iconColor, size: 20),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.send_outlined, color: iconColor),
          onPressed: () {
             // Navigation logic for Chat/Inbox
          },
        ),
      ],
    );
  }

  // --- 2. Bottom Navigation Bar ---

  Widget _buildBottomNavigationBar(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.textTheme.titleLarge?.color;
    final unselectedColor = theme.brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[700];

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: theme.scaffoldBackgroundColor,
      selectedItemColor: iconColor,
      unselectedItemColor: unselectedColor,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      
      currentIndex: _currentIndex, 
      
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search/Categories'),
        BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Post Listing'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favorites'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      
      onTap: _onItemTapped, 
    );
  }
}

// -----------------------------------------------------------------------------
// --- WIDGETS ---
// -----------------------------------------------------------------------------

// --- 3. Body Content Widget (Home Page) ---

class _HomepageBody extends StatelessWidget {
  const _HomepageBody();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        // Ventra Categories as Story/Quick Access
        SliverToBoxAdapter(
          child: _VentraCategoryBar(),
        ),
        const SliverToBoxAdapter(
          // Divider color is dynamic
          child: Divider(height: 1, thickness: 0.5, color: Color(0xFF555555)), 
        ),
        // Insta-style Product Feed (FIX APPLIED: Restored SliverList)
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              // Dummy data for event service listings
              final listing = {
                'title': index % 2 == 0 ? 'Professional Wedding Photography Package' : 'Premium Catering & Wait Staff for Events',
                'price': index % 3 == 0 ? '₦450,000' : '₦200,000',
                'location': index % 2 == 0 ? 'Ikeja' : 'Lekki',
                'image': 'assets/placeholder_$index.jpg', 
                'likes': 120 + index,
                'isPromoted': index == 0, 
              };
              return _VentraListingCard(listing: listing);
            },
            childCount: 10, // Show 10 dummy listings
          ),
        ),
      ],
    );
  }
}

// --- 4. Placeholder Widget for Other Tabs ---

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Ventra $title Screen',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}

// --- Widget for the Category/Quick Access Bar ---

class _VentraCategoryBar extends StatelessWidget {
  final List<Map<String, dynamic>> categories = const [
    {'name': 'New Post', 'icon': Icons.add_circle, 'color': Colors.redAccent},
    {'name': 'Photography', 'icon': Icons.camera_alt, 'color': Colors.blueGrey},
    {'name': 'Catering', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'name': 'Planners', 'icon': Icons.calendar_month, 'color': Colors.purple},
    {'name': 'Venues', 'icon': Icons.location_city, 'color': Colors.teal},
    {'name': 'Music/DJ', 'icon': Icons.music_note, 'color': Colors.deepOrange},
    {'name': 'Decorations', 'icon': Icons.auto_awesome, 'color': Colors.pink},
    {'name': 'Rentals', 'icon': Icons.chair, 'color': Colors.green},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Padding(
            padding: EdgeInsets.fromLTRB(index == 0 ? 12 : 8, 8, 8, 8),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: category['color'].withOpacity(0.1),
                    border: Border.all(
                      color: category['color'],
                      width: 2.5,
                    ),
                  ),
                  child: Icon(
                    category['icon'],
                    color: category['color'],
                    size: 30,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category['name'],
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color, 
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- Widget for a Single Product Listing Card ---

class _VentraListingCard extends StatelessWidget {
  final Map<String, dynamic> listing;

  const _VentraListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final iconColor = theme.textTheme.titleLarge?.color;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // --- Card Header ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                if (listing['isPromoted'])
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FEATURED',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                const Spacer(),
                Icon(Icons.more_vert, color: isDarkMode ? Colors.grey[600] : Colors.grey),
              ],
            ),
          ),

          // --- Listing Image ---
          AspectRatio(
            aspectRatio: 1 / 1,
            child: Container(
              color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[300],
              child: Center(
                child: Icon(
                  Icons.image, 
                  size: 80, 
                  color: isDarkMode ? Colors.grey[600] : Colors.grey,
                ),
              ),
            ),
          ),

          // --- Action Bar ---
          Row(
            children: [
              IconButton(icon: Icon(Icons.favorite_border, color: iconColor), onPressed: () {}),
              IconButton(icon: Icon(Icons.forum_outlined, color: iconColor), onPressed: () {}),
              IconButton(icon: Icon(Icons.share_outlined, color: iconColor), onPressed: () {}),
              const Spacer(),
              IconButton(icon: Icon(Icons.bookmark_border, color: iconColor), onPressed:() {}),
            ],
          ),

          // --- Listing Info ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing['price']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007bff),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  listing['title']!,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.place,
                      size: 14,
                      color: isDarkMode ? Colors.grey[600] : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${listing['location']!} • 10 min ago',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[600] : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${listing['likes']} interests',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ASSUMED ProfilePage IMPLEMENTATION (For completeness)
// -----------------------------------------------------------------------------

// NOTE: You must ensure your actual ProfilePage widget returns visible content.
/*
// File: ventra/pages/profilepage.dart
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'User Profile Page Content Loaded!',
        style: TextStyle(fontSize: 24, color: Colors.blue),
      ),
    );
  }
}
*/

