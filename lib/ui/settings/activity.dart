import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
//import '../../providers/auth_provider.dart' hide AuthProvider;

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  static const Color primaryPink = Color(0xFFE91E63);
  static const Color backgroundColor = Colors.black;
  static const Color appBarColor = Color(0xFF121212);
  static const Color textColor = Colors.white;

  /// Function to delete all notifications for the current user
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
  }

  @override
  Widget build(BuildContext context) {
    // Listen to AuthProvider for state changes
    Provider.of<AuthProvider>(context);
    // Direct access to Firebase User to avoid "undefined getter" errors on custom providers
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String uid = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Notifications',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          if (uid.isNotEmpty)
            TextButton(
              onPressed: () => _showClearDialog(context, uid),
              child: const Text(
                'Clear All',
                style: TextStyle(color: primaryPink, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: uid.isEmpty
          ? _buildLoggedOutState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Recent',
                    style: TextStyle(color: primaryPink, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .where('userId', isEqualTo: uid)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: primaryPink));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.separated(
                        itemCount: snapshot.data!.docs.length,
                        separatorBuilder: (context, index) => const Divider(
                          color: Colors.white10,
                          height: 1,
                          indent: 72,
                        ),
                        itemBuilder: (context, index) {
                          var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          return _buildActivityTile(data);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _showClearDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appBarColor,
        title: const Text('Clear Notifications', style: TextStyle(color: textColor)),
        content: const Text('Are you sure you want to delete all notifications?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllNotifications(uid);
            },
            child: const Text('Clear All', style: TextStyle(color: primaryPink)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(Map<String, dynamic> data) {
    IconData icon;
    switch (data['type']) {
      case 'like': icon = Icons.favorite_rounded; break;
      case 'comment': icon = Icons.chat_bubble_rounded; break;
      case 'booking': icon = Icons.confirmation_number_rounded; break;
      default: icon = Icons.notifications_rounded;
    }

    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: primaryPink.withOpacity(0.1),
        child: Icon(icon, color: primaryPink, size: 20),
      ),
      title: Text(
        data['title'] ?? '',
        style: const TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        data['timestamp'] != null
            ? _formatTimeAgo((data['timestamp'] as Timestamp).toDate())
            : 'Just now',
        style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12),
      ),
    );
  }

  Widget _buildLoggedOutState() {
    return const Center(
        child: Text("Log in to see your activity", style: TextStyle(color: Colors.white54)));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: textColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text("No notifications yet", style: TextStyle(color: textColor.withOpacity(0.4))),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}