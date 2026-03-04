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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

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
          // Added a "Discover" icon to the top right as well
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_rounded, color: primaryColor),
              onPressed: () => context.go('/discover-users'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        // --- FLOATING ACTION BUTTON TO DISCOVER ---
        floatingActionButton: FloatingActionButton(
          backgroundColor: primaryColor,
          child: const Icon(Icons.message_rounded, color: Colors.white),
          onPressed: () => context.go('/discover-users'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchBar(),
            ),

            _buildDynamicStories(currentUserId),

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

            Expanded(
              child: TabBarView(
                children: [
                  _buildChatList(chatService, currentUserId),
                  _buildEventChatsPlaceholder(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: "Search Messages...",
          prefixIcon: const Icon(Icons.search_rounded, color: primaryColor, size: 20),
          border: InputBorder.none,
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
    );
  }

  Widget _buildDynamicStories(String? currentUserId) {
    if (currentUserId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .snapshots(),
      builder: (context, snapshot) {
        // If they don't follow anyone, show a prompt to find friends
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildDiscoverPrompt();
        }

        final followedIds = snapshot.data!.docs.map((doc) => doc.id).toList();

        return Container(
          height: 110,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: followedIds.length,
            itemBuilder: (context, index) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(followedIds[index]).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox(width: 75);
                  final userData = userSnap.data?.data() as Map<String, dynamic>?;
                  final name = userData?['displayName'] ?? userData?['username'] ?? 'User';
                  final photo = userData?['photoURL'];

                  return _buildStoryItem(name, photo, followedIds[index]);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDiscoverPrompt() {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: InkWell(
        onTap: () => context.go('/discover-users'),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: const Icon(Icons.add, color: primaryColor, size: 30),
            ),
            const SizedBox(width: 12),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Find people", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                Text("Start a conversation", style: TextStyle(fontSize: 12, color: textColor)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem(String name, String? imageUrl, String uid) {
    return GestureDetector(
      onTap: () => context.go('/home/chat/$uid'),
      child: Padding(
        padding: const EdgeInsets.only(right: 15.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryColor, width: 2)),
              child: CircleAvatar(
                radius: 28,
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                child: imageUrl == null ? Text(name[0].toUpperCase()) : null,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 65,
              child: Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(ChatService chatService, String? currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: chatService.getConversationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }

        final docs = snapshot.data?.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final lastMsg = (data['lastMessage'] ?? "").toString().toLowerCase();
          return lastMsg.contains(_searchQuery);
        }).toList() ?? [];

        if (docs.isEmpty) return _buildEmptyState();

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final chatData = docs[index].data() as Map<String, dynamic>;
            final List participants = chatData['participants'] ?? [];
            final String otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');

            return FutureBuilder<Map<String, dynamic>?>(
              future: chatService.getUserProfile(otherUserId),
              builder: (context, userSnapshot) {
                final userData = userSnapshot.data;
                final name = userData?['displayName'] ?? userData?['username'] ?? 'User';
                final pfp = userData?['photoURL'];

                return ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: pfp != null ? NetworkImage(pfp) : null,
                    child: pfp == null ? Text(name[0]) : null,
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(chatData['lastMessage'] ?? 'No messages', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(chatService.formatTimestamp(chatData['lastMessageTime']), style: const TextStyle(fontSize: 11)),
                  onTap: () => context.go('/home/chat/${docs[index].id}'),
                );
              },
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
          Icon(Icons.chat_bubble_outline, size: 64, color: textColor.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text("No conversations yet"),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.go('/discover-users'),
            icon: const Icon(Icons.search),
            label: const Text("Discover Users"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEventChatsPlaceholder() {
    return Center(child: Text("Event chats will appear here", style: TextStyle(color: textColor.withOpacity(0.5))));
  }
}