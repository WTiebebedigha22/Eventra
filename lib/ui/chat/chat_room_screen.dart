import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  const ChatRoomScreen({super.key, required this.chatId});
  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _ctrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(children: [
        Expanded(child: Center(child: Text('Messages load here for ${widget.chatId}'))),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: [
            Expanded(child: TextField(controller: _ctrl)),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () async {
                if (_ctrl.text.trim().isEmpty) return;
                await chat.send(widget.chatId, _ctrl.text.trim(), 'me');
                _ctrl.clear();
              },
            )
          ]),
        )
      ]),
    );
  }
}
