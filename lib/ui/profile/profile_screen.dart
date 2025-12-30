import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ventra/ui/profile/edit_profile.dart';
import 'package:ventra/ui/profile/profile_settings.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color primaryPink = Color(0xFFE91E63);
  static const Color secondaryPurple = Color(0xFF9C27B0);
  static const Color backgroundColor = Colors.black;
  static const Color appBarColor = Color(0xFF181818);
  static const Color textColor = Colors.white;

  /// Helper to format numbers (e.g., 1200 -> 1.2k)
  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  /// Builds the stat columns (Events, Followers, Following)
  Widget _buildStatColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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

  /// Builds the grid content for the Tabs
  Widget _buildContentGrid(String type, Color color) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return Container(
          color: color.withOpacity(0.3),
          alignment: Alignment.center,
          child: Text(
            '$type ${index + 1}',
            style: const TextStyle(
                color: Colors.white12, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Data from AuthProvider
    final userName = auth.displayName;
    final fullName = auth.currentUserFullName;
    final bio = auth.currentBio;
    final photoUrl = auth.photoURL;
    final createdAt = auth.createdAt;
    
    // Formatted Stats
    final eventCount = _formatCount(auth.eventCount);
    final followers = _formatCount(auth.followerCount);
    final following = _formatCount(auth.followingCount);

    final email = auth.currentUserEmail ?? 'Unknown';
    final initialLetter = userName.isNotEmpty
        ? userName[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : 'G');

    final formattedJoinedDate = createdAt != null
        ? DateFormat('MMM/yyyy').format(createdAt)
        : null;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          elevation: 0,
          title: Text(
            userName,
            style: const TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: textColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileSettingsScreen()),
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryPink, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: appBarColor,
                                backgroundImage: photoUrl != null
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: photoUrl == null
                                    ? Text(
                                        initialLetter,
                                        style: const TextStyle(
                                          color: primaryPink,
                                          fontSize: 32,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const Expanded(child: SizedBox()),
                            _buildStatColumn('Events', eventCount),
                            const SizedBox(width: 25),
                            _buildStatColumn('Followers', followers),
                            const SizedBox(width: 25),
                            _buildStatColumn('Following', following),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          fullName,
                          style: const TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '@$userName',
                          style: TextStyle(
                            color: textColor.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bio,
                          style: TextStyle(color: textColor.withOpacity(0.8)),
                        ),
                        if (formattedJoinedDate != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  color: primaryPink, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Joined Ventra $formattedJoinedDate',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
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
                                            const EditProfileScreen()),
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
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: () async {
                                  await auth.logout();
                                  if (context.mounted) {
                                    context.go('/login');
                                  }
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
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    indicatorColor: primaryPink,
                    labelColor: textColor,
                    unselectedLabelColor: textColor.withOpacity(0.6),
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on_outlined)),
                      Tab(icon: Icon(Icons.bookmark_border)),
                      Tab(icon: Icon(Icons.check_circle_outline)),
                    ],
                  ),
                  appBarColor,
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildContentGrid('Events', primaryPink),
              _buildContentGrid('Saved', secondaryPurple),
              _buildContentGrid('Attended', primaryPink),
            ],
          ),
        ),
      ),
    );
  }
}

/// This class MUST be defined outside of the ProfileScreen class 
/// or defined as a static inner class.
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
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: _backgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}