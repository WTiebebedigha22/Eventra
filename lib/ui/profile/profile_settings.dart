import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../../providers/auth_provider.dart'; // Import AuthProvider

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
        {'title': 'Edit Profile', 'icon': Icons.person_outline, 'route': '/profile/edit', 'isDanger': false},
        {'title': 'Security', 'icon': Icons.security_outlined, 'route': '/settings/security', 'isDanger': false},
        {'title': 'Activity', 'icon': Icons.timeline, 'route': '/settings/activity', 'isDanger': false},
      ],
    },
    {
      'title': 'Content & Display',
      'items': [
        {'title': 'Notifications', 'icon': Icons.notifications_none, 'route': '/settings/notifications', 'isDanger': false},
        {'title': 'Theme', 'icon': Icons.brightness_6_outlined, 'route': '/settings/theme', 'isDanger': false},
        {'title': 'Language', 'icon': Icons.language_outlined, 'route': '/settings/language', 'isDanger': false},
      ],
    },
    {
      'title': 'Support & About',
      'items': [
        {'title': 'Help', 'icon': Icons.help_outline, 'route': '/settings/help', 'isDanger': false},
        {'title': 'Privacy Policy', 'icon': Icons.verified_user_outlined, 'route': '/settings/privacy', 'isDanger': false},
      ],
    },
    // --- NEW: Danger Zone Group for Log out and Delete Account ---
    {
      'title': 'Danger Zone',
      'items': [
        {'title': 'Log Out', 'icon': Icons.logout, 'action': 'logout', 'isDanger': true},
        {'title': 'Delete Account', 'icon': Icons.delete_forever_outlined, 'action': 'delete', 'isDanger': true},
      ],
    },
  ];

  // --- Updated Widget for a single setting item (handles navigation or action) ---
  Widget _buildSettingTile(
    BuildContext context, 
    String title, 
    IconData icon, 
    {
      String? route, 
      String? action,
      bool isDanger = false,
    }
  ) {
    // Get AuthProvider instance (listen: false as we only call methods)
    final auth = Provider.of<AuthProvider>(context, listen: false);

    VoidCallback? onTapHandler;

    if (route != null) {
      onTapHandler = () => context.push(route);
    } else if (action == 'logout') {
      onTapHandler = () async {
        // Show loading indicator or confirmation dialog if desired
        await auth.logout();
        // Navigate to login screen after successful logout
        context.go('/login');
      };
    } else if (action == 'delete') {
      onTapHandler = () {
        // TODO: Implement a confirmation dialog for account deletion
        // Example: showDialog(...)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete Account action triggered!')),
        );
      };
    }

    return ListTile(
      leading: Icon(icon, color: isDanger ? primaryPink : textColor.withOpacity(0.8)),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? primaryPink : textColor, 
          fontSize: 16,
          fontWeight: isDanger ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: onTapHandler != null 
          ? Icon(Icons.keyboard_arrow_right, color: textColor.withOpacity(0.5))
          : null,
      onTap: onTapHandler,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      tileColor: appBarColor, 
    );
  }
  // ----------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBarColor, 
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 1, 
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
            automaticallyImplyLeading: false, 
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
                  fillColor: backgroundColor, 
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
                      // Group Title (Pink accent header)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                        child: Text(
                          group['title'],
                          style: TextStyle(
                            color: primaryPink.withOpacity(0.8), 
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      
                      // List of Items
                      ...group['items'].map<Widget>((item) {
                        return Column(
                          children: [
                            _buildSettingTile(
                                context, 
                                item['title'], 
                                item['icon'], 
                                route: item['route'],
                                action: item['action'],
                                isDanger: item['isDanger'],
                            ),
                            // Divider between list items
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
