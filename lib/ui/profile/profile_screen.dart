import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ventra/ui/profile/edit_profile.dart';
import 'package:ventra/ui/profile/profile_settings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color primaryPink = Color(0xFFE91E63);
  static const Color secondaryPurple = Color(0xFF9C27B0);
  static const Color backgroundColor = Colors.black;
  static const Color appBarColor = Color(0xFF181818);
  static const Color textColor = Colors.white;

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

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

  /// Builds a grid of posts filtered by the user's ID
  Widget _buildUserPostsGrid(PostProvider postProvider, String currentUserId) {
    final userPosts = postProvider.posts.where((p) => p.userId == currentUserId).toList();

    if (userPosts.isEmpty) {
      return _buildEmptyState("No posts yet", Icons.grid_on_outlined);
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
      ),
      itemCount: userPosts.length,
      itemBuilder: (context, index) {
        final post = userPosts[index];
        
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: post),
            ),
          ),
          child: Container(
            color: appBarColor,
            child: post.mediaUrl != null
                ? Hero(
                    tag: 'post_${post.id}',
                    child: Image.network(
                      post.mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, color: Colors.white10),
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        post.content,
                        maxLines: 3,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildContentGrid(String type, Color color, List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return _buildEmptyState("No ${type.toLowerCase()} available yet", Icons.layers_clear_outlined);
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final imageUrl = item['imageUrl'] as String?;

        return Container(
          color: color.withOpacity(0.1),
          child: imageUrl != null
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, color: Colors.white10),
                )
              : const Icon(Icons.image, color: Colors.white10),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: textColor.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: textColor.withOpacity(0.5),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);

    final initialLetter = auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U';
    final formattedJoinedDate = auth.createdAt != null 
        ? DateFormat('MMM yyyy').format(auth.createdAt!) 
        : null;
    
    final userPostCount = postProvider.posts.where((p) => p.userId == auth.userId).length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          elevation: 0,
          title: Text(
            auth.displayName,
            style: const TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: textColor),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()),
              ),
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
                                backgroundImage: auth.photoURL != null ? NetworkImage(auth.photoURL!) : null,
                                child: auth.photoURL == null
                                    ? Text(initialLetter, style: const TextStyle(color: primaryPink, fontSize: 32))
                                    : null,
                              ),
                            ),
                            const Spacer(),
                            _buildStatColumn('Posts', _formatCount(userPostCount)),
                            const SizedBox(width: 25),
                            _buildStatColumn('Followers', _formatCount(auth.followerCount)),
                            const SizedBox(width: 25),
                            _buildStatColumn('Following', _formatCount(auth.followingCount)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(auth.fullName, style: const TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('@${auth.displayName}', style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(auth.bio, style: TextStyle(color: textColor.withOpacity(0.8))),
                        if (formattedJoinedDate != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, color: primaryPink, size: 14),
                              const SizedBox(width: 6),
                              Text('Joined $formattedJoinedDate', style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: textColor.withOpacity(0.2)),
                                  foregroundColor: textColor,
                                  backgroundColor: appBarColor,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                                ),
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
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () async {
                                  await auth.logout();
                                  if (context.mounted) context.go('/login');
                                },
                                child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
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
              _buildUserPostsGrid(postProvider, auth.userId),
              _buildContentGrid('Saved', secondaryPurple, auth.savedEvents),
              _buildContentGrid('Events', primaryPink, auth.attendedEvents),
            ],
          ),
        ),
      ),
    );
  }
}

/// Post Detail View with Hero Animation and Options
class PostDetailScreen extends StatelessWidget {
  final dynamic post;

  const PostDetailScreen({super.key, required this.post});

  void _showOptions(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Colors.white),
              title: const Text('Share Post', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete Post', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeletion(context, postProvider);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmDeletion(BuildContext context, PostProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text("Delete Post?", style: TextStyle(color: Colors.white)),
        content: const Text("This action will remove the post from your profile.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              provider.deletePost(post.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () => _showOptions(context)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'post_${post.id}',
              child: post.mediaUrl != null
                  ? Image.network(post.mediaUrl!, width: double.infinity, fit: BoxFit.contain)
                  : Container(
                      width: double.infinity,
                      height: 300,
                      color: const Color(0xFF181818),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: Text(post.content, style: const TextStyle(color: Colors.white, fontSize: 18), textAlign: TextAlign.center),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.mediaUrl != null) ...[
                    Text(post.content, style: const TextStyle(color: Colors.white, fontSize: 15)),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    DateFormat('MMMM dd, yyyy • hh:mm a').format(post.createdAt),
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this._backgroundColor);
  final TabBar _tabBar;
  final Color _backgroundColor;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: _backgroundColor, child: _tabBar);
  }
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}