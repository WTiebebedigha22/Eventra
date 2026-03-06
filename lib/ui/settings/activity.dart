import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  static const Color primaryColor = Color(0xFF3E5992);
  static const Color accentColor = Color(0xFF3BA73A); // Jiji Green
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

  // --- UI: Activity Tile ---
  Widget _buildActivityTile(BuildContext context, String docId, Map<String, dynamic> data) {
    IconData icon;
    Color iconColor;
    final String type = data['type'] ?? 'general';
    final bool isRead = data['isRead'] ?? false;

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
      case 'message':
        icon = Icons.mail_rounded;
        iconColor = accentColor;
        break;
      case 'tag':
        icon = Icons.alternate_email_rounded;
        iconColor = Colors.purple;
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
            Stack(
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
            ),
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
                          text: data['senderName'] ?? 'Someone', 
                          style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                        TextSpan(text: ' ${data['message'] ?? 'interacted with you.'}'),
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
            if (data['postImage'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(data['postImage'], width: 44, height: 44, fit: BoxFit.cover),
              )
            else if (type == 'follow')
              _buildFollowButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8)),
      child: const Text(
        'Follow', 
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
      ),
    );
  }

  // --- Logic: Handle Navigation ---
  void _handleNotificationTap(BuildContext context, String docId, Map<String, dynamic> data) {
    FirebaseFirestore.instance.collection('notifications').doc(docId).update({'isRead': true});
    
    final type = data['type'];
    if (type == 'like' || type == 'comment' || type == 'tag') {
      context.push('/post/${data['postId']}');
    } else if (type == 'follow') {
      context.push('/profile/${data['senderId']}');
    } else if (type == 'message') {
      context.push('/chat/${data['senderId']}');
    }
  }

  // --- Helper: Clear Dialog ---
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
              HapticFeedback.lightImpact();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- Helper: Logged Out State ---
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

  // --- Helper: Empty State ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No activity yet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          const Text("Interactions will appear here.", style: TextStyle(color: subtleText)),
        ],
      ),
    );
  }

  // --- Helper: Time Formatting ---
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