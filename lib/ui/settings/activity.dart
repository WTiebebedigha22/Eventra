import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// --- MOCK DATABASE STATE MANAGER ---
// Simulates Firestore updates and broadcasts them via streams
class MockFirestore {
  static final MockFirestore instance = MockFirestore._internal();
  MockFirestore._internal();

  final _controller = StreamController<List<Map<String, dynamic>>>.broadcast();

  // Initial Seed Data representing Firestore documents
  List<Map<String, dynamic>> _data = [
    {
      'id': 'notif_1',
      'userId': 'mock_user_123',
      'type': 'like',
      'senderName': 'Sarah Jenkins',
      'senderProfile': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      'message': 'liked your recent photography post.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      'isRead': false,
      'postImage': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=150',
      'postId': 'post_99',
    },
    {
      'id': 'notif_2',
      'userId': 'mock_user_123',
      'type': 'booking_request',
      'senderName': 'David Miller',
      'senderProfile': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      'message': 'requested a studio booking for Friday.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'isRead': false,
    },
    {
      'id': 'notif_3',
      'userId': 'mock_user_123',
      'type': 'comment',
      'senderName': 'Alex Rivera',
      'senderProfile': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      'message': 'commented: "This layout looks incredibly clean!"',
      'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
      'isRead': true,
      'postImage': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=150',
      'postId': 'post_99',
    },
    {
      'id': 'notif_4',
      'userId': 'mock_user_123',
      'type': 'follow',
      'senderName': 'Emma Watson',
      'senderProfile': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
      'message': 'started following you.',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'isRead': true,
      'senderId': 'user_emma',
    },
    {
      'id': 'notif_5',
      'userId': 'mock_user_123',
      'type': 'booking_confirmed',
      'senderName': 'System',
      'senderProfile': '',
      'message': 'Your booking for Session #402 has been confirmed.',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'isRead': true,
    },
  ];

  // Expose filtered stream updates just like Firestore snapshots
  Stream<List<Map<String, dynamic>>> streamNotifications({
    required String userId,
    required List<String> types,
  }) {
    // Immediate seed
    Timer.run(() => _emitFiltered(userId, types));
    return _controller.stream.map((allDocs) => allDocs
        .where((doc) => doc['userId'] == userId && types.contains(doc['type']))
        .toList()
      ..sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime)));
  }

  void _emitFiltered(String userId, List<String> types) {
    _controller.add(List.from(_data));
  }

  // Simulates document updating
  void updateDoc(String docId, Map<String, dynamic> updates) {
    final index = _data.indexWhere((element) => element['id'] == docId);
    if (index != -1) {
      _data[index] = {..._data[index], ...updates};
      _controller.add(List.from(_data));
    }
  }

  // Simulates batch deletes
  void clearAllForUser(String userId) {
    _data.removeWhere((element) => element['userId'] == userId);
    _controller.add(List.from(_data));
  }
}

