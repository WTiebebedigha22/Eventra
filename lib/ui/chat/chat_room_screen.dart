import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String otherUid;
  final String otherName;
  final String? otherAvatar;

  const ChatRoomScreen({
    super.key,
    required this.otherUid,
    required this.otherName,
    this.otherAvatar,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initChat(widget.otherUid, widget.otherName);
      context.read<ChatProvider>().markAsRead(widget.otherUid);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    // Clear typing on exit
    context.read<ChatProvider>().setTyping(widget.otherUid, false);
    super.dispose();
  }

  void _onTypingChanged(String value) {
    final provider = context.read<ChatProvider>();
    if (!_isTyping) {
      _isTyping = true;
      provider.setTyping(widget.otherUid, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      provider.setTyping(widget.otherUid, false);
    });
  }

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _isTyping = false;
    context.read<ChatProvider>().setTyping(widget.otherUid, false);
    await context.read<ChatProvider>().sendMessage(widget.otherUid, text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otherAvatar != null
                  ? NetworkImage(widget.otherAvatar!)
                  : null,
              child: widget.otherAvatar == null
                  ? Text(widget.otherName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherName,
                    style: const TextStyle(fontSize: 16)),
                StreamBuilder<bool>(
                  stream: provider.isOtherTyping(widget.otherUid),
                  builder: (_, snap) {
                    final typing = snap.data ?? false;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: typing
                          ? const Text('typing...',
                              key: ValueKey('typing'),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.greenAccent))
                          : const SizedBox.shrink(key: ValueKey('idle')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: provider.messages(widget.otherUid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No messages yet.\nSay hello! 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final msg = MessageModel.fromDoc(docs[i]);
                    final isMe = msg.senderId == myUid;
                    return _MessageBubble(
                        message: msg, isMe: isMe, isLast: i == docs.length - 1);
                  },
                );
              },
            ),
          ),
          _InputBar(
            controller: _controller,
            onChanged: _onTypingChanged,
            onSend: _send,
            sending: provider.sending,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isLast;

  const _MessageBubble(
      {required this.message, required this.isMe, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(message.timestamp);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time,
                    style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withOpacity(0.7)
                            : Colors.grey)),
                if (isMe && isLast) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.read ? Icons.done_all : Icons.done,
                    size: 12,
                    color: message.read
                        ? Colors.lightBlueAccent
                        : Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final bool sending;

  const _InputBar({
    required this.controller,
    required this.onChanged,
    required this.onSend,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, -2))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: (_) => onSend(),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            sending
                ? const SizedBox(
                    width: 44,
                    height: 44,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: onSend,
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}