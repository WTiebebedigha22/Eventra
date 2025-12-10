import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Note: You might need to import AuthProvider for logout, etc., if actions are taken here.

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  // Define your color scheme (consistent with other screens)
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color backgroundColor = Colors.black;
  static const Color appBarColor = Color(0xFF181818); 
  static const Color textColor = Colors.white;

  // Mock data structure for grouped settings
  final List<Map<String, dynamic>> settingGroups = const [
    {
      'title': 'Account',
      'items': [
        {'title': 'Edit Profile', 'icon': Icons.person_outline, 'route': '/home/profile/edit'},
        {'title': 'Security', 'icon': Icons.security_outlined, 'route': '/settings/security'},
        {'title': 'Activity', 'icon': Icons.timeline, 'route': '/settings/activity'},
      ],
    },
    {
      'title': 'Content & Display',
      'items': [
        {'title': 'Notifications', 'icon': Icons.notifications_none, 'route': '/settings/notifications'},
        {'title': 'Theme', 'icon': Icons.brightness_6_outlined, 'route': '/settings/theme'},
        {'title': 'Language', 'icon': Icons.language_outlined, 'route': '/settings/language'},
      ],
    },
    {
      'title': 'Support & About',
      'items': [
        {'title': 'Help', 'icon': Icons.help_outline, 'route': '/settings/help'},
        {'title': 'Privacy Policy', 'icon': Icons.verified_user_outlined, 'route': '/settings/privacy'},
      ],
    },
  ];

  // --- Widget for a single setting item ---
  Widget _buildSettingTile(BuildContext context, String title, IconData icon, String route) {
    return ListTile(
      leading: Icon(icon, color: textColor.withOpacity(0.8)),
      title: Text(
        title,
        style: const TextStyle(color: textColor, fontSize: 16),
      ),
      trailing: Icon(Icons.keyboard_arrow_right, color: textColor.withOpacity(0.5)),
      onTap: () {
        // Navigate to the specific setting screen
        // Use context.push() if you want a back button to this screen
        context.push(route);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      tileColor: appBarColor, // Dark background for the tile
    );
  }
  // ----------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBarColor, // Overall dark background
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 1, // Subtle line under the header
        title: const Text(
          'Settings and Privacy',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // --- 1. Search Bar (Sticky/Pinned) ---
          SliverAppBar(
            backgroundColor: appBarColor,
            automaticallyImplyLeading: false, // Don't show default back button here
            pinned: true,
            toolbarHeight: 70,
            flexibleSpace: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                style: const TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search settings...',
                  hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search, color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: backgroundColor, // Black fill for search bar
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),
          
          // --- 2. Grouped List Tiles ---
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, groupIndex) {
                final group = settingGroups[groupIndex];
                
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Title (Instagram/Spotify style section header)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                        child: Text(
                          group['title'],
                          style: TextStyle(
                            color: primaryPink.withOpacity(0.8), // Pink accent for headers
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      
                      // List of Items
                      ...group['items'].map<Widget>((item) {
                        return Column(
                          children: [
                            _buildSettingTile(context, item['title'], item['icon'], item['route']),
                            // Subtle divider between list items (using black as contrast)
                            Divider(color: backgroundColor, height: 1.0, thickness: 1.0),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
              childCount: settingGroups.length,
            ),
          ),

          // --- 3. Footer Spacer ---
          const SliverToBoxAdapter(
            child: SizedBox(height: 30),
          ),
        ],
      ),
    );
  }
}