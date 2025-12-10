import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ventra/ui/profile/edit_profile.dart';
import 'package:ventra/ui/profile/profile_settings.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Define your color scheme (consistent with other screens)
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color secondaryPurple = Color(0xFF9C27B0);
  static const Color backgroundColor = Colors.black;
  static const Color appBarColor = Color(
    0xFF181818,
  ); // Darker shade for App/Tab bars
  static const Color textColor = Colors.white;

  // --- Widget for a single Profile Statistic ---
  Widget _buildStatColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.7)),
        ),
      ],
    );
  }
  // ---------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Get the AuthProvider instance
    final auth = Provider.of<AuthProvider>(context);
    final email = auth.currentUserEmail ?? 'Unknown';

    return DefaultTabController(
      length: 3, // Events, Saved, Attended
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          elevation: 0,
          title: Text(
            email.split('@').first, // Use username portion of email as title
            style: const TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            // Settings/More Icon
            IconButton(
              icon: const Icon(Icons.settings, color: textColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverList(
                delegate: SliverChildListDelegate([
                  // --- 1. Profile Header ---
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar and Stats Row
                        Row(
                          children: [
                            // Large Profile Avatar (Pink Border/Accent)
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primaryPink,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: appBarColor,
                                child: Text(
                                  email[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: primaryPink,
                                    fontSize: 32,
                                  ),
                                ),
                              ),
                            ),
                            const Expanded(child: SizedBox()), // Spacer
                            // Stats Columns (Instagram Style: 3 columns)
                            _buildStatColumn('Events', '12'),
                            const SizedBox(width: 25),
                            _buildStatColumn('Followers', '1.2k'),
                            const SizedBox(width: 25),
                            _buildStatColumn('Following', '80'),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Username/Bio
                        Text(
                          email, // Full email for subtitle/username
                          style: const TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Event Enthusiast | Exploring the city\'s best meetups.',
                          style: TextStyle(color: textColor.withOpacity(0.8)),
                        ),
                        const SizedBox(height: 16),

                        // Edit Profile / Logout Button
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: textColor.withOpacity(0.5),
                                  ),
                                  foregroundColor: textColor,
                                  backgroundColor: appBarColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EditProfileScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Edit Profile'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 100,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryPink,
                                  foregroundColor:
                                      Colors.black, // Black text on pink button
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: () async {
                                  await auth.logout();
                                  context.go('/login');
                                },
                                child: const Text('Logout'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              // --- 2. Tab Bar (Sliver Persistent Header) ---
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    indicatorColor: primaryPink, // Pink indicator line
                    labelColor: textColor,
                    unselectedLabelColor: textColor.withOpacity(0.6),
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on_outlined)),
                      Tab(icon: Icon(Icons.bookmark_border)),
                      Tab(icon: Icon(Icons.check_circle_outline)),
                    ],
                  ),
                  appBarColor, // Background color of the tab bar
                ),
                pinned: true,
              ),
            ];
          },
          // --- 3. Tab Content ---
          body: TabBarView(
            children: [
              // Grid View of User's Events
              _buildContentGrid('Events', primaryPink),
              // List of Saved Events
              _buildContentGrid('Saved', secondaryPurple),
              // List of Attended Events
              _buildContentGrid('Attended', primaryPink),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Widget for TabBarView Content (Simulating a Photo Grid)
Widget _buildContentGrid(String type, Color color) {
  return GridView.builder(
    padding: EdgeInsets.zero,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 1.5,
      mainAxisSpacing: 1.5,
    ),
    itemCount: 9, // Example items
    itemBuilder: (context, index) {
      return Container(
        color: color.withOpacity(0.3),
        alignment: Alignment.center,
        child: Text(
          '$type ${index + 1}',
          style: TextStyle(color: Colors.white12, fontWeight: FontWeight.bold),
        ),
      );
    },
  );
}

// Custom Delegate to make the TabBar sticky (SliverPersistentHeader)
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this._backgroundColor);

  final TabBar _tabBar;
  final Color _backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: _backgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
