import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Colors.white;
  static const Color navBarColor = Colors.transparent;
  static const Color textColor = Colors.black54;

  @override
  Widget build(BuildContext context) {
    // Standard: Use the provider to access the service
    final chatService = Provider.of<ChatService>(context, listen: false);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text('Chats', 
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: Column(
        children: [
          _buildStoriesSection(),
          const Divider(color: navBarColor, height: 1),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Update: Match the method name in your ChatService
              stream: chatService.getConversationsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryColor));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final chatData = doc.data() as Map<String, dynamic>;
                    
                    final List participants = chatData['participants'] ?? [];
                    final String otherUserId = participants.firstWhere(
                      (id) => id != currentUserId, 
                      orElse: () => ''
                    );

                    // --- LIVE DATA: Fetch Profile for each list item ---
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: chatService.getUserProfile(otherUserId),
                      builder: (context, userSnapshot) {
                        final userData = userSnapshot.data;
                        final String displayName = userData?['name'] ?? 'User';
                        final String? profilePic = userData?['profileImageUrl'];

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: primaryColor.withOpacity(0.1),
                            backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
                            child: profilePic == null 
                                ? Text(displayName[0].toUpperCase(), style: const TextStyle(color: primaryColor)) 
                                : null,
                          ),
                          title: Text(
                            displayName,
                            style: const TextStyle(color: textColor, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            chatData['lastMessage'] ?? 'No messages yet',
                            style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            chatService.formatTimestamp(chatData['lastMessageTime']),
                            style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 12),
                          ),
                          onTap: () => context.go('/home/chat/${doc.id}'),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_rounded, size: 64, color: textColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text("No conversations yet", style: TextStyle(color: textColor.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildStoriesSection() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: 7,
        itemBuilder: (context, index) => _buildStoryItem("User $index"),
      ),
    );
  }

  Widget _buildStoryItem(String name) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        children: [
          CircleAvatar(radius: 30, backgroundColor: navBarColor, child: Text(name[0], style: const TextStyle(color: textColor))),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(color: textColor, fontSize: 12)),
        ],
      ),
    );
  }
}