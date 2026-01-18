import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/chat_service.dart';

class UserDiscoveryScreen extends StatelessWidget {
  const UserDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Find People", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetching all users from your 'users' collection
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Filter out your own profile so you don't chat with yourself
          final users = snapshot.data!.docs.where((doc) => doc.id != myUid).toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final String userId = users[index].id;
              final String name = userData['name'] ?? 'Unknown User';
              final String? photo = userData['profileImageUrl'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: photo != null ? NetworkImage(photo) : null,
                  child: photo == null ? Text(name[0]) : null,
                ),
                title: Text(name, style: const TextStyle(color: Colors.black)),
                subtitle: const Text("Tap to message", style: TextStyle(color: Colors.white54)),
                trailing: const Icon(Icons.send_rounded, color: Color(0xFF3E5992)),
                onTap: () async {
                  // SYNC LOGIC: Get unique ID for these two users
                  String chatId = await chatService.getOrCreateConversation(userId);
                  // Navigate to the room
                  context.go('/home/chat/$chatId');
                },
              );
            },
          );
        },
      ),
 
    );
  }
}