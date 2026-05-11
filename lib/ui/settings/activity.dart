import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  static const Color primaryColor = Color(0xFF3E5992);
  static const Color accentColor = Color(0xFF3BA73A);
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Activity',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          if (uid.isNotEmpty)
            TextButton(
              onPressed: () => _showClearDialog(context, uid),
              child: const Text(
                'Clear all',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: uid.isEmpty
          ? _buildLoggedOutState()
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // If you see an error here, you likely need to create a Firestore Index
                  // Check your debug console for the clickable link.
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 80, color: Color(0xFFF0F2F5)),
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    return _buildActivityTile(context, doc.id, data);
                  },
                );
              },
            ),
    );
  }

  Widget _buildActivityTile(BuildContext context, String docId, Map<String, dynamic> data) {
    IconData icon;
    Color iconColor;
    final String type = data['type'] ?? 'general';
    final bool isRead = data['isRead'] ?? false;

    // Logic to handle both social and event interactions
    switch (type) {
      case 'like':
        icon = Icons.favorite_rounded;
        iconColor = Colors.redAccent;
        break;
      case 'comment':
        icon = Icons.chat_bubble_rounded;
        iconColor = primaryColor;
        break;
      case 'follow':
        icon = Icons.person_add_alt_1_rounded;
        iconColor = Colors.blue;
        break;
      case 'booking_request':
        icon = Icons.pending_actions_rounded;
        iconColor = Colors.orange;
        break;
      case 'booking_confirmed':
        icon = Icons.confirmation_number_rounded;
        iconColor = accentColor;
        break;
      case 'message':
        icon = Icons.mail_rounded;
        iconColor = accentColor;
        break;
      default:
        icon = Icons.notifications_rounded;
        iconColor = Colors.grey;
    }

    return InkWell(
      onTap: () => _handleNotificationTap(context, docId, data),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isRead ? Colors.transparent : primaryColor.withOpacity(0.04),
        child: Row(
          children: [
            _buildAvatar(data, icon, iconColor),
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
                          style: const TextStyle(fontWeight: FontWeight.bold)
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
            _buildTrailing(type, data),
          ],
        ),
      ),
    );
  }

  // Helper to build the Avatar with the small indicator icon
  Widget _buildAvatar(Map<String, dynamic> data, IconData icon, Color iconColor) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.grey[200],
          backgroundImage: (data['senderProfile'] != null && data['senderProfile'] != '')
              ? NetworkImage(data['senderProfile'])
              : null,
          child: (data['senderProfile'] == null || data['senderProfile'] == '')
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 12),
        ),
      ],
    );
  }

  // Helper for the right-side of the tile
  Widget _buildTrailing(String type, Map<String, dynamic> data) {
    if (data['postImage'] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(data['postImage'], width: 44, height: 44, fit: BoxFit.cover),
      );
    } else if (type == 'follow') {
      return _buildActionButton('Follow', primaryColor);
    } else if (type == 'booking_request') {
      return _buildActionButton('View', accentColor);
    }
    return const SizedBox.shrink();
  }

  Widget _buildActionButton(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label, 
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, String docId, Map<String, dynamic> data) {
    // Mark as read immediately
    FirebaseFirestore.instance.collection('notifications').doc(docId).update({'isRead': true});
    
    final type = data['type'];
    final String postId = data['postId'] ?? '';
    final String senderId = data['senderId'] ?? '';

    // Advanced Routing
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
        // Assuming you have a route for tickets or booking details
        context.push('/tickets'); 
        break;
      case 'message':
        if (senderId.isNotEmpty) context.push('/chat/$senderId');
        break;
      default:
        debugPrint("Unknown notification type: $type");
    }
  }

  // --- Utility Methods (Clear Dialog, Empty States, Time Formatting) ---
  // [Same as your original code with slight improvements...]
  
  void _showClearDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Activity?'),
        content: const Text('This will permanently remove all notifications.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final collection = FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: uid);
              final snapshots = await collection.get();
              final batch = FirebaseFirestore.instance.batch();
              for (var doc in snapshots.docs) {
                batch.delete(doc.reference);
              }
              await batch.commit();
              HapticFeedback.mediumImpact();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
          const Text("Log in to see activity", style: TextStyle(color: subtleText, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No activity yet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          const Text("Interactions and bookings will appear here.", style: TextStyle(color: subtleText)),
        ],
      ),
    );
  }

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    DateTime dt = (timestamp as Timestamp).toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}