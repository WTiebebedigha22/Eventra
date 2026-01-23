import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  // Logic state variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Styling Constants
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Colors.black54;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          title: const Text(
            'Messages',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
        ),
        body: Column(
          children: [
            // --- SEARCH BAR ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.trim().toLowerCase()),
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: "Search Messages...",
                    hintStyle: const TextStyle(
                      color: Colors.black38,
                      fontSize: 18,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // --- STORIES SECTION ---
            _buildStoriesSection(),

            const Divider(height: 1),

            const TabBar(
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: "Chats"),
                Tab(text: "Events"),
              ],
            ),

            // --- CHAT LIST ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: chatService.getConversationsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Local Filtering for search
                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final lastMsg = (data['lastMessage'] ?? "")
                        .toString()
                        .toLowerCase();
                    return lastMsg.contains(_searchQuery);
                  }).toList();

                  if (docs.isEmpty) return _buildEmptyState();

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final chatData = doc.data() as Map<String, dynamic>;

                      final List participants = chatData['participants'] ?? [];
                      final String otherUserId = participants.firstWhere(
                        (id) => id != currentUserId,
                        orElse: () => '',
                      );

                      return FutureBuilder<Map<String, dynamic>?>(
                        future: chatService.getUserProfile(otherUserId),
                        builder: (context, userSnapshot) {
                          final userData = userSnapshot.data;
                          final String displayName =
                              userData?['name'] ?? 'User';
                          final String? profilePic =
                              userData?['profileImageUrl'];

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: primaryColor.withOpacity(0.1),
                              backgroundImage: profilePic != null
                                  ? NetworkImage(profilePic)
                                  : null,
                              child: profilePic == null
                                  ? Text(
                                      displayName.isNotEmpty
                                          ? displayName[0].toUpperCase()
                                          : "?",
                                      style: const TextStyle(
                                        color: primaryColor,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              chatData['lastMessage'] ?? 'No messages yet',
                              style: TextStyle(
                                color: textColor.withOpacity(0.6),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              chatService.formatTimestamp(
                                chatData['lastMessageTime'],
                              ),
                              style: TextStyle(
                                color: textColor.withOpacity(0.4),
                                fontSize: 12,
                              ),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: textColor.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? "No conversations yet" : "No results found",
            style: TextStyle(color: textColor.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesSection() {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 10),
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
      padding: const EdgeInsets.only(right: 15.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Text(
              name[name.length - 1],
              style: const TextStyle(color: primaryColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
