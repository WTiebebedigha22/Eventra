import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: ListView(children: [
        ListTile(title: const Text('Organizer A'), onTap: () => context.go('/home/chat/organizerA')),
      ]),
    );
  }
}
