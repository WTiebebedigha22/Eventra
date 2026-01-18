import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  // --- Theme Colors ---
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

  Future<void> _clearAllNotifications(String uid) async {
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
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String uid = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
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
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
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

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return _buildActivityTile(data);
                  },
                );
              },
            ),
    );
  }

  void _showClearDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Activity?'),
        content: const Text('This will remove all your recent notifications permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: subtleText)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllNotifications(uid);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(Map<String, dynamic> data) {
    IconData icon;
    Color iconColor;

    switch (data['type']) {
      case 'like':
        icon = Icons.favorite_rounded;
        iconColor = Colors.redAccent;
        break;
      case 'comment':
        icon = Icons.chat_bubble_rounded;
        iconColor = primaryColor;
        break;
      case 'booking':
        icon = Icons.confirmation_number_rounded;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.notifications_rounded;
        iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: (data['isRead'] ?? true) ? Colors.transparent : primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[100],
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
        title: RichText(
          text: TextSpan(
            style: const TextStyle(color: textColor, fontSize: 14),
            children: [
              TextSpan(text: data['senderName'] ?? 'Someone', style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: ' ${data['message'] ?? 'interacted with your post.'}'),
            ],
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            data['timestamp'] != null
                ? _formatTimeAgo((data['timestamp'] as Timestamp).toDate())
                : 'Just now',
            style: const TextStyle(color: subtleText, fontSize: 12),
          ),
        ),
        trailing: data['postImage'] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(data['postImage'], width: 40, height: 40, fit: BoxFit.cover),
              )
            : null,
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
            child: Icon(Icons.notifications_none_rounded, size: 40, color: Colors.grey[300]),
          ),
          const SizedBox(height: 16),
          const Text("No notifications yet", style: TextStyle(color: subtleText, fontSize: 15)),
          const SizedBox(height: 8),
          Text("Interactions with your posts will appear here", 
               style: TextStyle(color: subtleText.withOpacity(0.5), fontSize: 13)),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}