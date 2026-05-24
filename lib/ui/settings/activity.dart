import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ActivityScreen extends StatefulWidget {
  final bool isVendor;
  
  const ActivityScreen({super.key, this.isVendor = false});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Color(0xFF7A7E8B);
  static const Color backgroundColor = Colors.white;
  static const Color dividerColor = Color(0xFFF0F2F5);

  late TabController _tabController;
  String? _currentUid;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _currentUid = user?.uid;
      _isLoading = false;
    });
    
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUid = user?.uid;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Activity',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          if (_currentUid != null)
            TextButton(
              onPressed: () => _showClearDialog(context, _currentUid!),
              child: const Text(
                'Clear all',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
        bottom: _currentUid == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(44),
                child: _buildTabBar(),
              ),
      ),
      body: _currentUid == null
          ? _buildLoggedOutState()
          : TabBarView(
              controller: _tabController,
              children: [
                _NotificationsTab(
                  uid: _currentUid!,
                  type: 'interaction',
                  emptyIcon: Icons.favorite_border_rounded,
                  emptyTitle: 'No interactions yet',
                  emptySubtitle: 'Likes, comments and follows will appear here.',
                  onTap: _handleNotificationTap,
                ),
                _NotificationsTab(
                  uid: _currentUid!,
                  type: 'booking',
                  emptyIcon: Icons.confirmation_number_outlined,
                  emptyTitle: 'No booking activity',
                  emptySubtitle: 'Booking requests and confirmations will appear here.',
                  onTap: _handleNotificationTap,
                ),
              ],
            ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: subtleText,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        padding: const EdgeInsets.all(2),
        tabs: const [
          Tab(text: 'Interactions'),
          Tab(text: 'Bookings'),
        ],
      ),
    );
  }

  Future<void> _handleNotificationTap(BuildContext context, String notificationId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }

    final type = data['type'];
    final String postId = data['postId'] ?? data['itemId'] ?? '';
    final String senderId = data['senderId'] ?? '';
    final String bookingId = data['bookingId'] ?? '';

    switch (type) {
      case 'like':
      case 'comment':
      case 'tag':
        if (postId.isNotEmpty) {
          context.push('/post/$postId');
        }
        break;
      case 'follow':
        if (senderId.isNotEmpty) {
          context.push('/user/$senderId');
        }
        break;
      case 'booking_request':
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'booking_reminder':
        if (bookingId.isNotEmpty) {
          context.push('/booking/$bookingId');
        } else {
          context.push('/tickets');
        }
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  void _showClearDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Activity?'),
        content: const Text('This will permanently remove all notifications. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllNotifications(uid);
              HapticFeedback.mediumImpact();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications cleared'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllNotifications(String uid) async {
    try {
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  Widget _buildLoggedOutState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 64, color: primaryColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text(
            'Log in to see activity',
            style: TextStyle(color: subtleText, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab({
    required this.uid,
    required this.type,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onTap,
  });

  final String uid;
  final String type;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final void Function(BuildContext, String, Map<String, dynamic>) onTap;

  static const Color primaryColor = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> getStream() {
      if (type == 'interaction') {
        return FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: uid)
            .where('type', whereIn: ['like', 'comment', 'follow', 'tag'])
            .orderBy('createdAt', descending: true)
            .snapshots();
      } else {
        return FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: uid)
            .where('type', whereIn: ['booking_request', 'booking_confirmed', 'booking_cancelled', 'booking_reminder'])
            .orderBy('createdAt', descending: true)
            .snapshots();
      }
    }

    return StreamBuilder<QuerySnapshot>(
      stream: getStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 80,
            color: Colors.grey.shade200,
          ),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _ActivityTile(
              docId: doc.id,
              data: data,
              onTap: onTap,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(emptyIcon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            emptyTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1E21),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            emptySubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF7A7E8B), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.docId,
    required this.data,
    required this.onTap,
  });

  final String docId;
  final Map<String, dynamic> data;
  final void Function(BuildContext, String, Map<String, dynamic>) onTap;

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Color(0xFF7A7E8B);

  @override
  Widget build(BuildContext context) {
    final String type = data['type'] ?? 'general';
    final bool isRead = data['isRead'] == true;
    final iconData = _getIconForType(type);
    final iconColor = _getIconColor(type);

    return InkWell(
      onTap: () => onTap(context, docId, data),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isRead ? Colors.transparent : primaryColor.withOpacity(0.04),
        child: Row(
          children: [
            _buildAvatar(iconData, iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: textColor, fontSize: 14, height: 1.3),
                      children: [
                        TextSpan(
                          text: data['senderName'] ?? data['username'] ?? 'Someone',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' ${data['message'] ?? _getDefaultMessage(type)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(data['createdAt']),
                    style: const TextStyle(color: subtleText, fontSize: 12),
                  ),
                ],
              ),
            ),
            _buildTrailing(type, data),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.chat_bubble_rounded;
      case 'follow':
        return Icons.person_add_alt_1_rounded;
      case 'booking_request':
        return Icons.pending_actions_rounded;
      case 'booking_confirmed':
        return Icons.confirmation_number_rounded;
      case 'booking_cancelled':
        return Icons.cancel_rounded;
      case 'booking_reminder':
        return Icons.alarm_rounded;
      case 'tag':
        return Icons.alternate_email;
      case 'review':
        return Icons.star_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'like':
        return Colors.redAccent;
      case 'comment':
        return primaryColor;
      case 'follow':
        return Colors.blue;
      case 'booking_request':
        return Colors.orange;
      case 'booking_confirmed':
        return Colors.green;
      case 'booking_cancelled':
        return Colors.redAccent;
      case 'booking_reminder':
        return Colors.orange;
      case 'tag':
        return primaryColor;
      case 'review':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getDefaultMessage(String type) {
    switch (type) {
      case 'like':
        return 'liked your post';
      case 'comment':
        return 'commented on your post';
      case 'follow':
        return 'started following you';
      case 'booking_request':
        return 'requested a booking';
      case 'booking_confirmed':
        return 'confirmed your booking';
      case 'booking_cancelled':
        return 'cancelled your booking';
      case 'booking_reminder':
        return 'reminder: upcoming event';
      case 'tag':
        return 'tagged you in a post';
      case 'review':
        return 'left a review';
      default:
        return 'sent a notification';
    }
  }

  Widget _buildAvatar(IconData icon, Color iconColor) {
    final String profileUrl = data['senderPhotoURL'] ?? data['senderProfile'] ?? '';
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.grey[200],
          backgroundImage: profileUrl.isNotEmpty 
              ? CachedNetworkImageProvider(profileUrl) 
              : null,
          child: profileUrl.isEmpty 
              ? Icon(Icons.person, color: Colors.grey[400], size: 28) 
              : null,
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            color: Colors.white, 
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 12),
        ),
      ],
    );
  }

  Widget _buildTrailing(String type, Map<String, dynamic> data) {
    final String postImage = data['postImage'] ?? data['imageUrl'] ?? '';
    if (postImage.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: postImage,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 44,
            height: 44,
            color: Colors.grey.shade200,
            child: const Icon(Icons.image, size: 20, color: Colors.grey),
          ),
          errorWidget: (context, url, error) => Container(
            width: 44,
            height: 44,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
          ),
        ),
      );
    }
    
    if (type == 'follow') {
      return _buildPill('Follow', primaryColor);
    }
    if (type == 'booking_request') {
      return _buildPill('Respond', primaryColor);
    }
    if (type == 'booking_confirmed') {
      return _buildPill('View Ticket', Colors.green);
    }
    if (type == 'review') {
      return _buildPill('View Review', Colors.amber);
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return 'Just now';
    }
    
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo';
    return '${(diff.inDays / 365).floor()}y';
  }
}