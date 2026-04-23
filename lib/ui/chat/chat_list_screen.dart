import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getConversationsStream(),
        builder: (context, snapshot) {
          // 🔄 LOADING STATE
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final sessions = snapshot.data!.docs
              .map((d) => ChatSession.fromFirestore(d))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.only(top: 8),
            itemCount: sessions.length,
            separatorBuilder: (_, __) =>
                const Divider(indent: 80, height: 1),
            itemBuilder: (context, index) {
              final session = sessions[index];
              final otherId = session.getOtherUserId(_currentUid);
              final unread = session.unreadFor(_currentUid);

              return FutureBuilder<Map<String, dynamic>?>(
                future: _chatService.getUserProfile(otherId),
                builder: (context, userSnap) {
                  final user = userSnap.data;

                  final name = user?['displayName'] ?? 'User';
                  final avatar = user?['photoURL'];
                  final isOnline = user?['isOnline'] ?? false;

                  return Dismissible(
                    key: ValueKey(session.id),
                    background: _swipeBg(Icons.delete, Colors.red),
                    secondaryBackground:
                        _swipeBg(Icons.notifications_off, Colors.orange),
                    onDismissed: (_) {
                      // 🔥 Hook delete/mute later
                    },
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

                      // ─── AVATAR + ONLINE DOT ───
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                avatar != null ? NetworkImage(avatar) : null,
                            child: avatar == null
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),

                          if (isOnline)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                height: 12,
                                width: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),

                      // ─── NAME + MESSAGE ───
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),

                      subtitle: Row(
                        children: [
                          if (session.lastMessage.contains('📷'))
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(Icons.image, size: 16, color: Colors.grey),
                            ),

                          Expanded(
                            child: Text(
                              session.lastMessage.isEmpty
                                  ? "Start conversation..."
                                  : session.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unread > 0
                                    ? Colors.black
                                    : Colors.grey[600],
                                fontWeight:
                                    unread > 0 ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ─── TIME + UNREAD ───
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _chatService.formatTimestamp(
                                session.lastMessageTime),
                            style: TextStyle(
                              fontSize: 11,
                              color: unread > 0
                                  ? Colors.deepPurpleAccent
                                  : Colors.grey,
                            ),
                          ),

                          if (unread > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.deepPurpleAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unread > 99 ? '99+' : '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // ─── NAVIGATION ───
                      onTap: () {
                        _chatService.markAsRead(session.id);

                        context.push(
                          '/chat/room/${session.id}/$otherId',
                          extra: {
                            'peerName': name,
                            'peerAvatar': avatar,
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ─────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No conversations yet",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────
  // LOADING SHIMMER (SIMPLE)
  // ─────────────────────────────
  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  // ─────────────────────────────
  // SWIPE BACKGROUND
  // ─────────────────────────────
  Widget _swipeBg(IconData icon, Color color) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: color,
      child: Icon(icon, color: Colors.white),
    );
  }
}