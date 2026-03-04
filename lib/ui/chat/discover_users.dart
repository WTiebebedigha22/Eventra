import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/chat_service.dart';

class UserDiscoveryScreen extends StatefulWidget {
  const UserDiscoveryScreen({super.key});

  @override
  State<UserDiscoveryScreen> createState() => _UserDiscoveryScreenState();
}

class _UserDiscoveryScreenState extends State<UserDiscoveryScreen> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  static const Color primaryBlue = Color(0xFF3E5992);

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Discover People",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search by username...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: primaryBlue),
                filled: true,
                fillColor: Colors.white10,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- USER LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryBlue));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildNoUsersFound();
                }

                // Filter logic: Remove self + check search query
                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['displayName'] ?? data['username'] ?? '').toString().toLowerCase();
                  return doc.id != myUid && name.contains(_searchQuery);
                }).toList();

                if (users.isEmpty) return _buildNoUsersFound();

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final userData = users[index].data() as Map<String, dynamic>;
                    final String userId = users[index].id;
                    final String name = userData['displayName'] ?? userData['username'] ?? 'User';
                    final String? photo = userData['photoURL'];
                    final String bio = userData['bio'] ?? 'Hey there! I am using Ventra.';

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: primaryBlue.withOpacity(0.2),
                          backgroundImage: photo != null ? NetworkImage(photo) : null,
                          child: photo == null
                              ? Text(name[0].toUpperCase(), style: const TextStyle(color: primaryBlue))
                              : null,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          bio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chat_bubble_outline_rounded, color: primaryBlue),
                        onTap: () => _handleStartChat(context, chatService, userId),
                      ),
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

  // --- START CHAT LOGIC ---
  Future<void> _handleStartChat(BuildContext context, ChatService service, String targetId) async {
    // Show a small loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: primaryBlue)),
    );

    try {
      String chatId = await service.getOrCreateConversation(targetId);
      if (context.mounted) {
        Navigator.pop(context); // Remove loading
        context.go('/home/chat/$chatId');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error starting conversation")),
        );
      }
    }
  }

  Widget _buildNoUsersFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text("No users found", style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}