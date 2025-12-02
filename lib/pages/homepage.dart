import 'package:flutter/material.dart';

class VentraHomepage extends StatelessWidget {
  const VentraHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold background uses theme's scaffoldBackgroundColor
    return Scaffold(
      appBar: _buildAppBar(context), // Pass context to AppBar builder
      body: _buildBody(context),      // Pass context to Body builder
      bottomNavigationBar: _buildBottomNavigationBar(context), // Pass context to BottomNav builder
    );
  }

  // --- 1. AppBar (Ventra Blend - Now Dynamic) ---

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.textTheme.titleLarge?.color; // Dynamic color for icons/text

    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor, // Dynamic App Bar background
      elevation: 0.5,
      title: Row(
        children: [
          // Jiji-style Location Selector
          Icon(
            Icons.location_on_outlined,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 4),
          Text(
            'Lagos, Nigeria', // Dynamic Location
            style: TextStyle(
              color: iconColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            color: iconColor,
            size: 20,
          ),
        ],
      ),
      actions: [
        // Message Icon (Ventra Inbox)
        IconButton(
          icon: Icon(
            Icons.send_outlined,
            color: iconColor,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  // --- 2. Body (Categories and Feed) ---

  Widget _buildBody(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        // Ventra Categories as Story/Quick Access (Event Services)
        SliverToBoxAdapter(
          child: _VentraCategoryBar(),
        ),
        const SliverToBoxAdapter(
          // Divider color is dynamic, using a slightly darker grey for better visibility in both modes
          child: Divider(height: 1, thickness: 0.5, color: Color(0xFF555555)), 
        ),
        // Insta-style Product Feed
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              // Updated dummy data for event service listings
              final listing = {
                'title': index % 2 == 0 ? 'Professional Wedding Photography Package' : 'Premium Catering & Wait Staff for Events',
                'price': index % 3 == 0 ? '₦450,000' : '₦200,000',
                'location': index % 2 == 0 ? 'Ikeja' : 'Lekki',
                'image': 'assets/placeholder_$index.jpg', // Replace with actual images
                'likes': 120 + index,
                'isPromoted': index == 0, // Promote the first item
              };
              return _VentraListingCard(listing: listing);
            },
            childCount: 10, // Show 10 dummy listings
          ),
        ),
      ],
    );
  }

  // --- 3. Bottom Navigation Bar ---

  Widget _buildBottomNavigationBar(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.textTheme.titleLarge?.color;
    final unselectedColor = theme.brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[700];

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: theme.scaffoldBackgroundColor, // Dynamic background
      selectedItemColor: iconColor, // Dynamic selected item color
      unselectedItemColor: unselectedColor, // Dynamic unselected color
      showSelectedLabels: false,
      showUnselectedLabels: false,
      currentIndex: 0, // Home
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search/Categories'),
        BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Post Listing'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favorites'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      onTap: (index) {
        // Handle navigation taps
      },
    );
  }
}

// --- Widget for the Category/Quick Access Bar (Theme Sensitive) ---

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
                // Category Icon in a circle (Like an IG story profile image)
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
                // Category Name
                Text(
                  category['name'],
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color, // Dynamic text color
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

// --- Widget for a Single Product Listing Card (Ventra Feed Style - Theme Sensitive) ---

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

          // --- Listing Image (The main visual focus - Placeholder is dynamic) ---
          AspectRatio(
            aspectRatio: 1 / 1, // Square image
            child: Container(
              color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[300], // Dynamic placeholder background
              child: Center(
                child: Icon(
                  Icons.image, 
                  size: 80, 
                  color: isDarkMode ? Colors.grey[600] : Colors.grey, // Dynamic placeholder icon
                ),
              ),
            ),
          ),

          // --- Action Bar (Icons are dynamic) ---
          Row(
            children: [
              // Like/Heart
              IconButton(icon: Icon(Icons.favorite_border, color: iconColor), onPressed: () {}),
              // Message/Chat (The primary action)
              IconButton(icon: Icon(Icons.forum_outlined, color: iconColor), onPressed: () {}),
              // Share
              IconButton(icon: Icon(Icons.share_outlined, color: iconColor), onPressed: () {}),
              const Spacer(),
              // Save/Bookmark
              IconButton(icon: Icon(Icons.bookmark_border, color: iconColor), onPressed: () {}),
            ],
          ),

          // --- Listing Info (Text is dynamic) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price (Blue remains consistent for high visibility)
                Text(
                  listing['price']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007bff), // Constant clean blue
                  ),
                ),
                const SizedBox(height: 4),
                // Title (Listing Description)
                Text(
                  listing['title']!,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.bodyMedium?.color, // Dynamic body text color
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Location and Time Posted
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
                // Engagement Count
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

// --- Reminder: You must wrap this in a MaterialApp with darkTheme set ---
/*
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ventra App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
        // ... define other light theme properties
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
        ),
        // ... define other dark theme properties
      ),
      themeMode: ThemeMode.system, // KEY: Auto detect system mode
      home: const VentraHomepage(),
    );
  }
}
*/