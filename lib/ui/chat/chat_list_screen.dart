import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chat/chat_session.dart';
import '../../services/chat_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getConversationsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final sessions = snapshot.data!.docs.map((d) => ChatSession.fromFirestore(d)).toList();

          return ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (context, index) => const Divider(indent: 80),
            itemBuilder: (context, index) {
              final session = sessions[index];
              final otherId = session.getOtherUserId(_currentUid);
              final unread = session.unreadCounts[_currentUid] ?? 0;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _chatService.getUserProfile(otherId),
                builder: (context, userSnap) {
                  final user = userSnap.data;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: user?['photoURL'] != null ? NetworkImage(user!['photoURL']) : null,
                      child: user?['photoURL'] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(user?['displayName'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(session.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_chatService.formatTimestamp(session.lastMessageTime), style: const TextStyle(fontSize: 12)),
                        if (unread > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                            child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                      ],
                    ),
                    onTap: () {
                      _chatService.markAsRead(session.id);
                      // Navigate to Chat Detail Screen here
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}