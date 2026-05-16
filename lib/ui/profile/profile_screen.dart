import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    required this.userId,
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final String currentUid =
      FirebaseAuth.instance.currentUser?.uid ?? '';

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool isFollowing = false;
  bool isLoadingFollow = false;

  late final bool isMe;

  late final Stream<DocumentSnapshot>
      _userStream;

  late final Stream<QuerySnapshot>
      _postsStream;

  Stream<QuerySnapshot>? _ticketsStream;
  Stream<QuerySnapshot>? _savedStream;

  @override
  void initState() {
    super.initState();

    isMe = widget.userId == currentUid;

    _userStream = _firestore
        .collection('users')
        .doc(widget.userId)
        .snapshots();

    _postsStream = _firestore
        .collection('posts')
        .where(
          'creatorId',
          isEqualTo: widget.userId,
        )
        .snapshots();

    if (isMe) {
      _ticketsStream = _firestore
          .collectionGroup('tickets')
          .where(
            'userId',
            isEqualTo: widget.userId,
          )
          .snapshots();

      _savedStream = _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('bookmarks')
          .snapshots();
    } else {
      _checkFollowStatus();
    }
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
      debugPrint(
        "_checkFollowStatus error: $e",
      );
    }
  }

  Future<void> _toggleFollow() async {
    if (isLoadingFollow) return;

    HapticFeedback.mediumImpact();

    setState(() {
      isFollowing = !isFollowing;
      isLoadingFollow = true;
    });

    final userRef = _firestore
        .collection('users')
        .doc(widget.userId);

    final currentUserRef = _firestore
        .collection('users')
        .doc(currentUid);

    final followerRef = userRef
        .collection('followers')
        .doc(currentUid);

    final followingRef = currentUserRef
        .collection('following')
        .doc(widget.userId);

    final batch = _firestore.batch();

    try {
      if (isFollowing) {
        batch.set(followerRef, {
          'followedAt':
              FieldValue.serverTimestamp(),
        });

        batch.set(followingRef, {
          'followedAt':
              FieldValue.serverTimestamp(),
        });

        batch.update(userRef, {
          'followerCount':
              FieldValue.increment(1),
        });

        batch.update(currentUserRef, {
          'followingCount':
              FieldValue.increment(1),
        });
      } else {
        batch.delete(followerRef);

        batch.delete(followingRef);

        batch.update(userRef, {
          'followerCount':
              FieldValue.increment(-1),
        });

        batch.update(currentUserRef, {
          'followingCount':
              FieldValue.increment(-1),
        });
      }

      await batch.commit();
    } catch (e) {
      if (mounted) {
        setState(() {
          isFollowing = !isFollowing;
        });
      }

      debugPrint(
        "Error toggling follow: $e",
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingFollow = false;
        });
      }
    }
  }

  String _getChatId(
    String uid1,
    String uid2,
  ) {
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
      backgroundColor:
          AppColors.bgSecondary,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),

      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.share_outlined,
                color: AppColors.textPrimary,
              ),

              title: Text(
                "Share Profile",
                style:
                    AppTextStyles.titleMedium,
              ),

              onTap: () =>
                  Navigator.pop(context),
            ),

            ListTile(
              leading: const Icon(
                Icons
                    .report_problem_outlined,
                color: AppColors.error,
              ),

              title: Text(
                "Report User",
                style: AppTextStyles
                    .titleMedium
                    .copyWith(
                  color: AppColors.error,
                ),
              ),

              onTap: () =>
                  Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.bgPrimary,

      body:
          StreamBuilder<DocumentSnapshot>(
        stream: _userStream,

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color:
                    AppColors.accentPurple,
              ),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return Center(
              child: Text(
                "User not found",
                style:
                    AppTextStyles.bodyMedium,
              ),
            );
          }

          final userData = snapshot.data!
                  .data()
              as Map<String, dynamic>? ??
              {};

          final String? photoURL =
              userData['photoURL'];

          final String displayName =
              userData['displayName'] ??
                  'User';

          final String username =
              userData['username'] ?? '';

          final String bio =
              userData['bio'] ?? '';

          return DefaultTabController(
            length: isMe ? 3 : 1,

            child: NestedScrollView(
              headerSliverBuilder:
                  (context,
                          innerBoxIsScrolled) =>
                      [
                SliverAppBar(
                  backgroundColor:
                      AppColors.bgPrimary,

                  elevation: 0,
                  pinned: true,
                  centerTitle: true,

                  automaticallyImplyLeading:
                      !isMe,

                  leading: !isMe
                      ? IconButton(
                          icon:
                              const Icon(
                            Icons
                                .arrow_back_ios_new_rounded,
                            color: AppColors
                                .textPrimary,
                            size: 20,
                          ),
                          onPressed: () =>
                              context.pop(),
                        )
                      : null,

                  title: Text(
                    isMe
                        ? "My Profile"
                        : "@$username",
                    style: AppTextStyles
                        .headlineSmall,
                  ),

                  actions: [
                    IconButton(
                      icon: Icon(
                        isMe
                            ? Icons
                                .settings_outlined
                            : Icons
                                .more_horiz,
                        color: AppColors
                            .textPrimary,
                      ),

                      onPressed: isMe
                          ? () => context
                              .push(
                                  '/settings')
                          : _showMoreOptions,
                    ),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(
                          height: 12),

                      _buildAvatar(
                          photoURL),

                      const SizedBox(
                          height: 14),

                      Text(
                        displayName,
                        style: AppTextStyles
                            .headlineMedium,
                      ),

                      if (!isMe &&
                          username
                              .isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            top: 4,
                          ),
                          child: Text(
                            "@$username",
                            style:
                                AppTextStyles
                                    .bodyMedium,
                          ),
                        ),

                      if (bio.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            40,
                            14,
                            40,
                            0,
                          ),
                          child: Text(
                            bio,
                            textAlign:
                                TextAlign
                                    .center,
                            style:
                                AppTextStyles
                                    .bodyMedium
                                    .copyWith(
                              color: AppColors
                                  .textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),

                      const SizedBox(
                          height: 24),

                      _buildStatsRow(
                          userData),

                      const SizedBox(
                          height: 24),

                      _buildActionButtons(
                        userData,
                        displayName,
                        photoURL,
                      ),

                      const SizedBox(
                          height: 22),
                    ],
                  ),
                ),

                SliverPersistentHeader(
                  pinned: true,

                  delegate:
                      _SliverAppBarDelegate(
                    TabBar(
                      indicatorColor:
                          AppColors
                              .accentPurple,

                      indicatorWeight:
                          2.5,

                      labelColor:
                          AppColors
                              .textPrimary,

                      unselectedLabelColor:
                          AppColors
                              .textHint,

                      dividerColor:
                          AppColors
                              .borderDefault,

                      tabs: isMe
                          ? const [
                              Tab(
                                icon: Icon(
                                  Icons
                                      .grid_on_rounded,
                                ),
                              ),
                              Tab(
                                icon: Icon(
                                  Icons
                                      .confirmation_number_outlined,
                                ),
                              ),
                              Tab(
                                icon: Icon(
                                  Icons
                                      .bookmark_outline_rounded,
                                ),
                              ),
                            ]
                          : const [
                              Tab(
                                icon: Icon(
                                  Icons
                                      .grid_on_rounded,
                                ),
                              ),
                            ],
                    ),
                  ),
                ),
              ],

              body: TabBarView(
                children: isMe
                    ? [
                        _buildGrid(
                          _postsStream,
                          "No posts yet",
                          Icons
                              .camera_alt_outlined,
                          "post",
                        ),

                        _buildGrid(
                          _ticketsStream!,
                          "No tickets yet",
                          Icons
                              .confirmation_number_outlined,
                          "ticket",
                        ),

                        _buildGrid(
                          _savedStream!,
                          "No saved items",
                          Icons
                              .bookmark_outline_rounded,
                          "post",
                        ),
                      ]
                    : [
                        _buildGrid(
                          _postsStream,
                          "No posts yet",
                          Icons
                              .camera_alt_outlined,
                          "post",
                        ),
                      ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(String? photoURL) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),

          decoration: BoxDecoration(
            shape: BoxShape.circle,

            border: Border.all(
              color:
                  AppColors.borderDefault,
              width: 2,
            ),
          ),

          child: CircleAvatar(
            radius: 48,
            backgroundColor:
                AppColors.bgCard,

            backgroundImage:
                (photoURL != null &&
                        photoURL.isNotEmpty)
                    ? NetworkImage(
                        photoURL)
                    : null,

            child: (photoURL == null ||
                    photoURL.isEmpty)
                ? const Icon(
                    Icons.person,
                    size: 40,
                    color:
                        AppColors.textHint,
                  )
                : null,
          ),
        ),

        if (isMe)
          Positioned(
            bottom: 2,
            right: 2,

            child: GestureDetector(
              onTap: () =>
                  HapticFeedback
                      .lightImpact(),

              child: Container(
                padding:
                    const EdgeInsets.all(
                        8),

                decoration: BoxDecoration(
                  color: AppColors
                      .accentPurple,

                  shape: BoxShape.circle,

                  border: Border.all(
                    color: AppColors
                        .bgPrimary,
                    width: 3,
                  ),
                ),

                child: const Icon(
                  Icons
                      .add_a_photo_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsRow(
    Map<String, dynamic> data,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        _statItem(
          data['followingCount'] ?? 0,
          "Following",
        ),

        _statDivider(),

        _statItem(
          data['followerCount'] ?? 0,
          "Followers",
        ),

        _statDivider(),

        _statItem(
          data['totalLikes'] ?? 0,
          "Likes",
        ),
      ],
    );
  }

  Widget _statDivider() => Container(
        height: 24,
        width: 1,
        color: AppColors.borderDefault,
        margin:
            const EdgeInsets.symmetric(
          horizontal: 24,
        ),
      );

  Widget _statItem(
    int count,
    String label,
  ) {
    return Column(
      children: [
        Text(
          _formatCount(count),
          style:
              AppTextStyles.headlineMedium,
        ),

        const SizedBox(height: 4),

        Text(
          label,
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    Map<String, dynamic> userData,
    String displayName,
    String? photoURL,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
      ),

      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              text: isMe
                  ? "Edit Profile"
                  : (isFollowing
                      ? "Unfollow"
                      : "Follow"),

              isFilled:
                  !isMe && !isFollowing,

              onTap: isMe
                  ? () =>
                      context.push('/edit')
                  : _toggleFollow,
            ),
          ),

          const SizedBox(width: 10),

          _squareIconButton(
            isMe
                ? Icons.share_outlined
                : Icons.mail_outline_rounded,
            () {
              if (isMe) {
                _showMoreOptions();
              } else {
                final chatId =
                    _getChatId(
                  currentUid,
                  widget.userId,
                );

                context.push(
                  '/chat/room/$chatId/${widget.userId}',
                  extra: {
                    'peerName':
                        displayName,
                    'peerAvatar':
                        photoURL,
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

        style:
            ElevatedButton.styleFrom(
          elevation: 0,

          backgroundColor: isFilled
              ? AppColors.accentPurple
              : AppColors.bgCard,

          foregroundColor: Colors.white,

          side: BorderSide(
            color: isFilled
                ? Colors.transparent
                : AppColors
                    .borderDefault,
          ),

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
                    14),
          ),
        ),

        child: Text(
          text,
          style:
              AppTextStyles.labelLarge,
        ),
      ),
    );
  }

  Widget _squareIconButton(
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      height: 46,
      width: 46,

      decoration: BoxDecoration(
        color: AppColors.bgCard,

        borderRadius:
            BorderRadius.circular(14),

        border: Border.all(
          color: AppColors.borderDefault,
        ),
      ),

      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: AppColors.textPrimary,
        ),

        padding: EdgeInsets.zero,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildGrid(
    Stream<QuerySnapshot> stream,
    String emptyTitle,
    IconData emptyIcon,
    String type,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,

      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(
              color:
                  AppColors.accentPurple,
            ),
          );
        }

        final docs =
            snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,
              children: [
                Icon(
                  emptyIcon,
                  size: 52,
                  color:
                      AppColors.textHint,
                ),

                const SizedBox(
                    height: 14),

                Text(
                  emptyTitle,
                  style: AppTextStyles
                      .bodyMedium,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.zero,

          physics:
              const ClampingScrollPhysics(),

          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),

          itemCount: docs.length,

          itemBuilder:
              (context, index) {
            final data = docs[index]
                    .data()
                as Map<String, dynamic>;

            final String mediaUrl =
                data['imageUrl'] ??
                    data['mediaUrl'] ??
                    data['eventImageUrl'] ??
                    '';

            final String price =
                data['price']
                        ?.toString() ??
                    '';

            return GestureDetector(
              onTap: () {
                final docId =
                    docs[index].id;

                if (type ==
                    "ticket") {
                  context.push(
                    '/ticket/$docId',
                    extra: data,
                  );
                } else {
                  context.push(
                    '/post/$docId',
                    extra: data,
                  );
                }
              },

              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color:
                        AppColors.bgCard,
                  ),

                  if (mediaUrl
                      .isNotEmpty)
                    Image.network(
                      mediaUrl,
                      fit: BoxFit.cover,

                      loadingBuilder:
                          (
                        context,
                        child,
                        progress,
                      ) {
                        if (progress ==
                            null) {
                          return child;
                        }

                        return const Center(
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                          ),
                        );
                      },

                      errorBuilder:
                          (
                        _,
                        __,
                        ___,
                      ) =>
                              const Icon(
                        Icons
                            .broken_image_outlined,
                        color: AppColors
                            .textHint,
                      ),
                    ),

                  if (price.isNotEmpty)
                    Positioned(
                      bottom: 6,
                      left: 6,

                      child: Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),

                        decoration:
                            BoxDecoration(
                          color: Colors.black
                              .withOpacity(
                                  .65),

                          borderRadius:
                              BorderRadius
                                  .circular(
                                      8),
                        ),

                        child: Text(
                          price,
                          style: AppTextStyles
                              .labelSmall
                              .copyWith(
                            color:
                                Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SliverAppBarDelegate
    extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(
    this._tabBar,
  );

  final TabBar _tabBar;

  @override
  double get minExtent =>
      _tabBar.preferredSize.height;

  @override
  double get maxExtent =>
      _tabBar.preferredSize.height;

  @override
  Widget build(
    context,
    offset,
    overlaps,
  ) {
    return Container(
      color: AppColors.bgPrimary,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(
    _SliverAppBarDelegate old,
  ) {
    return false;
  }
}