// --- MAIN WIDGET IMPLEMENTATION ---

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Colors.deepPurpleAccent;
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

  static const List<String> _interactionTypes = ['like', 'comment', 'follow', 'tag', 'message'];
  static const List<String> _bookingTypes = ['booking_request', 'booking_confirmed', 'booking_cancelled', 'booking_reminder'];

  late TabController _tabController;
  
  // Set to empty string '' to see the logged out screen state block toggle
  final String _mockUid = 'mock_user_123'; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
          if (_mockUid.isNotEmpty)
            TextButton(
              onPressed: () => _showClearDialog(context, _mockUid),
              child: const Text(
                'Clear all',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
        bottom: _mockUid.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(44),
                child: _buildTabBar(),
              ),
      ),
      body: _mockUid.isEmpty
          ? _buildLoggedOutState()
          : TabBarView(
              controller: _tabController,
              children: [
                _NotificationsTab(
                  uid: _mockUid,
                  types: _interactionTypes,
                  emptyIcon: Icons.favorite_border_rounded,
                  emptyTitle: 'No interactions yet',
                  emptySubtitle: 'Likes, comments and follows will appear here.',
                  onTap: _handleNotificationTap,
                ),
                _NotificationsTab(
                  uid: _mockUid,
                  types: _bookingTypes,
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

  void _handleNotificationTap(BuildContext context, String docId, Map<String, dynamic> data) {
    // Intercept mock framework updates instead of calling live collection routing refs
    MockFirestore.instance.updateDoc(docId, {'isRead': true});

    final type = data['type'];
    final String postId = data['postId'] ?? '';
    final String senderId = data['senderId'] ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mock Route Navigate: Triggered action target for type ($type)')),
    );

    // Context GoRouter logic preserved safely below
    switch (type) {
      case 'like':
      case 'comment':
      case 'tag':
        if (postId.isNotEmpty) context.push('/post/$postId');
        break;
      case 'follow':
        if (senderId.isNotEmpty) context.push('/profile/$senderId');
        break;
      case 'booking_request':
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'booking_reminder':
        context.push('/tickets');
        break;
      case 'message':
        if (senderId.isNotEmpty) context.push('/chat/$senderId');
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
        content: const Text('This will permanently remove all notifications from both tabs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              MockFirestore.instance.clearAllForUser(uid);
              HapticFeedback.mediumImpact();
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
        ],
      ),
    );
  }
}

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab({
    required this.uid,
    required this.types,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onTap,
  });

  final String uid;
  final List<String> types;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final void Function(BuildContext, String, Map<String, dynamic>) onTap;

  static const Color primaryColor = Colors.deepPurpleAccent;
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: MockFirestore.instance.streamNotifications(userId: uid, types: types),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          itemCount: snapshot.data!.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            indent: 80,
            color: Color(0xFFF0F2F5),
          ),
          itemBuilder: (context, index) {
            final data = snapshot.data![index];
            return _ActivityTile(
              docId: data['id'],
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
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            emptySubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: subtleText),
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

  static const Color primaryColor = Colors.deepPurpleAccent;
  static const Color accentColor = Colors.purpleAccent;
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

  @override
  Widget build(BuildContext context) {
    final String type = data['type'] ?? 'general';
    final bool isRead = data['isRead'] ?? false;
    final (IconData icon, Color iconColor) = _iconForType(type);

    return InkWell(
      onTap: () => onTap(context, docId, data),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isRead ? Colors.transparent : primaryColor.withOpacity(0.04),
        child: Row(
          children: [
            _buildAvatar(icon, iconColor),
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
                          text: data['senderName'] ?? 'System',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' ${data['message'] ?? 'sent a notification.'}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(data['timestamp']),
                    style: const TextStyle(color: subtleText, fontSize: 12),
                  ),
                ],
              ),
            ),
            _buildTrailing(type),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _iconForType(String type) {
    return switch (type) {
      'like' => (Icons.favorite_rounded, Colors.redAccent),
      'comment' => (Icons.chat_bubble_rounded, primaryColor),
      'follow' => (Icons.person_add_alt_1_rounded, Colors.blue),
      'booking_request' => (Icons.pending_actions_rounded, Colors.orange),
      'booking_confirmed' => (Icons.confirmation_number_rounded, Colors.green),
      'booking_cancelled' => (Icons.cancel_rounded, Colors.redAccent),
      'booking_reminder' => (Icons.alarm_rounded, Colors.orange),
      'message' => (Icons.mail_rounded, accentColor),
      _ => (Icons.notifications_rounded, Colors.grey),
    };
  }

  Widget _buildAvatar(IconData icon, Color iconColor) {
    final String profileUrl = data['senderProfile'] ?? '';
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.grey[200],
          backgroundImage: profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
          child: profileUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 12),
        ),
      ],
    );
  }

  Widget _buildTrailing(String type) {
    if (data['postImage'] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          data['postImage'] as String,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      );
    }
    if (type == 'follow') return _buildPill('Follow', primaryColor);
    if (type == 'booking_request') return _buildPill('View', accentColor);
    return const SizedBox.shrink();
  }

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    final DateTime dt = timestamp is DateTime ? timestamp : (timestamp as dynamic).toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}