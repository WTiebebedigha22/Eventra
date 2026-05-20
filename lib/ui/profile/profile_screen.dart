import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    required this.userId,
    super.key,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isFollowing = false;
  bool isLoadingFollow = false;
  late final bool isMe;
  late final Stream<DocumentSnapshot> _userStream;
  late final Stream<QuerySnapshot> _postsStream;
  Stream<QuerySnapshot>? _bookingsStream;
  Stream<QuerySnapshot>? _savedStream;
  Stream<QuerySnapshot>? _reviewsStream;
  
  late TabController _tabController;
  int _currentTabIndex = 0;
  
  // Track if user is vendor
  bool _isVendor = false;
  bool _isLoadingVendorStatus = true;

  @override
  void initState() {
    super.initState();
    
    isMe = widget.userId == currentUid;
    
    _tabController = TabController(
      length: 1, // Will be updated after vendor check
      vsync: this,
    );
    
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });

    _userStream = _firestore
        .collection('users')
        .doc(widget.userId)
        .snapshots();

    // FIXED: Changed from collectionGroup to direct collection query
    _postsStream = _firestore
        .collection('posts')
        .where('userId', isEqualTo: widget.userId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    if (isMe) {
      // FIXED: Changed to direct collection queries instead of collectionGroup
      _bookingsStream = _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .snapshots();

      // Saved/bookmarked items
      _savedStream = _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('bookmarks')
          .snapshots();
          
      // Reviews written by user
      _reviewsStream = _firestore
          .collection('reviews')
          .where('customerId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      _checkFollowStatus();
    }
    
    // Check vendor status
    _checkVendorStatus();
  }
  
  Future<void> _checkVendorStatus() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      if (mounted) {
        setState(() {
          _isVendor = userDoc.data()?['isVendor'] ?? false;
          _isLoadingVendorStatus = false;
          // Update tab controller length after vendor status is known
          final tabCount = isMe ? (_isVendor ? 4 : 3) : 1;
          _tabController = TabController(
            length: tabCount,
            vsync: this,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingVendorStatus = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkFollowStatus() async {
    if (currentUid.isEmpty) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('followers')
          .doc(currentUid)
          .get();

      if (mounted) {
        setState(() {
          isFollowing = doc.exists;
        });
      }
    } catch (e) {
      debugPrint("_checkFollowStatus error: $e");
    }
  }

  Future<void> _toggleFollow() async {
    if (isLoadingFollow) return;

    HapticFeedback.mediumImpact();

    setState(() {
      isFollowing = !isFollowing;
      isLoadingFollow = true;
    });

    final userRef = _firestore.collection('users').doc(widget.userId);
    final currentUserRef = _firestore.collection('users').doc(currentUid);
    final followerRef = userRef.collection('followers').doc(currentUid);
    final followingRef = currentUserRef.collection('following').doc(widget.userId);

    final batch = _firestore.batch();

    try {
      if (isFollowing) {
        batch.set(followerRef, {
          'followedAt': FieldValue.serverTimestamp(),
        });
        batch.set(followingRef, {
          'followedAt': FieldValue.serverTimestamp(),
        });
        batch.update(userRef, {
          'followerCount': FieldValue.increment(1),
        });
        batch.update(currentUserRef, {
          'followingCount': FieldValue.increment(1),
        });
      } else {
        batch.delete(followerRef);
        batch.delete(followingRef);
        batch.update(userRef, {
          'followerCount': FieldValue.increment(-1),
        });
        batch.update(currentUserRef, {
          'followingCount': FieldValue.increment(-1),
        });
      }

      await batch.commit();
    } catch (e) {
      if (mounted) {
        setState(() {
          isFollowing = !isFollowing;
        });
      }
      debugPrint("Error toggling follow: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingFollow = false;
        });
      }
    }
  }

  String _getChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
              title: Text("Share Profile", style: AppTextStyles.titleMedium),
              onTap: () {
                Navigator.pop(context);
                _shareProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem_outlined, color: AppColors.error),
              title: Text("Report User", style: AppTextStyles.titleMedium.copyWith(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _reportUser();
              },
            ),
            if (!isMe)
              ListTile(
                leading: const Icon(Icons.block, color: AppColors.error),
                title: Text("Block User", style: AppTextStyles.titleMedium.copyWith(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _blockUser();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share profile feature coming soon')),
    );
  }

  void _reportUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted')),
    );
  }

  void _blockUser() async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUid)
          .collection('blocked')
          .doc(widget.userId)
          .set({
        'blockedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User blocked')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error blocking user: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentPurple),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Error loading profile', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text("User not found", style: AppTextStyles.bodyMedium),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final String? photoURL = userData['photoURL'];
          final String displayName = userData['displayName'] ?? 'User';
          final String username = userData['username'] ?? '';
          final String bio = userData['bio'] ?? '';
          final bool isVendor = userData['isVendor'] ?? false;

          // Update tab controller length based on vendor status
          final tabCount = isMe ? (isVendor ? 4 : 3) : 1;
          if (_tabController.length != tabCount) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _tabController.dispose();
              _tabController = TabController(length: tabCount, vsync: this);
              setState(() {});
            });
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                backgroundColor: AppColors.bgPrimary,
                elevation: 0,
                pinned: true,
                centerTitle: true,
                automaticallyImplyLeading: !isMe,
                leading: !isMe
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                        onPressed: () => context.pop(),
                      )
                    : null,
                title: Text(
                  isMe ? "My Profile" : "@$username",
                  style: AppTextStyles.headlineSmall,
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isMe ? Icons.settings_outlined : Icons.more_horiz,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: isMe ? () => context.push('/settings') : _showMoreOptions,
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildAvatar(photoURL),
                    const SizedBox(height: 14),
                    Text(displayName, style: AppTextStyles.headlineMedium),
                    if (isVendor)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Vendor",
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.accentPurple),
                        ),
                      ),
                    if (!isMe && username.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text("@$username", style: AppTextStyles.bodyMedium),
                      ),
                    if (bio.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 14, 40, 0),
                        child: Text(
                          bio,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    _buildStatsRow(userData),
                    const SizedBox(height: 24),
                    _buildActionButtons(userData, displayName, photoURL),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.accentPurple,
                    indicatorWeight: 2.5,
                    labelColor: AppColors.textPrimary,
                    unselectedLabelColor: AppColors.textHint,
                    dividerColor: AppColors.borderDefault,
                    tabs: _buildTabs(isMe, isVendor),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: _buildTabContent(isMe, isVendor),
            ),
          );
        },
      ),
    );
  }
  
  List<Tab> _buildTabs(bool isMe, bool isVendor) {
    if (!isMe) {
      return const [Tab(icon: Icon(Icons.grid_on_rounded), text: 'Posts')];
    }
    
    final tabs = <Tab>[
      const Tab(icon: Icon(Icons.grid_on_rounded), text: 'Posts'),
      const Tab(icon: Icon(Icons.book_online_outlined), text: 'Bookings'),
      const Tab(icon: Icon(Icons.bookmark_outline_rounded), text: 'Saved'),
    ];
    
    if (isVendor) {
      tabs.insert(2, const Tab(icon: Icon(Icons.reviews_outlined), text: 'Reviews'));
    }
    
    return tabs;
  }
  
  List<Widget> _buildTabContent(bool isMe, bool isVendor) {
    if (!isMe) {
      return [
        _buildPostsGrid(),
      ];
    }
    
    final content = <Widget>[
      _buildPostsGrid(),
      _buildBookingsGrid(),
      _buildSavedGrid(),
    ];
    
    if (isVendor) {
      content.insert(2, _buildReviewsGrid());
    }
    
    return content;
  }

  Widget _buildAvatar(String? photoURL) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderDefault, width: 2),
          ),
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.bgCard,
            backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
            child: (photoURL == null || photoURL.isEmpty)
                ? const Icon(Icons.person, size: 40, color: AppColors.textHint)
                : null,
          ),
        ),
        if (isMe)
          Positioned(
            bottom: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => _updateProfilePhoto(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bgPrimary, width: 3),
                ),
                child: const Icon(Icons.add_a_photo_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  void _updateProfilePhoto() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Update photo feature coming soon')),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _statItem(data['followingCount'] ?? 0, "Following"),
        _statDivider(),
        _statItem(data['followerCount'] ?? 0, "Followers"),
        _statDivider(),
        _statItem(data['totalLikes'] ?? 0, "Likes"),
      ],
    );
  }

  Widget _statDivider() => Container(
        height: 24,
        width: 1,
        color: AppColors.borderDefault,
        margin: const EdgeInsets.symmetric(horizontal: 24),
      );

  Widget _statItem(int count, String label) {
    return Column(
      children: [
        Text(_formatCount(count), style: AppTextStyles.headlineMedium),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> userData, String displayName, String? photoURL) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              text: isMe
                  ? "Edit Profile"
                  : (isFollowing ? "Unfollow" : "Follow"),
              isFilled: !isMe && !isFollowing,
              onTap: isMe ? () => context.push('/edit') : _toggleFollow,
            ),
          ),
          const SizedBox(width: 10),
          _squareIconButton(
            isMe ? Icons.share_outlined : Icons.message_outlined,
            () {
              if (isMe) {
                _showMoreOptions();
              } else {
                final chatId = _getChatId(currentUid, widget.userId);
                context.push(
                  '/chat/room/$chatId/${widget.userId}',
                  extra: {
                    'peerName': displayName,
                    'peerAvatar': photoURL,
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required bool isFilled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isFilled ? AppColors.accentPurple : AppColors.bgCard,
          foregroundColor: Colors.white,
          side: BorderSide(
            color: isFilled ? Colors.transparent : AppColors.borderDefault,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(text, style: AppTextStyles.labelLarge),
      ),
    );
  }

  Widget _squareIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: AppColors.textPrimary),
        padding: EdgeInsets.zero,
        onPressed: onTap,
      ),
    );
  }

  // FIXED: Posts Grid - Using direct collection query
  Widget _buildPostsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _postsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentPurple));
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Error loading posts', snapshot.error);
        }

        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return _buildEmptyWidget("No posts yet", Icons.camera_alt_outlined);
        }

        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: const ClampingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final mediaUrl = data['imageUrl'] ?? data['mediaUrl'] ?? '';
            
            return _buildGridItem(
              mediaUrl: mediaUrl,
              title: data['title'] ?? '',
              onTap: () => context.push('/post/${docs[index].id}', extra: data),
            );
          },
        );
      },
    );
  }

  // FIXED: Bookings Grid - Using direct collection query
  Widget _buildBookingsGrid() {
    if (_bookingsStream == null) {
      return _buildEmptyWidget("No bookings yet", Icons.book_online_outlined);
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: _bookingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentPurple));
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Error loading bookings', snapshot.error);
        }

        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return _buildEmptyWidget("No bookings yet", Icons.book_online_outlined,
              actionText: "Browse Events", onAction: () => context.push('/events'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            final Color statusColor = _getStatusColor(status);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: data['eventImageUrl'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data['eventImageUrl'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.event, size: 40),
                        ),
                      )
                    : const Icon(Icons.event, size: 40),
                title: Text(data['eventName'] ?? 'Event Booking'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${data['eventDate'] ?? 'TBD'}'),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                trailing: Text('\$${data['price'] ?? 0}'),
                onTap: () => context.push('/booking/${docs[index].id}', extra: data),
              ),
            );
          },
        );
      },
    );
  }

  // FIXED: Reviews Grid - Using direct collection query
  Widget _buildReviewsGrid() {
    if (_reviewsStream == null) {
      return _buildEmptyWidget("No reviews yet", Icons.reviews_outlined);
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: _reviewsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentPurple));
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Error loading reviews', snapshot.error);
        }

        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return _buildEmptyWidget("No reviews yet", Icons.reviews_outlined);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final rating = (data['rating'] ?? 0).toDouble();
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        )),
                        const Spacer(),
                        Text(
                          DateFormat('MMM dd, yyyy').format(
                            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now()
                          ),
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(data['comment'] ?? 'No comment', style: AppTextStyles.bodyMedium),
                    if (data['vendorName'] != null)
                      Text('For: ${data['vendorName']}', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Saved/Bookmarked items
  Widget _buildSavedGrid() {
    if (_savedStream == null) {
      return _buildEmptyWidget("No saved items", Icons.bookmark_outline_rounded);
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: _savedStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentPurple));
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Error loading saved items', snapshot.error);
        }

        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return _buildEmptyWidget("No saved items", Icons.bookmark_outline_rounded);
        }

        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: const ClampingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final mediaUrl = data['imageUrl'] ?? data['mediaUrl'] ?? '';
            
            return _buildGridItem(
              mediaUrl: mediaUrl,
              title: data['title'] ?? '',
              onTap: () {
                final postId = data['postId'] ?? docs[index].id;
                context.push('/post/$postId', extra: data);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGridItem({
    required String mediaUrl,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: AppColors.bgCard),
          if (mediaUrl.isNotEmpty)
            Image.network(
              mediaUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              },
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: AppColors.textHint,
                size: 32,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String message, IconData icon, {String? actionText, VoidCallback? onAction}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52, color: AppColors.textHint),
          const SizedBox(height: 14),
          Text(message, style: AppTextStyles.bodyMedium),
          if (actionText != null && onAction != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.explore),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPurple,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message, Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 52, color: AppColors.error),
          const SizedBox(height: 14),
          Text(message, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          Text(error?.toString() ?? 'Unknown error', style: AppTextStyles.bodySmall),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double offset, bool overlaps) {
    return Container(
      color: AppColors.bgPrimary,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate old) => false;
}